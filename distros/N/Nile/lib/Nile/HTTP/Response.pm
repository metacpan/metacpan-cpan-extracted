#   Copyright Infomation
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Author : Dr. Ahmed Amin Elsheshtawy, Ph.D.
# Website: https://github.com/mewsoft/Nile, http://www.mewsoft.com
# Email  : mewsoft@cpan.org, support@mewsoft.com
# Copyrights (c) 2014-2015 Mewsoft Corp. All rights reserved.
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
package Nile::HTTP::Response;

our $VERSION = '0.55';
our $AUTHORITY = 'cpan:MEWSOFT';

=pod

=encoding utf8

=head1 NAME

Nile::HTTP::Response -  The HTTP response manager.

=head1 SYNOPSIS

    # get response instance
    $res = $app->response;

    $res->code(200);
    #$res->status(200);
    
    $res->header('Content-Type' => 'text/plain');
    #$res->content_type('text/html');
    $res->header(Content_Base => 'http://www.mewsoft.com/');
    $res->header(Accept => "text/html, text/plain, image/*");
    $res->header(MIME_Version => '1.0', User_Agent   => 'Nile Web Client/0.27');
    $res->cookies->{username} = {
            value => 'mewsoft',
            path  => "/",
            domain => '.mewsoft.com',
            expires => time + 24 * 60 * 60,
        };
    #$res->body("Hello world content");
    $res->content("Hello world content");

    # PSGI response
     $response = $res->finalize;
     # [$code, $headers, $body]
     ($code, $headers, $body) = @$response;
    
    # headers as string
    $headers_str = $res->headers_as_string($eol)
    
    # message as string
    print $res->as_string($eol);

    # HTTP/1.1 200 OK
    # Accept: text/html, text/plain, image/*
    # User-Agent: Nile Web Client/0.27
    # Content-Type: text/plain
    # Content-Base: http://www.mewsoft.com/
    # MIME-Version: 1.0
    # Set-Cookie: username=mewsoft; domain=.mewsoft.com; path=/; expires=Fri, 25-Jul-2014 19:10:45 GMT
    #
    # Hello world content

=head1 DESCRIPTION

Nile::HTTP::Response - The HTTP response manager allows you to create PSGI response array ref.

=cut

use Nile::Base;
use Scalar::Util ();
use HTTP::Headers;
use URI::Escape ();
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub main { # sub new{}
    my ($self, $code, $headers, $content) = @_;
    $self->status($code) if defined $code;
    $self->headers($headers) if defined $headers;
    $self->body($content) if defined $content;
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 headers

  $headers = $res->headers;
  $res->headers([ 'Content-Type' => 'text/html' ]);
  $res->headers({ 'Content-Type' => 'text/html' });
  $res->headers( HTTP::Headers->new );

Sets and gets HTTP headers of the response. Setter can take either an
array ref, a hash ref or L<HTTP::Headers> object containing a list of
headers.

This is L<HTTP::Headers> object and all its methods available:
    
    say $res->headers->header_field_names();
    say $res->headers->remove_content_headers();
    $res->headers->clear();

=cut

sub headers {

    my $self = shift;

    if (@_) {
        my $headers = shift;
        if (ref $headers eq 'ARRAY') {
            Carp::carp("Odd number of headers") if @$headers % 2 != 0;
            $headers = HTTP::Headers->new(@$headers);
        }
        elsif (ref $headers eq 'HASH') {
            $headers = HTTP::Headers->new(%$headers);
        }
        return $self->{headers} = $headers;
    }
    else {
        return $self->{headers} ||= HTTP::Headers->new();
    }
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 header

  $res->header('X-Foo' => 'bar');
  my $val = $res->header('X-Foo');

Sets and gets HTTP header of the response.

=cut

sub header { shift->headers->header(@_) }
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=head2 remove_header
    
    # delete
    $res->remove_header('Content-Type');

 Removes the header fields with the specified names.

=cut

sub remove_header { shift->headers->remove_header(@_) }
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 status

  $res->status(200);
  $status = $res->status;

Sets and gets HTTP status code. C<code> is an alias.

=cut

has status => (is => 'rw');
sub code    { shift->status(@_) }
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 body

  $res->body($body_str);
  $res->body([ "Hello", "World" ]);
  $res->body($io);

Gets and sets HTTP response body. Setter can take either a string, an
array ref, or an IO::Handle-like object. C<content> is an alias.

Note that this method doesn't automatically set I<Content-Length> for
the response. You have to set it manually if you want, with the
C<content_length> method.

=cut

has body => (is => 'rw');
sub content { shift->body(@_) }
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 cookies

    $res->cookies->{name} = 123;
    $res->cookies->{name} = {value => '123'};

Returns a hash reference containing cookies to be set in the
response. The keys of the hash are the cookies' names, and their
corresponding values are a plain string (for C<value> with everything
else defaults) or a hash reference that can contain keys such as
C<value>, C<domain>, C<expires>, C<path>, C<httponly>, C<secure>,
C<max-age>.

C<expires> can take a string or an integer (as an epoch time) and
B<does not> convert string formats such as C<+3M>.

    $res->cookies->{name} = {
        value => 'test',
        path  => "/",
        domain => '.example.com',
        expires => time + 24 * 60 * 60,
    };

=cut

has cookies => (is => 'rw', isa => 'HashRef', default => sub {+{}});
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 content_length

  $res->content_length(123);

A decimal number indicating the size in bytes of the message content.
Shortcut for the equivalent get/set method in C<< $res->headers >>.

=cut

sub content_length {shift->headers->content_length(@_)}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 content_type

  $res->content_type('text/plain');

The Content-Type header field indicates the media type of the message content.
Shortcut for the equivalent get/set method in C<< $res->headers >>.

=cut

sub content_type {shift->headers->content_type(@_)}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 content_encoding

  $res->content_encoding('gzip');

Shortcut for the equivalent get/set method in C<< $res->headers >>.

=cut

sub content_encoding {shift->headers->content_encoding(@_)}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 location

Gets and sets C<Location> header.

Note that this method doesn't normalize the given URI string in the
setter.

=cut

sub location {shift->headers->header('Location' => @_)}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 redirect

  $res->redirect($url);
  $res->redirect($url, 301);

Sets redirect URL with an optional status code, which defaults to 302.

Note that this method doesn't normalize the given URI string. Users of
this module have to be responsible about properly encoding URI paths
and parameters.

=cut

sub redirect {

    my $self = shift;

    if (@_) {
        my $url = shift;
        my $status = shift || 302;
        $self->location($url);
        $self->status($status);
    }

    return $self->location;
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 finalize

    $res = $res->finalize;
    # [$code, \@headers, $body]
    ($code, $headers, $body) = @$res;

Returns the status code, headers, and body of this response as a PSGI response array reference.

=cut

sub finalize {

    my $self = shift;
    
    $self->status || $self->status(200);

    my $headers = $self->headers;

    my @headers;

    $headers->scan(sub{
    my ($k, $v) = @_;
        $v =~ s/\015\012[\040|\011]+/chr(32)/ge; # replace LWS with a single SP
        $v =~ s/\015|\012//g; # remove CR and LF since the char is invalid here
        push @headers, $k, $v;
    });

    $self->build_cookies(\@headers);

    return [$self->status, \@headers, $self->build_body];
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 to_app

  $res_app = $res->to_app;

A helper shortcut for C<< sub { $res->finalize } >>.

=cut

sub to_app {sub {shift->finalize}}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 headers_as_string

    $headers = $res->headers_as_string($eol)

Return the header fields as a formatted MIME header.

The optional $eol parameter specifies the line ending sequence to
use.  The default is "\n".  Embedded "\n" characters in header field
values will be substituted with this line ending sequence.

=cut

sub headers_as_string {
    
    my ($self, $eol) = @_;

    $eol = "\n" unless defined $eol;
    
    my $res = $self->finalize;
    my ($code, $headers, $body) = @$res;

    #$self->headers->as_string;

    my @result = ();
    
    for (my $i = 0; $i < @$headers; $i = $i+2) {
        my $k = $headers->[$i];
        my $v = $headers->[$i+1];
        if (index($v, "\n") >= 0) {
            $v = $self->process_newline($v, $eol);
        }
        push @result, $k . ': ' . $v;
    }

    return join($eol, @result, '');
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub process_newline {
    local $_ = shift;
    my $eol = shift;
    # must handle header values with embedded newlines with care
    s/\s+$//;        # trailing newlines and space must go
    s/\n(\x0d?\n)+/\n/g;     # no empty lines
    s/\n([^\040\t])/\n $1/g; # intial space for continuation
    s/\n/$eol/g;    # substitute with requested line ending
    $_;
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 as_string

    $message = $res->as_string($eol);

Returns the message formatted as a single string.

The optional $eol parameter specifies the line ending sequence to use.
The default is "\n".  If no $eol is given then as_string will ensure
that the returned string is newline terminated (even when the message
content is not).  No extra newline is appended if an explicit $eol is
passed.

=cut


sub as_string {

    my($self, $eol) = @_;

    $eol = "\n" unless defined $eol;

    # The calculation of content might update the headers
    # so we need to do that first.
    my $content = $self->content;
    
    #push @header, "Server: " . server_software() if $nph;
    #push @header, "Status: $status"              if $status;
    #push @header, "Window-Target: $target"       if $target;
    #sub server_software { $ENV{'SERVER_SOFTWARE'} || 'cmdline' }
    
    my $protocol = ($ENV{SERVER_PROTOCOL} || 'HTTP/1.1') . " " .$self->code . " " . $self->http_codes->{$self->code} . $eol;

    return join("",
                        #$protocol,
                        $self->headers_as_string($eol),
                        $eol,
                        $content,
                        (@_ == 1 && length($content) && $content !~ /\n\z/) ? "\n" : "",
                );
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 render

    $res->render;

Prints the message formatted as a single string to the standard output.

=cut

sub render {
    my ($self) = @_;
    print $self->as_string();
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub send_file {
    
    my ($self, $file, $options) = @_;
    
    load Nile::HTTP::SendFile;
    
    my $sender = Nile::HTTP::SendFile->new;

    $sender->send_file($self, $file, $options);


}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
has encoded => (is => 'rw', isa => 'Bool', default => 0);
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub build_body {

    my $self = shift;

    my $body = $self->body;

    $body = [] unless defined $body;
    
    if (!$self->encoded) {
        $self->encoded(1);
        $body = Encode::encode($self->app->charset, $body);
    }

    if (!ref $body or Scalar::Util::blessed($body) && overload::Method($body, q("")) && !$body->can('getline')) {
        return [$body];
    } else {
        return $body;
    }
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub build_cookies {
    my($self, $headers) = @_;
    while (my($name, $val) = each %{$self->cookies}) {
        my $cookie = $self->build_cookie($name, $val);
        push @$headers, 'Set-Cookie' => $cookie;
    }
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub build_cookie {

    my($self, $name, $val) = @_;

    return '' unless defined $val;

    $val = {value => $val} unless ref $val eq 'HASH';

    my @cookie = (URI::Escape::uri_escape($name) . "=" . URI::Escape::uri_escape($val->{value}));

    push @cookie, "domain=" . $val->{domain}   if $val->{domain};
    push @cookie, "path=" . $val->{path}       if $val->{path};
    push @cookie, "expires=" . $self->cookie_date($val->{expires}) if $val->{expires};
    push @cookie, "max-age=" . $val->{"max-age"} if $val->{"max-age"};
    push @cookie, "secure"                     if $val->{secure};
    push @cookie, "HttpOnly"                   if $val->{httponly};

    return join "; ", @cookie;
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub file_response {

    my ($self, $file, $mime, $status) = @_;
    
    $mime ||= $self->app->mime->for_file($file) || "application/x-download",

    $self->status($status) if ($status);
    
    my ($size, $last_modified) = (stat $file)[7,9];

    $last_modified = $self->http_date($last_modified);

    #my $ifmod = $ENV{HTTP_IF_MODIFIED_SINCE};

    open (my $fh, '<', $file);
    binmode $fh;

    $self->content($fh);

    $self->header('Last-Modified' => $last_modified);
    $self->header('Content-Type' => $mime);
    $self->header('Content-Length' => $size);

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
my @MON  = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
my @WDAY = qw(Sun Mon Tue Wed Thu Fri Sat);

=head2 cookie_date

    say $res->cookie_date( time + 24 * 60 * 60);
    #Fri, 25-Jul-2014 20:46:53 GMT

Returns cookie formated date.

=cut

sub cookie_date {
    my ($self, $expires) = @_;
    if ($expires =~ /^\d+$/) {
        return $self->make_date($expires, "cookie");
    }
    return $expires;
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 http_date

    say $res->http_date(time);
    #Thu, 24 Jul 2014 20:46:53 GMT

Returns http formated date.

=cut

sub http_date {
    my ($self, $time) = @_;
    return $self->make_date($time, "http");
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub make_date {

    my ($self, $time, $format) = @_;
    
    # format: cookie = "-", http = " "
    my $sp = $format eq "cookie" ? "-" : " ";

    my ($sec, $min, $hour, $mday, $mon, $year, $wday) = gmtime($time);
    $year += 1900;

    return sprintf("%s, %02d$sp%s$sp%s %02d:%02d:%02d GMT",
                   $WDAY[$wday], $mday, $MON[$mon], $year, $hour, $min, $sec);
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
has 'http_codes' => (
                        is => 'rw',
                        isa => 'HashRef',
                        default =>  sub { +{
                        # informational
                        # 100 => 'Continue', # only on HTTP 1.1
                        # 101 => 'Switching Protocols', # only on HTTP 1.1

                        # processed codes
                        200 => 'OK',
                        201 => 'Created',
                        202 => 'Accepted',

                        # 203 => 'Non-Authoritative Information', # only on HTTP 1.1
                        204 => 'No Content',
                        205 => 'Reset Content',
                        206 => 'Partial Content',

                        # redirections
                        301 => 'Moved Permanently',
                        302 => 'Found',

                        # 303 => '303 See Other', # only on HTTP 1.1
                        304 => 'Not Modified',

                        # 305 => '305 Use Proxy', # only on HTTP 1.1
                        306 => 'Switch Proxy',

                        # 307 => '307 Temporary Redirect', # on HTTP 1.1

                        # problems with request
                        400 => 'Bad Request',
                        401 => 'Unauthorized',
                        402 => 'Payment Required',
                        403 => 'Forbidden',
                        404 => 'Not Found',
                        405 => 'Method Not Allowed',
                        406 => 'Not Acceptable',
                        407 => 'Proxy Authentication Required',
                        408 => 'Request Timeout',
                        409 => 'Conflict',
                        410 => 'Gone',
                        411 => 'Length Required',
                        412 => 'Precondition Failed',
                        413 => 'Request Entity Too Large',
                        414 => 'Request-URI Too Long',
                        415 => 'Unsupported Media Type',
                        416 => 'Requested Range Not Satisfiable',
                        417 => 'Expectation Failed',

                        # problems with server
                        500 => 'Internal Server Error',
                        501 => 'Not Implemented',
                        502 => 'Bad Gateway',
                        503 => 'Service Unavailable',
                        504 => 'Gateway Timeout',
                        505 => 'HTTP Version Not Supported',
    }});
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 status_message($code)

The status_message() function will translate status codes to human
readable strings. If the $code is unknown, then C<undef> is returned.

=cut

sub status_message {my $self = shift; $self->http_codes->{$_[0]};}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 is_info( $code )

Return TRUE if C<$code> is an I<Informational> status code (1xx).  This
class of status code indicates a provisional response which can't have
any content.

=cut

sub is_info {shift; $_[0] >= 100 && $_[0] < 200; }
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=item is_success( $code )

Return TRUE if C<$code> is a I<Successful> status code (2xx).

=cut

sub is_success {shift; $_[0] >= 200 && $_[0] < 300; }
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=item is_redirect( $code )

Return TRUE if C<$code> is a I<Redirection> status code (3xx). This class of
status code indicates that further action needs to be taken by the
user agent in order to fulfill the request.

=cut

sub is_redirect {shift; $_[0] >= 300 && $_[0] < 400; }
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=item is_error( $code )

Return TRUE if C<$code> is an I<Error> status code (4xx or 5xx).  The function
returns TRUE for both client and server error status codes.

=cut

sub is_error {shift; $_[0] >= 400 && $_[0] < 600; }
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=item is_client_error( $code )

Return TRUE if C<$code> is a I<Client Error> status code (4xx). This class
of status code is intended for cases in which the client seems to have
erred.

=cut

sub is_client_error {shift; $_[0] >= 400 && $_[0] < 500; }
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=item is_server_error( $code )

Return TRUE if C<$code> is a I<Server Error> status code (5xx). This class
of status codes is intended for cases in which the server is aware
that it has erred or is incapable of performing the request.

=cut

sub is_server_error {shift; $_[0] >= 500 && $_[0] < 600; }
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub http_code_response {
    
    my ($self, $code) = @_;

    $self->code($code);
    
    $self->header('Content-Type' => 'text/plain');
    
    my $body = $self->status_message($code);

    $self->content($body);
    
    use bytes; # turn off character semantics
    $self->header('Content-Length' => length($body));

    return $self->finalize;
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub response_403 {
    # 403 => 'Forbidden',
    return shift->http_code_response(403);
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub response_400 {
    # 400 => 'Bad Request',
    return shift->http_code_response(400);
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub response_404 {
    # 404 => 'Not Found',
    return shift->http_code_response(404);
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=pod

=head1 Bugs

This project is available on github at L<https://github.com/mewsoft/Nile>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Nile>.

=head1 SOURCE

Source repository is at L<https://github.com/mewsoft/Nile>.

=head1 ACKNOWLEDGMENT

This module is based on L<Plack::Response> L<HTTP::Message>

=head1 SEE ALSO

See L<Nile> for details about the complete framework.

=head1 AUTHOR

Ahmed Amin Elsheshtawy,  احمد امين الششتاوى <mewsoft@cpan.org>
Website: http://www.mewsoft.com

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014-2015 by Dr. Ahmed Amin Elsheshtawy احمد امين الششتاوى mewsoft@cpan.org, support@mewsoft.com,
L<https://github.com/mewsoft/Nile>, L<http://www.mewsoft.com>

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
