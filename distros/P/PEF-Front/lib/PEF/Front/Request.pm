package PEF::Front::Request;
use strict;
use warnings;
use JSON;
use Carp ();
use utf8;
use Encode;
use PEF::Front::Headers;
use PEF::Front::File;
use PEF::Front::Config;
use XML::Simple;
use URI;

my $coro_ae = $INC{'Coro/AnyEvent.pm'} ? 1 : 0;

sub new {
	my ($class, $env) = @_;
	Carp::croak(q{$env is required})
		unless defined $env && ref($env) eq 'HASH';
	my $self = bless {env => $env}, $class;
	$self->_parse;
	$self;
}
sub env               {$_[0]->{env}}
sub remote_ip         {$_[0]->{env}{REMOTE_ADDR}}
sub protocol          {$_[0]->{env}{SERVER_PROTOCOL}}
sub http_method       {$_[0]->{env}{REQUEST_METHOD}}
sub port              {$_[0]->{env}{SERVER_PORT}}
sub user              {$_[0]->{env}{REMOTE_USER}}
sub request_uri       {$_[0]->{env}{REQUEST_URI}}
sub path_info         {$_[0]->{env}{PATH_INFO}}
sub query_string      {$_[0]->{env}{QUERY_STRING}}
sub script_name       {$_[0]->{env}{SCRIPT_NAME}}
sub scheme            {$_[0]->{env}{'psgi.url_scheme'}}
sub uri               {URI->new($_[0]->base)}
sub secure            {$_[0]->scheme eq 'https'}
sub _input            {$_[0]->{env}{'psgi.input'}}
sub content_length    {$_[0]->{env}{CONTENT_LENGTH}}
sub content_type      {$_[0]->{env}{CONTENT_TYPE}}
sub raw_body          {$_[0]->{raw_body}}
sub content_encoding  {$_[0]->headers->get_header("content_encoding")}
sub header            {$_[0]->headers->get_header($_[1])}
sub referer           {$_[0]->headers->get_header("referer")}
sub user_agent        {$_[0]->headers->get_header("user_agent")}
sub set_out_header    {$_[0]->out_headers->set_header($_[1] => $_[2])}
sub remove_out_header {$_[0]->out_headers->remove_header($_[1])}
sub get_out_header    {$_[0]->out_headers->get_header($_[1])}
sub set_out_cookie    {$_[0]->out_cookies->set_header($_[1] => $_[2])}
sub remove_out_cookie {$_[0]->out_cookies->remove_header($_[1])}
sub get_out_cookie    {$_[0]->out_cookies->get_header($_[1])}

sub method {
	my $xm = $_[0]{method};
	return $xm if $xm;
	if (my $hmo = $_[0]->{env}{HTTP_X_HTTP_METHOD_OVERRIDE}) {
		$_[0]{method} = uc $hmo;
	} elsif (
		$_[0]->{env}{HTTP_UPGRADE}
		&& $_[0]->{env}{HTTP_CONNECTION}
		&& $_[0]->{env}{HTTP_UPGRADE} eq 'WebSocket'
		&& $_[0]->{env}{HTTP_CONNECTION} eq 'Upgrade'
		)
	{
		$_[0]{method} = 'WEBSOCKET';
	} elsif ($_[0]->{env}{HTTP_ACCEPT}
		&& $_[0]->{env}{HTTP_ACCEPT} eq 'text/event-stream')
	{
		$_[0]{method} = 'SSE';
	} else {
		$_[0]{method} = $_[0]->{env}{REQUEST_METHOD};
	}
	$_[0]{method};
}

sub logger {
	my $self = $_[0];
	cfg_logger($self)
		|| sub {$self->{env}{'psgi.errors'}->print($_[0]->{message});}
}

sub _parse {
	my $self = $_[0];
	$self->_parse_query_params;
	$self->_parse_request_body if $self->{env}{CONTENT_LENGTH} || $self->{env}{CONTENT_TYPE};
}

sub params {
	my $self = $_[0];
	return $self->{params} if exists $self->{params};
	my $q = $self->{query_params} || {};
	my $p = $self->{body_params}  || {};
	$self->{params} = {%$p, %$q};
	if (exists $self->{params}{json}) {
		my $form = eval {from_json $self->{params}{json}} || {};
		$self->logger({level => "warn", message => $@}) if $@;
		$self->{params} = {%{$self->{params}}, %$form};
	}
	$self->{params};
}

sub path {
	my $self = $_[0];
	return $self->{path} if @_ == 1 and exists $self->{path};
	$self->{path} ||= decode_utf8($self->{env}{PATH_INFO} || '/');
	if (@_ == 2) {
		my $np = (utf8::is_utf8($_[1]) ? $_[1] : decode_utf8 $_[1]);
		if (not defined $np or $np =~ /^\s*$/) {
			$self->{path} = '/';
		} else {
			if (substr($np, 0, 1) ne '/') {
				$self->{path} = substr($self->{path}, 0, rindex($self->{path}, '/') + 1) . $np;
			} else {
				$self->{path} = $np;
			}
		}
	}
	return $self->{path};
}

sub note {
	my ($self, $key, $value) = @_;
	if (@_ == 3) {
		$self->{note}{$key} = $value;
	}
	if (exists $self->{note}{$key}) {
		$self->{note}{$key};
	} else {
		return;
	}
}

sub out_headers {
	my $self = shift;
	if (not $self->{out_headers}) {
		$self->{out_headers} = PEF::Front::HTTPHeaders->new;
	}
	$self->{out_headers};
}

sub out_cookies {
	my $self = shift;
	if (not $self->{out_cookies}) {
		$self->{out_cookies} = PEF::Front::Headers->new;
	}
	$self->{out_cookies};
}

sub param {
	my ($self, $param, $value) = @_;
	return $self->params->{$param} if not defined $value;
	$self->params->{$param} = (utf8::is_utf8($value) ? $value : decode_utf8 $value);
}

sub hostname {
	my $self = $_[0];
	return $self->{hostname} if exists $self->{hostname};
	$self->{hostname} = $self->{env}{HTTP_HOST} || $self->{env}{SERVER_NAME};
	$self->{hostname} =~ s/:\d+//;
	$self->{hostname};
}

sub base {
	my $self = $_[0];
	return $self->{base} if exists $self->{base};
	$self->{base} = $self->scheme . "://" . ($self->{env}{HTTP_HOST} || $self->{env}{SERVER_NAME}) . $self->request_uri;
	$self->{base};
}

sub cookies {
	my $self = $_[0];
	return {} unless $self->{env}{HTTP_COOKIE};
	return $self->{cookies} if exists $self->{cookies};
	my %results;
	my @pairs = grep m/=/, split "[;,] ?", $self->{env}{HTTP_COOKIE};
	for my $pair (@pairs) {
		$pair =~ s/^\s+//;
		$pair =~ s/\s+$//;
		my ($key, $value) = map {
			tr/+/ /;
			s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
			decode_utf8 $_
		} split("=", $pair, 2);
		$results{$key} = $value;
	}
	$self->{cookies} = \%results;
}

sub _php_jquery_param {
	my ($root, $path, $value) = @_;
	my @struct = $path =~ /\[?([^\[\]]+)\]?/g;
	return if !@struct;
	my $sl = \$root;
	for my $key (@struct) {
		if ($key =~ /^\d+$/) {
			$$sl //= [];
			$sl = \$$sl->[$key];
		} else {
			$$sl //= {};
			$sl = \$$sl->{$key};
		}
	}
	if (substr($path, -2, 2) eq '[]') {
		push @$$sl, $value;
		$sl = \$$sl->[-1];
	} else {
		$$sl = $value;
	}
	return $sl;
}

sub _parse_urlencoded {
	my $query = $_[0];
	my $form  = {};
	my @pairs = split(/[&;]/, $query);
	foreach my $pair (@pairs) {
		my ($name, $value) = map {
			tr/+/ /;
			s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
			eval {decode_utf8 $_}
			}
			split(/=/, $pair, 2);
		if (index($name, "[") >= 0 && index($name, "]") > 0) {
			_php_jquery_param($form, $name, $value);
		} else {
			$form->{$name} = $value if defined $name and $name ne '';
		}
	}
	return $form;
}

sub headers {
	my $self = shift;
	if (!defined $self->{headers}) {
		my $env = $self->{env};
		$self->{headers} = PEF::Front::HTTPHeaders->new(
			map {
				(my $field = decode_utf8 $_) =~ s/^HTTPS?_//;
				($field => decode_utf8 $env->{$_});
				}
				grep {
				/^HTTP/ || /^CONTENT/
				} keys %$env
		);
	}
	$self->{headers};
}

sub _parse_query_params {
	my $self = $_[0];
	return {} if !$self->{env}{QUERY_STRING};
	return $self->{query_params} if exists $self->{query_params};
	$self->{query_params} = _parse_urlencoded($self->{env}{QUERY_STRING});
}

sub _parse_request_body {
	my $self = $_[0];
	my $ct   = $self->{env}{CONTENT_TYPE};
	my $cl   = $self->{env}{CONTENT_LENGTH};
	if (!$ct && !$cl) {
		return;
	}
	return $self->{body_params} if exists $self->{body_params};
	my $read_body_sub = sub {
		$self->{raw_body} = '';
		my $buffer;
		while ($cl && $self->_input->read($buffer, $cl))
		{
			$self->{raw_body} .= $buffer;
			$cl -= length $buffer;
		}
	};
	if (index($ct, 'application/x-www-form-urlencoded') == 0) {
		$read_body_sub->();
		$self->{body_params} = _parse_urlencoded($self->{raw_body});
	} elsif (index($ct, 'application/json') == 0) {
		$read_body_sub->();
		my $from_json = $self->{raw_body};
		if (substr($self->{raw_body}, 0, 2) eq '%7') {
			$from_json =~ tr/+/ /;
			$from_json =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
		}
		$self->{body_params} = eval {$from_json && decode_json $from_json } || {};
		return $self->{body_params};
	} elsif (index($ct, 'application/xml') == 0) {
		$read_body_sub->();
		$self->{body_params} = eval {XMLin $self->{raw_body}} || {};
		return $self->{body_params};
	} elsif (index($ct, 'multipart/form-data') == 0) {
		$self->_parse_multipart_form;
	}
	return $self->{body_params};
}

sub _headers_block_size() {256}
sub _read_chunk_size()    {32768}

sub _parse_multipart_form {
	my $self   = $_[0];
	my $buffer = '';
	my $input  = $self->_input;
	my $cl     = $self->{env}{CONTENT_LENGTH};
	my $ct     = $self->{env}{CONTENT_TYPE};
	$self->{body_params} = {};
	my $form = $self->{body_params};
	my ($boundary) = $ct =~ /boundary=\"?([^\";,]+)\"?/;
	return if not defined $boundary;
	my $start_boundary = "--" . $boundary . "\x0d\x0a";
	my $end_boundary   = "--" . $boundary . "--\x0d\x0a";
	my $lchnk          = 0;
	my $current_field_ref;

	while (1) {
		my $chunk;
		my $start = index($buffer, $start_boundary);
		$start = index($buffer, $end_boundary) if $start == -1;
		$buffer .= $chunk if $start == -1 && $input->read($chunk, _read_chunk_size);
		last if $buffer eq '';
		$start = index($buffer, $start_boundary) if $start == -1;
		$start = index($buffer, $end_boundary)   if $start == -1;
		my $field_sub = sub {

			if (   $buffer ne ''
				&& $buffer =~ /^Content-Disposition:/
				&& (my $body_start = index($buffer, "\x0d\x0a\x0d\x0a")))
			{
				my $header = substr($buffer, 0, $body_start);
				substr($buffer, 0, $body_start + 4, '');
				my $next_start = index($buffer, $start_boundary);
				$next_start = index($buffer, $end_boundary) if $next_start == -1;
				my $current_value;
				if ($next_start >= 0) {
					$current_value = substr($buffer, 0, $next_start - 2);
					substr($buffer, 0, $next_start, '');
				} else {
					$current_value = '';
				}
				my ($name) = ($header =~ /name="?([^";\x0d\x0a]*)[";]?/);
				my ($file) = ($header =~ /filename="?([^";\x0d\x0a]*)[";\x0d\x0a]?/);
				my ($type) = ($header =~ /Content-Type:\s*(\S+)/);
				$name ||= '';
				utf8::decode($name);
				if (index($name, "[") >= 0 && index($name, "]") > 0) {
					$current_field_ref = _php_jquery_param($form, $name, '');
				} else {
					$current_field_ref = \$form->{$name};
				}
				if (defined($file) && $file ne '') {
					($file) = ($file =~ /([^\/\\]*)$/);
					$file =~ s/^\s*//;
					$file =~ s/\s*$//;
					$file =~ s/^(\w+:+)+//;
					if ($file eq '' || substr($file, 0, 1) eq '.') {
						$file = "unnamed_upload" . $file;
					}
					$$current_field_ref = PEF::Front::File->new(
						filename => decode_utf8($file),
						size     => $cl,
						content_type => $type || 'application/octet-stream',
					);
					$$current_field_ref->append($current_value);
				} else {
					$$current_field_ref = $current_value;
				}
				if ($next_start >= 0) {
					utf8::decode($$current_field_ref)
						if not ref $$current_field_ref eq 'PEF::Front::File';
					$current_field_ref = undef;
				}
				return 1;
			}
			return;
		};
		if ($start >= 0) {
			my $end = index($buffer, $end_boundary);
			if ($end == 0) {
				if (defined $current_field_ref and not ref $$current_field_ref) {
					utf8::decode($$current_field_ref);
					$current_field_ref = undef;
				}
				last;
			}
			my $be = $end == $start ? 2 : 0;
			if (    defined $current_field_ref
				and ref $$current_field_ref eq 'PEF::Front::File'
				and $start > 1)
			{
				$$current_field_ref->append(substr($buffer, 0, $start - 2));
				$$current_field_ref->finish;
				$current_field_ref = undef;
				substr($buffer, 0, $start + length($start_boundary) + $be, '');
			} elsif (defined $current_field_ref) {
				$$current_field_ref .= substr($buffer, 0, $start - 2) if $start > 1;
				utf8::decode($$current_field_ref);
				$current_field_ref = undef;
				substr($buffer, 0, $start + length($start_boundary) + $be, '');
			}
			if (not $field_sub->()) {
				substr($buffer, 0, $start + length($start_boundary) + $be, '');
			}
		} else {
			my $store_chunk = $lchnk > _headers_block_size ? $lchnk - _headers_block_size : 0;
			if (length($buffer) < $store_chunk + _headers_block_size * 2) {
				if (length($buffer) > _headers_block_size * 2) {
					$store_chunk = length($buffer) - _headers_block_size;
				} else {
					$store_chunk = 0;
				}
			}
			if (defined $current_field_ref and ref $$current_field_ref eq 'PEF::Front::File') {
				if ($store_chunk) {
					$$current_field_ref->append(substr($buffer, 0, $store_chunk));
					substr($buffer, 0, $store_chunk, '');
				}
			} elsif (defined $current_field_ref) {
				if ($store_chunk) {
					$$current_field_ref .= substr($buffer, 0, $store_chunk);
					substr($buffer, 0, $store_chunk, '');
				}
			} else {
				$field_sub->();
			}
		}
		$lchnk = length $buffer;
	}
	return $form;
}
1;
__END__

=head1 NAME

PEF::Front::Request - HTTP request object from PSGI env hash

=head1 SYNOPSIS

package My::Local::Test;

  sub test {
    my ($msg, $context) = @_;
    return {
        result    => "OK",
        data      => [1, 2],
        path_info => $context->{request}->path_info
    };
  }

=head1 DESCRIPTION

L<PEF::Front::Request> provides a consistent API for request objects across
PEF::Front framework.

=head1 CAVEAT

This module is intended to be used by web application developers only in rare circumstances.
Developers can receive an object of this type in "Local", "InFilter" and "OutFilter" handlers via hash "context". 

=head1 METHODS

Unless otherwise noted, all methods and attributes are B<read-only>,
and passing values to the method like an accessor doesn't work like
you expect it to.

=over 2

=item new($env)

    PEF::Front::Request->new( $env );

Creates a new request object from supplied $env hash.

=item env()

Returns the shared PSGI environment hash reference. This is a
reference, so writing to this environment passes through during the
whole PSGI request/response cycle.

=item remote_ip()

Returns the IP address of the client (C<REMOTE_ADDR>).

=item http_method()

Contains the request method (C<GET>, C<POST>, C<HEAD>, etc) from HTTP 
protocol directly.

=item method()

Contains the request method (C<GET>, C<POST>, C<HEAD>, etc) from HTTP protocol
but it understands also C<X-HTTP-Method-Override> header and C<WEBSOCKET>, 
C<SSE> types of request.

=item protocol()

Returns the protocol (HTTP/1.0 or HTTP/1.1) used for the current request.

=item request_uri()

Returns the raw, undecoded request URI path. You probably do B<NOT>
want to use this to dispatch requests.

=item path_info()

Returns B<PATH_INFO> in the environment. Use this to get the local
path for the requests.

=item path ( [$path] )

Similar to C<path_info> but can be changed during internal routing process. 
Decoded to utf8 perl internal representation.

=item query_string()

Returns B<QUERY_STRING> in the environment. This is the undecoded
query string in the request URI.

=item script_name()

Returns B<SCRIPT_NAME> in the environment. This is the absolute path
where your application is hosted. B<NOT TESTED>

=item scheme()

Returns the scheme (C<http> or C<https>) of the request.

=item secure()

Returns true or false, indicating whether the connection is secure (https).

=item uri()

Returns an URI object for the current request. 

Every time this method is called it returns a new, cloned URI object.

=item logger()

Returns (optional) configured C<cfg_logger> or C<psgix.logger> code reference.
When it exists, your application is supposed to send the log message to this 
logger, using:

  $req->logger->({ level => 'debug', message => "This is a debug message" });

=item cookies()

Returns a reference to a hash containing the cookies. Values are
strings that are sent by clients and are URI decoded.

If there are multiple cookies with the same name in the request, this
method will ignore the duplicates and return only the first value. If
that causes issues for you, you may have to use modules like
CGI::Simple::Cookie to parse C<<$request->header('Cookies')>> by
yourself.

=item params()

Returns a hash reference containing (merged) GET
and POST parameters.

=item raw_body()

Returns the request content in an undecoded byte string for POST requests.

=item hostname()

Returns hostname of current request.

=item base()

Returns full URL string of current request.

=item user()

Returns C<REMOTE_USER> if it's set.

=item headers()

Returns an L<PEF::Front::HTTPHeaders> object containing the headers for the current request.

=item content_encoding()

Shortcut to $req->headers->get_header("content_encoding").

=item content_length()

Returns length of content.

=item content_type()

Returns Content-Type header value.

=item header()

Shortcut to $req->headers->get_header.

=item referer()

Shortcut to $req->headers->get_header("referer").

=item user_agent()

Shortcut to $req->headers->get_header("user_agent").

=item param($param, [$value])

Returns GET and POST parameters. This is an alternative method for accessing parameters in
$req->params. It B<does> allow setting or modifying query parameters.

=item get_out_header($header)

=item get_out_cookie($cookie)

=item set_out_header($header, $value)

=item set_out_cookie($cookie, $value)

=item remove_out_header($header)

=item remove_out_cookie($cookie)

Set/get/remove headers and cookies that will be copied into response object.

=item C<note($key, $value)>

Set/get some extra info for request. Usefule during routing phase when 
context is not made up yet.

=back

=head1 AUTHORS

Anton Petrusevich. 

=head1 Copyright and License

Copyright (c) 2014 - 2016 Anton Petrusevich. Some Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
