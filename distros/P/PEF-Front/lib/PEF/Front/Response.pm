package PEF::Front::Response;
use strict;
use warnings;
use Time::Duration::Parse;
use Scalar::Util qw(blessed);
use Encode;
use utf8;
use URI::Escape;
use URI;
use PEF::Front::Config;
use PEF::Front::Headers;

sub new {
	my ($class, %args) = @_;
	my $status   = delete $args{status}  || 200;
	my $body     = delete $args{body}    || [];
	my $base_url = delete $args{base}    || '';
	my $href     = delete $args{headers} || [];
	my $cref     = delete $args{cookies} || [];
	my @headers;
	my @cookies;
	if (ref($href) eq 'HASH') {
		@headers = %$href;
	} elsif (ref($href) eq 'ARRAY') {
		@headers = @$href;
	} else {
		@headers = ($href);
	}
	if (ref($cref) eq 'HASH') {
		@cookies = %$cref;
	} elsif (ref($cref) eq 'ARRAY') {
		@cookies = @$cref;
	} else {
		@cookies = ($cref);
	}
	my $request = delete $args{request};
	if ($request && blessed($request) && $request->isa("PEF::Front::Request")) {
		$base_url ||= $request->base;
		if (not $request->out_headers->is_empty) {
			unshift @headers, $request->out_headers;
		}
		if (not $request->out_cookies->is_empty) {
			unshift @cookies, $request->out_cookies;
		}
	}
	$body = [$body] if not ref $body;
	my $self = bless {
		status   => $status,
		headers  => PEF::Front::HTTPHeaders->new(@headers),
		cookies  => PEF::Front::Headers->new(@cookies),
		body     => $body,
		base_url => $base_url
	}, $class;
	$self;
}

sub add_header {
	my ($self, $key, $value) = @_;
	$self->{headers}->add_header($key, $value);
}

sub set_header {
	my ($self, $key, $value) = @_;
	$self->{headers}->set_header($key, $value);
}

sub remove_header {
	my ($self, $key, $value) = @_;
	$self->{headers}->remove_header($key, $value);
}

sub get_header {
	my ($self, $key) = @_;
	$self->{headers}->get_header($key);
}

sub set_cookie {
	my ($self, $key, $value) = @_;
	$self->{cookies}->set_header($key, $value);
}

sub remove_cookie {
	my ($self, $key) = @_;
	$self->{cookies}->remove_header($key);
}

sub get_cookie {
	my ($self, $key) = @_;
	$self->{cookies}->get_header($key);
}

sub set_body {
	my ($self, $body) = @_;
	$self->{body} = ref($body) ? $body : [$body];
}

sub add_body {
	my ($self, $body) = @_;
	if (ref($self->{body}) eq 'ARRAY') {
		push @{$self->{body}}, $body;
	} else {
		$self->set_body($body);
	}
}

sub get_body {$_[0]->{body}}

sub status {
	my ($self, $status) = @_;
	$self->{status} = $status if defined $status;
	$self->{status};
}

sub redirect {
	my ($self, $url, $status) = @_;
	if ($url) {
		if ($self->{base_url} ne '') {
			my $nuri = URI->new_abs($url, $self->{base_url});
			$url = $nuri->as_string;
		}
		$self->set_header(Location => $url);
		if (!defined $status) {
			$status ||= $self->status;
			$self->status(302) if $status < 300 || $status > 399;
		} else {
			$self->status($status);
		}
		$self->remove_header('Content-Type');
	}
}

sub content_type {
	my ($self, $type) = @_;
	$self->set_header('Content-Type' => $type) if $type;
	return $self->get_header('Content-Type') if defined wantarray;
}

my @dow = qw(Sun Mon Tue Wed Thu Fri Sat);
my @mon = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);

sub expires {
	my $expires = eval {parse_duration($_[0])} || 0;
	my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = gmtime(time + $expires);
	sprintf "%s, %02d-%s-%04d %02d:%02d:%02d GMT", $dow[$wday], $mday, $mon[$mon], 1900 + $year, $hour, $min, $sec;
}

sub _safe_encode_utf8 {
	return encode_utf8($_[0]) if not ref($_[0]) && utf8::is_utf8($_[0]);
	$_[0];
}

sub make_headers {
	my ($self) = @_;
	my $headers = $self->{headers}->get_all_headers;
	for (@$headers) {
		$_ = encode_utf8($_) if utf8::is_utf8($_);
	}
	my $cookies = $self->{cookies}->get_all_headers;
	for (my $i = 0; $i < @$cookies; $i += 2) {
		my $name  = _safe_encode_utf8($cookies->[$i]);
		my $value = $cookies->[$i + 1];
		$value = '' if not defined $value;
		$value = {value => $value} unless ref($value) eq 'HASH';
		no utf8;
		my @cookie = (URI::Escape::uri_escape($name) . "=" . URI::Escape::uri_escape(_safe_encode_utf8($value->{value})));
		push @cookie, "domain=" . $value->{domain}            if $value->{domain};
		push @cookie, "path=" . $value->{path}                if $value->{path};
		push @cookie, "expires=" . expires($value->{expires}) if $value->{expires};
		push @cookie, "max-age=" . $value->{"max-age"}        if $value->{"max-age"};
		push @cookie, "secure"                                if $value->{secure};
		push @cookie, "HttpOnly"                              if $value->{httponly};
		push @$headers, ('Set-Cookie' => join "; ", @cookie);
	}
	return [$self->status, $headers];
}

sub response {
	my ($self) = @_;
	my $out = $self->make_headers;
	if ('ARRAY' eq ref $self->{body}) {
		for (@{$self->{body}}) {
			$_ = encode_utf8($_) if utf8::is_utf8($_);
		}
	}
	push @$out, $self->{body};
	return $out;

}

1;

__END__

=head1 NAME
 
PEF::Front::Response - HTTP response object

=head1 SYNOPSIS

  use PEF::Front::Response;
  use PEF::Front::Route;
  
  PEF::Front::Route::add_route(
   get '/' => sub {
      PEF::Front::Response->new(
        headers => ['Content-Type' => 'text/plain'], 
        body => 'Hello World!'
      );
    }
  );

=head1 DESCRIPTION

PEF::Front::Response is a response class for your applications. 
Generally, you will want to create instances of this class 
only as exceptions or in special cases.

=head1 FUNCTIONS

=head2 new(%params)
 
Returns a new Web::Response object. Valid parameters are:
 
=over 4
 
=item status
 
The HTTP status code for the response.
 
=item headers
 
The headers to return with the response. Can be provided as an arrayref, a
hashref, or an L<PEF::Front::HTTPHeaders> object.
 
=item cookies
 
The cookies to return with the response. Can be provided as an arrayref, a
hashref, or an L<PEF::Front::Headers> object.

The values of cookies can either be the string values of the cookies, or a 
hashref whose keys can be any of C<value>, C<domain>, C<path>, C<expires>, 
C<max-age>, C<secure>, C<httponly>. Defaults to C<{}>.
 
=item body
 
The content of the request. Can be provided as a string, an arrayref containing 
a list of either of strings, a filehandle, or code reference.
Defaults to C<''>.
 
=item base

Base URL for incomplete redirect location.

=item request

L<PEF::Front::Request> object to import C<base>, C<headers> and C<cookies> 
from.

=back
 
=head2 status([$status])
 
Sets (and returns) the status attribute, as described above.

=head2 add_header($key, $value)

Adds response header. This action allows to have multiple headers 
with the same name.

=head2 set_header($key, $value)

Sets response header. This action ensures that there's only one header 
with given name in response.

=head2 remove_header($key)

Removes header.

=head2 get_header($key)

Returns header.

=head2 set_cookie($key, $value)

Sets cookie value.

=head2 remove_cookie($key)

Removes cookie.

=head2 get_cookie($key)

Returns get_cookie.

=head2 set_body($body)

Sets response body. It can be string, array of strings, file handle or code reference.

=head2 add_body($body_chunk)

Adds response body chunk.

=head2 get_body 

Returns response body.

=head2 redirect($location, $status)

Response will redirect browser to new location.

=head2 content_type($ct)

Sets 'Content-Type'

=head2 expires($expires)

Makes 'expires' cookie attribute. $expires is time interval parseable 
by L<Time::Duration>.

=head2 make_headers

Makes all response headers.

=head2 response

Returns a valid L<PSGI> response, based on the values given.

=head1 AUTHOR
 
This module was written and is maintained by Anton Petrusevich.

=head1 Copyright and License
 
Copyright (c) 2016 Anton Petrusevich. Some Rights Reserved.
 
This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

