package PEF::Front::RenderTT;

use strict;
use warnings;
use Data::Dumper;
use Scalar::Util qw(blessed);
use Encode;
use URI::Escape;
use Template::Alloy;
use PEF::Front::Config;
use PEF::Front::Cache;
use PEF::Front::Validator;
use PEF::Front::NLS;
use PEF::Front::Response;
use Sub::Name;

sub handler {
	my ($request, $context) = @_;
	my $form          = $request->params;
	my $cookies       = $request->cookies;
	my $logger        = $request->logger;
	my $http_response = PEF::Front::Response->new(request => $request);
	my $lang          = $context->{lang};
	$http_response->set_cookie(lang => {value => $lang, path => "/"});
	my $template = delete $context->{method};
	$template =~ tr/ /_/;
	my $template_file = "$template.html";
	my $found         = 0;

	for my $tdir ((cfg_template_dir($request, $lang))) {
		my $full_template_file = $tdir . "/" . $template_file;
		if (-f $full_template_file) {
			$found = 1;
			cfg_log_level_info
				&& $logger->({level => "info", message => "found template '$full_template_file'"});
			last;
		}
	}
	if (!$found) {
		cfg_log_level_info
			&& $logger->({level => "info", message => "template '$template' not found"});
		$http_response->status(404);
		return $http_response->response();
	}
	$context->{template}  = $template;
	$context->{time}      = time;
	$context->{gmtime}    = [gmtime];
	$context->{localtime} = [localtime];
	if (\&PEF::Front::Config::cfg_context_post_hook != \&PEF::Front::Config::std_context_post_hook) {
		cfg_context_post_hook($context);
	}
	my $model = subname model => sub {
		my %req;
		my $method;
		for (@_) {
			if (ref) {
				%req = (%$_, %req);
			} else {
				$method = $_;
			}
		}
		$req{method} = $method if defined $method;
		my $vreq = eval {validate(\%req, $context)};
		my $response;
		if (!$@) {
			my $as = get_method_attrs($vreq => 'allowed_source');
			if ($as
				&& (   (!ref($as) && $as ne 'template')
					|| (ref($as) eq 'ARRAY' && !grep {$_ eq 'template'} @$as))
				)
			{
				cfg_log_level_error
					&& $logger->({level => "error", message => "not allowed source"});
				return {
					result      => 'INTERR',
					answer      => 'Unallowed calling source',
					answer_args => []
				};
			}
			my $cache_attr = get_method_attrs($vreq => 'cache');
			my $cache_key;
			if ($cache_attr) {
				$cache_key = make_request_cache_key($vreq, $cache_attr);
				$cache_attr->{expires} = cfg_cache_method_expire unless exists $cache_attr->{expires};
				cfg_log_level_debug && $logger->({level => "debug", message => "cache key: $cache_key"});
				$response = get_cache("ajax:$cache_key");
			}
			if (not $response) {
				my $model = get_model($vreq);
				my $model_sub = get_method_attrs($vreq => 'model_sub');
				if (ref $model) {
					local $Data::Dumper::Terse = 1;
					$model = Dumper($model);
					substr($model, -1, 1, '') if substr($model, -1, 1) eq "\n";
				}
				cfg_log_level_debug
					&& $logger->({level => "debug", message => "model: $model"});
				$response = $model_sub->($vreq, $context);
				if ($@) {
					cfg_log_level_error
						&& $logger->({level => "error", message => "model: $model; error: " . Dumper($@, $vreq)});
					$response = {result => 'INTERR', answer => 'Internal error', answer_args => []};
					return {result => 'INTERR', answer => 'Internal error', answer_args => []};
				}
				if ($response->{result} eq 'OK' && $cache_attr) {
					set_cache("ajax:$cache_key", $response, $cache_attr->{expires});
				}
			}
		}
		return $response;
	};
	my $tt = Template::Alloy->new(
		INCLUDE_PATH => [cfg_template_dir($request, $lang)],
		COMPILE_DIR  => cfg_template_cache,
		V2EQUALS     => 0,
		ENCODING     => 'UTF-8',
	);
	$tt->define_vmethod('text', model => $model);
	$tt->define_vmethod('hash', model => $model);
	$tt->define_vmethod(
		'text',
		config => subname(
			config => sub {
				my ($key) = @_;
				PEF::Front::Config::cfg($key);
			}
		)
	);
	$tt->define_vmethod(
		'text',
		m => subname(
			m => sub {
				my ($msgid, @params) = @_;
				msg_get($lang, $msgid, @params)->{message};
			}
		)
	);
	$tt->define_vmethod(
		'text',
		mn => subname(
			mn => sub {
				my ($msgid, $num, @params) = @_;
				msg_get_n($lang, $msgid, $num, @params)->{message};
			}
		)
	);
	$tt->define_vmethod(
		'text',
		ml => subname(
			ml => sub {
				my ($msgid, $tlang, @params) = @_;
				msg_get($tlang, $msgid, @params)->{message};
			}
		)
	);
	$tt->define_vmethod(
		'text',
		mnl => subname(
			mnl => sub {
				my ($msgid, $num, $tlang, @params) = @_;
				msg_get_n($tlang, $msgid, $num, @params)->{message};
			}
		)
	);
	$tt->define_vmethod(
		'text',
		uri_unescape => subname(
			uri_unescape => sub {
				uri_unescape(@_);
			}
		)
	);
	$tt->define_vmethod(
		'text',
		strftime => subname(
			strftime => sub {
				return if ref $_[1] ne 'ARRAY';
				strftime($_[0], @{$_[1]});
			}
		)
	);
	$tt->define_vmethod(
		'text',
		gmtime => subname(
			gmtime => sub {
				return [gmtime($_[0])];
			}
		)
	);
	$tt->define_vmethod(
		'text',
		localtime => subname(
			localtime => sub {
				return [localtime($_[0])];
			}
		)
	);
	$tt->define_vmethod(
		'text',
		response_content_type => (
			subname response_content_type => sub {
				$http_response->content_type($_[0]);
				return;
			}
		)
	);
	$tt->define_vmethod(
		'text',
		request_get_header => subname(
			request_get_header => sub {
				return $request->headers->get_header($_[0]);
			}
		)
	);
	$tt->define_vmethod(
		'text',
		response_set_header => subname(
			response_set_header => sub {
				my @p = ref($_[0]) eq 'HASH' ? %{$_[0]} : @_;
				$http_response->set_header(@p);
				return;
			}
		)
	);
	$tt->define_vmethod(
		'text',
		response_set_cookie => subname(
			response_set_cookie => sub {
				my @p = ref($_[0]) eq 'HASH' ? %{$_[0]} : @_;
				$http_response->set_cookie(@p);
				return;
			}
		)
	);
	$tt->define_vmethod(
		'text',
		response_set_status => subname(
			response_set_status => sub {
				$http_response->status($_[0]);
				return;
			}
		)
	);
	$tt->define_vmethod(
		'text',
		session => subname(
			session => sub {
				$context->{session} ||= PEF::Front::Session->new($request);
				if (@_) {
					return $context->{session}->data->{$_[0]};
				} else {
					return $context->{session}->data;
				}
			}
		)
	);
	$http_response->content_type('text/html; charset=utf-8');
	$http_response->set_body('');
	return sub {
		my $responder = $_[0];
		$tt->process($template_file, $context, \$http_response->get_body->[0])
			or cfg_log_level_error && $logger->({level => "error", message => "error: " . $tt->error()});
		$responder->($http_response->response());
	};
}

1;

__END__

=head1 NAME

B<PEF::Front::RenderTT> - Template processing

=head1 DESCRIPTION

Template engine is implemented by L<Template::Alloy> module using 
Template::Toolkit style. You can use all functions that provided by
L<Template::Alloy> module plus a few more.
 
=head1 SETTINGS

L<Template::Alloy> module setup using "V2EQUALS => 0", this means 
that for string comparison you have to use "eq" operator and "==" for
numerical.

=head1 PATH

Templates are located in B<cfg_template_dir($request, $lang)> 
(See L<PEF::Front::Config>), they are called like $template.html 
and are accessible by path /app$Template.  Its file name is a 
lower-case converted from CamelCase form with suffix C<.html>. 
Like: C</appIndex> -> C<index.html>, 
C</appUserSettings> -> C<user_settings.html>.

This C</app$Template>  path is created automatically when you 
put your template in template directory.

=head1 CONTEXT

During template processing following context variables are pre-defined:

=over

=item B<ip>

IP address of the client.

=item B<lang>

Short (ISO 639-1) language code. 
There's automatic language detection based on URL, HTTP headers and cookies
and Geo IP. You can turn it off. It's written to 'lang' cookie.

=item B<hostname>

Hostname of current request.

=item B<path>

Current URI path.

=item B<path_info>

Initial URI path.

=item B<template>

Template name.

=item B<scheme>

URL scheme. One of: 'http', 'https'.

=item B<src>

Is equal to 'app'.

=item B<form>, B<headers>, B<cookies>

These are corresponding hashes. B<form> contains parameters from
query string, form data and extra parameters from URI path.

=item B<session> and B<request> 

They are objects and can be used from handlers or from template.

C<session> is loaded only if it was used for parameter value. 

=item B<time>, B<gmtime>, B<localtime>

These are additional fields for template processing. 
C<time> is current UNIX-time, C<gmtime> - 9-element list with the time in GMT,
C<localtime> - 9-element list with the time for the local time zone. 
See C<perldoc -f> for these functions. 

=back 

=head1 ADDED FUNCTIONS

There're some additional functions defined. 

=head2 model()

It can be used as virtual method for string or hash:

  [% news = "get all news".model(limit => 3) %]

or

  [% news = {method => "get all news", limit => 3}.model %]

This method calls internal model handler to get some data. 
Source B<template> must be allowed.

=head2 config($key)

Returns config's parameter value.

  [% config('www_static_captchas_path') %]

=head2 uri_unescape($uri)

Returns a string with each %XX sequence replaced with the actual byte (octet).

=head2 strftime($fmt, 9-elements array)

Convert date and time information to string. Returns the string.

See C<strftime> in L<POSIX>.

=head2 gmtime($time), localtime($time)

Return 9-elements array. See corresponding perl functions.

=head2 response_content_type($ct)

Sets response Content-Type header.

=head2 request_get_header($h)

Returns request header

=head2 response_set_header($h => $v)

Sets response header.

=head2 response_set_cookie($c => $v)

Sets response cookie.

=head2 response_set_status($code)

Sets response status code.

=head2 session($key)

Returns session data.

=head2 Localization

=head3 m($msgid, @args)

Returns localized text for message $msgid. It supports parameterized
messages like:

  [% m('Hello $1', user.name) %]

C<$1> means first argument, C<$2> means second, etc.

=head3 mn($msgid, $num, @args)

This works like C<m($msgid, @args)> but supports singular/plural forms. 
C<$num> is used to select right form.

  [% mn('You just deleted $1 unimportant files', number, number) %]

In this example first C<number> selects singular/plural form and second
C<number> is argument.

=head3 ml($msgid, $lang, @args)

This is like C<m($msgid, @args)> but language is selectable.

=head3 mnl($msgid, $num, $lang, @args)

This is like C<mn($msgid, $num, @args)> but language is selectable.

Even if you use only one language it has some sense to use localization:
it can help you to translate from "programmers" language to "usual user"
language.

=head1 AUTHOR
 
This module was written and is maintained by Anton Petrusevich.

=head1 Copyright and License
 
Copyright (c) 2016 Anton Petrusevich. Some Rights Reserved.
 
This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
