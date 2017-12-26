package PEF::Front::Route;
use Scalar::Util qw(blessed);
use PEF::Front::Config;
use PEF::Front::Request;
use PEF::Front::Response;
use PEF::Front::Ajax;
use PEF::Front::RenderTT;
use PEF::Front::NLS;
use if cfg_handle_static(), 'File::LibMagic';
use Encode;
use URI::Escape;
use File::Basename;
use base 'Exporter';
use strict;
use warnings;

our @EXPORT = qw(get post patch put del trace websocket sse);

sub get ($) {
	my $rule = $_[0];
	bless \$rule, "PEF::Front::Request::Method::GET";
}

sub post ($) {
	my $rule = $_[0];
	bless \$rule, "PEF::Front::Request::Method::POST";
}

sub patch ($) {
	my $rule = $_[0];
	bless \$rule, "PEF::Front::Request::Method::PATCH";
}

sub put ($) {
	my $rule = $_[0];
	bless \$rule, "PEF::Front::Request::Method::PUT";
}

sub del ($) {
	my $rule = $_[0];
	bless \$rule, "PEF::Front::Request::Method::DELETE";
}

sub websocket ($) {
	my $rule = $_[0];
	bless \$rule, "PEF::Front::Request::Method::WEBSOCKET";
}

sub sse ($) {
	my $rule = $_[0];
	bless \$rule, "PEF::Front::Request::Method::SSE";
}

my @rewrite;
my $rulepos = 0;
my $nurlpos = 1;
my $flagpos = 2;
my $tranpos = 3;

sub add_route {
	my @params = @_;
	shift @params if @params & 1;
	for (my $i = 0; $i < @params; $i += 2) {
		my ($rule, $rdest) = @params[$i, $i + 1];
		my $check_method = '';
		my $required_method;
		if ($required_method = blessed $rule and $required_method =~ /^PEF::Front::Request::Method::/) {
			$required_method =~ s/.*:://;
			$rule         = $$rule;
			$check_method = "return if \$request->method ne '$required_method';";
		}
		push @rewrite, [$rule, undef, {}, undef];
		my $ri = $#rewrite;
		if (ref($rdest) eq 'ARRAY') {
			$rewrite[$ri][$nurlpos] = $rdest->[0];
			my @flags = split /[, ]+/, $rdest->[1] if @$rdest > 1;
			for my $f (@flags) {
				my ($p, $v) = split /=/, $f, 2;
				$p = uc $p;
				if ($p eq 'RE' && !$v) {
					warn "regexp rule with empty flags value: $rule -> $rdest->[0] / $rdest->[1]";
					next;
				}
				$rewrite[$ri][$flagpos]{$p} = $v;
			}
		} elsif (ref($rdest) && ref($rdest) ne 'CODE') {
			die "bad routing rule at $rule";
		} else {
			$rewrite[$ri][$nurlpos] = $rdest;
		}
		if (ref($rule) eq 'Regexp') {
			if (!ref($rewrite[$ri][$nurlpos])) {
				$rewrite[$ri][$tranpos]
					= eval
					"sub {my \$request = \$_[0]; $check_method my \$url = \$request->path; return \$url if \$url =~ s\"$rule\""
					. $rewrite[$ri][$nurlpos] . "\""
					. (exists($rewrite[$ri][$flagpos]{RE}) ? $rewrite[$ri][$flagpos]{RE} : "")
					. "; return }";
			} else {
				$rewrite[$ri][$tranpos]
					= eval "sub {my \$request = \$_[0]; $check_method "
					. "my \@params = \$request->path =~ "
					. (
					exists($rewrite[$ri][$flagpos]{RE})
					? "m\"$rule\"" . $rewrite[$ri][$flagpos]{RE} . ";"
					: "m\"$rule\"; "
					)
					. "return \$rewrite[$ri][$nurlpos]->(\$request, \@params) if \@params;"
					. "return; }";
			}
		} elsif (ref($rule) eq 'CODE') {
			if (not defined($rewrite[$ri][$nurlpos])) {
				if ($required_method) {
					$rewrite[$ri][$tranpos] = sub {
						return if $_[0]->method ne $required_method;
						goto &$rule;
					};
				} else {
					$rewrite[$ri][$tranpos] = $rule;
				}
			} elsif (!ref $rewrite[$ri][$nurlpos]) {
				$rewrite[$ri][$tranpos]
					= eval "sub {my \$request = \$_[0]; $check_method "
					. "return '$rewrite[$ri][$nurlpos]' if \$rewrite[$ri][$rulepos]->(\$request);"
					. "return; }";
			} else {
				$rewrite[$ri][$tranpos]
					= eval "sub {my \$request = \$_[0]; $check_method "
					. "my \@params = \$rewrite[$ri][$rulepos]->(\$request);"
					. "return \$rewrite[$ri][$nurlpos]->(\$request, \@params) if \@params;"
					. "return; }";
			}
		} else {
			if (!ref $rewrite[$ri][$nurlpos]) {
				$rewrite[$ri][$tranpos]
					= eval "sub {my \$request = \$_[0]; $check_method "
					. "return '$rewrite[$ri][$nurlpos]' if \$request->path eq '$rule';"
					. "return; }";
			} else {
				$rewrite[$ri][$tranpos]
					= eval "sub {my \$request = \$_[0]; $check_method "
					. "return \$rewrite[$ri][$nurlpos]->(\$request) if \$request->path eq '$rule';"
					. "return; }";
			}
		}
	}
}

sub import {
	return if @rewrite;
	my ($class, @params) = @_;
	$class->export_to_level(1, $class, @EXPORT);
	add_route(@params);
}

sub rewrite_route {
	my $request = $_[0];
	for (my $i = 0; $i < @rewrite; ++$i) {
		my $rewrite_func  = $rewrite[$i][$tranpos];
		my $rewrite_flags = $rewrite[$i][$flagpos];
		if ((my $npi = $rewrite_func->($request))) {
			my $http_response;
			if (ref $npi) {
				$http_response = $npi->[2] if @$npi > 2;
				$rewrite_flags = $npi->[1] if @$npi > 1;
				$npi           = $npi->[0];
				$npi ||= '';
				if ($rewrite_flags and not ref $rewrite_flags) {
					$rewrite_flags = {map {my ($p, $v) = split /=/, $_, 2; (uc($p), $v)} split /[, ]+/, $rewrite_flags};
				}
			}
			if (%$rewrite_flags and exists $rewrite_flags->{R}) {
				$http_response ||= PEF::Front::Response->new(request => $request);
				$http_response->redirect($npi, $rewrite_flags->{R});
			}
			if (   !$http_response
				&& exists($rewrite_flags->{L})
				&& defined($rewrite_flags->{L})
				&& $rewrite_flags->{L} > 0)
			{
				$http_response = PEF::Front::Response->new(request => $request);
				$http_response->status($rewrite_flags->{L});
			}
			return $http_response
				if $http_response
				&& blessed($http_response)
				&& $http_response->isa('PEF::Front::Response');
			$request->path($npi) if defined $npi;
			last if %$rewrite_flags and exists $rewrite_flags->{L};
		}
	}
	return;
}

sub prepare_context {
	my ($request, $prefix) = @_;
	my $form = $request->params;
	my $lang;
	my ($src, $method, $params);
	if (cfg_url_contains_lang) {
		($lang, $src, $method, $params) = $request->path =~ m{^/(\w{2})/(\Q$prefix\E)([^/]+)/?(.*)$};
		if (not defined $lang) {
			my $http_response = PEF::Front::Response->new(request => $request);
			$http_response->redirect(cfg_location_error);
			return $http_response;
		}
	} else {
		($src, $method, $params) = $request->path =~ m{^/(\Q$prefix\E)([^/]+)/?(.*)$};
		if (not defined $method) {
			my $http_response = PEF::Front::Response->new(request => $request);
			$http_response->redirect(cfg_location_error);
			return $http_response;
		}
		$lang = PEF::Front::NLS::guess_lang($request);
	}
	cfg_parse_extra_params($src, $params, $form);
	return PEF::Front::Response->new(request => $request, status => 404) if $method =~ /[\/.\\]/;
	my $rm = $method;
	$method =~ tr/_/ /;
	$method =~ s/[[:upper:]]\K([[:upper:]])/ \l$1/g;
	$method =~ s/[[:lower:]]\K([[:upper:]])/ \l$1/g;
	$method = lcfirst $method;

	if (cfg_url_only_camel_case) {
		my $mrf = $method;
		$mrf =~ s/ ([[:lower:]])/\u$1/g;
		$mrf = ucfirst($mrf);
		return PEF::Front::Response->new(request => $request, status => 404) if $mrf ne $rm;
	}
	return {
		ip        => $request->remote_ip,
		lang      => $lang,
		hostname  => $request->hostname,
		path      => $request->path,
		path_info => $request->path_info,
		form      => $form,
		headers   => $request->headers,
		scheme    => $request->scheme,
		cookies   => $request->cookies,
		method    => $method,
		src       => $src,
		request   => $request,
	};
}

sub www_static_handler {
	my ($request, $http_response) = @_;
	my $path = $request->path;
	$path =~ s|/{2,}|/|g;
	my @path = split /\//, $path;
	my $valid = 1;
	for (my $i = 0; $i < @path; ++$i) {
		if ($path[$i] eq '..') {
			--$i;
			if ($i < 1) {
				$valid = 0;
				cfg_log_level_error && $request->logger->(
					{   level   => "error",
						message => "not allowed path: " . $request->path
					}
				);
				last;
			}
			splice @path, $i, 2;
			--$i;
		}
	}
	my $sfn = cfg_www_static_dir . $request->path;
	if ($valid && -e $sfn && -r $sfn && -f $sfn) {
		use feature 'state';
		state $file_magic = File::LibMagic->new;
		my $ctype = $file_magic->checktype_filename($sfn);
		if ($ctype =~ /^text\/plain/) {
			state $suffix_map = {
				'.css' => "text/css",
				'.js'  => "application/javascript",
			};
			my ($name, $path, $suffix) = fileparse($sfn, qr/\.[^.]+$/);
			$suffix = lc $suffix;
			if ($suffix_map->{$suffix}) {
				$ctype =~ s/^text\/plain/$suffix_map->{$suffix}/;
			}
		}
		$http_response->status(200);
		$http_response->set_header('content-type',   $ctype);
		$http_response->set_header('content-length', -s $sfn);
		open my $bh, "<", $sfn;
		$http_response->set_body($bh);
	}
}

our %handlers = (
	'/app'    => \&PEF::Front::RenderTT::handler,
	'/ajax'   => \&PEF::Front::Ajax::handler,
	'/get'    => \&PEF::Front::Ajax::handler,
	'/submit' => \&PEF::Front::Ajax::handler,
);

sub add_prefix_handler {
	my ($prefix, $handler) = @_;
	$prefix = '/' . $prefix if substr($prefix, 0, 1) ne '/';
	die "bad handler type" if ref $handler ne 'CODE';
	$handlers{$prefix} = $handler;
}

sub process_request {
	my ($request, $parent_context) = @_;
	$request = PEF::Front::Request->new($request) if not blessed $request;
	cfg_log_level_info
		&& $request->logger->({level => "info", message => "serving request: " . $request->path});
	my $http_response = rewrite_route($request);
	return $http_response->response if $http_response;
	if (cfg_url_contains_lang
		&& (length($request->path) < 4 || substr($request->path, 3, 1) ne '/'))
	{
		my $lang = PEF::Front::NLS::guess_lang($request);
		if ($request->method eq 'GET') {
			$http_response = PEF::Front::Response->new(request => $request);
			$http_response->redirect("/$lang" . $request->request_uri);
			return $http_response->response();
		} else {
			$request->path("/$lang" . $request->path);
		}
	}
	my $lang_offset = (cfg_url_contains_lang) ? 3 : 0;
	my $handler;
	my $handler_prefix;
	for my $prefix (keys %handlers) {
		if (substr($request->path, $lang_offset, length $prefix) eq $prefix
			&& (!cfg_url_only_camel_case || substr($request->path, $lang_offset + length $prefix, 1) =~ /^[A-Z]$/))
		{
			$handler = $handlers{$prefix};
			$handler_prefix = substr($prefix, 1);
			last;
		}
	}
	if ($handler) {
		my $context = prepare_context($request, $handler_prefix);
		if (blessed($context) && $context->isa('PEF::Front::Response')) {
			return $context->response();
		}
		$context->{parent_context} = $parent_context;
		$handler->($request, $context);
	} else {
		$http_response = PEF::Front::Response->new(request => $request, status => 404);
		www_static_handler($request, $http_response) if cfg_handle_static;
		$http_response->response();
	}
}

sub to_app {
	\&process_request;
}

1;

__END__

=head1 NAME

B<PEF::Front::Route> - Routing of incoming requests

=head1 DESCRIPTION

B<PEF::Front> has already pre-defined routing schema. This document describes
this schema and methods to amend it.

=head1 ROUTING

Incoming requests must be associated with their handlers. 
Standard schema is following:

=over

=item B</app$Template>

Returns processed template. Its file name is a lower-case converted 
from CamelCase form. Like: C</appIndex> -> C<index.html>, 
C</appUserSettings> -> C<user_settings.html>. It's possible
to have some extra parameters like C</appArticle/id-283>
and then parameter C<id> will be equal to "283". 
Without parameter name this value will be put into parameter C<cookie>.

See C<cfg_parse_extra_params> in L<PEF::Front::Config>.

=item B</ajax$Method>

Returns JSON answer, doesn't support redirects. By default doesn't parse
parameters from URI path. Method name is lower-case converted 
from CamelCase form: C</ajaxGetUserInfo> -> "get user info".

=item B</submit$Method>

It's like C</ajax$Method> but support redirects and content can be in 
any form.

=item B</get$Method>

It's like C</submit$Method> but by default parses parameters from URI path. 

=back

=head2 CUSTOM PRFIXES

=head3 B<add_prefix_handler($prefix, $handler)>

Application can define its own prefix handlers B</$prefix$Method>. 
C<$handler> is a code reference that receives C<($request, $context)>.

=head2 RULES

Using routing rules this schema can be changed completely. You can import
your routing rules in  C<PEF::Front::Route> or add them  with
C<PEF::Front::Route::add_route(@rules)>. 

  use PEF::Front::Route ('/' => '/appIndex');
  
or

  use PEF::Front::Route;
  PEF::Front::Route::add_route('/' => '/appIndex');
  
Routing is always given by pairs: C<rule> => C<destination>. 
Destination can be simple value or 2 or 3-elements array with value, flags 
and L<PEF::Front::Response> object.

C<flags> can be string like "L=404" or hash like {L => 404}. 
In string form flags are separated by space or comma.

  PEF::Front::Route::add_route(
    '/'        => '/appIndex',
    '/me'      => ['/appUser', 'L'],
    '/oldpath' => ['/', 'R=301'],
  );

Following flags are recognized:

=over

=item B<R>

By default it's temporary redirect but status parameter can change it, 
for example C<R=301> means permanent redirect. This flag automatically
means 'Last destination'.

=item B<L>

Last destination. Parameter can set response status: C<L=404>.

=item B<RE>

Regexp flags for matching or substitution operator. Like C<RE=g>.

=back

Following combinations of rules and destinations are supported:

=over

=item B<string> => B<string>

Replaces one path with another.

=item B<Regexp> => B<string>

Transformation function is simple regexp substitution: 
C<s"$regexp"$string"$flags>.

  qr"/index(.*)" => '/appIndex$1'

=item B<Regexp> => B<CODE>.

If C<m"$regexp"$flags> is true then supplied function is called with params
C<($request, @params)>, where C<@params> is array of matched groups of
C<$regexp>.

=item B<string> => B<CODE>

When path is exactly equal to the strng then supplied subroutine is called 
with parameter C<($request)>.

=item B<CODE> => B<string>

When supplied subroutine with parameter C<($request)> returns true
then path is replaces with the string.

=item B<CODE => B<CODE>

When supplied subroutine with parameter C<($request)> returns true
then second subroutine called with params C<($request, @params)>
where C<@params> is result of first matching function.

=item B<CODE> => B<undef>

Supplied function with parameter C<($request)> checks path and returns new 
destination.

=back

Routing process is executed in order of rules addition. 
Final destination of the routing process can have one of supported prefixes
or point to some static content. If static content is not supported or no such 
content found then response with 404 status is returned.

Using B<CODE> => B<undef> you can implement any URL mapping that you wish.

  # quasi-RESTful

  sub my_routing {
    my $path = $_[0]->path;
    my ($resource, $id) = $path =~ m{^/([^/]+)/?([^/]+)?};
    $resource = ucfirst $resource;
    my $action = ucfirst lc $_[0]->method;
    $_[0]->param(id => $id) if defined $id;
    return ["/ajax$action$resource", "L"];
  }
  
  PEF::Front::Route::add_route(\&my_routing => undef);

During routing process you can change request parameters and put some notes to
it. See C<note($key [, $value])> in L<PEF::Front::Request>.

This module exports these functions: C<get post patch put delete trace websocket sse>
to help with HTTP method filtering.

  PEF::Front::Route::add_route(
    get  '/' => '/appIndex',
    post '/' => '/ajaxLogin',
  );

=head1 APPLICATION ENTRY POINT

You startup file must return reference to subroutine that accept incoming 
request. C<PEF::Front::Route->to_app()> is this reference. Your last
line in startup file usually should be

  PEF::Front::Route->to_app(); 
  
=head1 AUTHOR
 
This module was written and is maintained by Anton Petrusevich.

=head1 Copyright and License
 
Copyright (c) 2016 Anton Petrusevich. Some Rights Reserved.
 
This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
