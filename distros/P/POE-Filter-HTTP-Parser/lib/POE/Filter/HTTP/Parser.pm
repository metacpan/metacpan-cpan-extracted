package POE::Filter::HTTP::Parser;
$POE::Filter::HTTP::Parser::VERSION = '1.08';
# ABSTRACT: A HTTP POE filter for HTTP clients or servers

use strict;
use warnings;
use HTTP::Parser;
use HTTP::Status qw(status_message RC_BAD_REQUEST RC_OK RC_LENGTH_REQUIRED);
use base 'POE::Filter';
use Encode qw[encode_utf8];

my %type_map = (
   'server', 'request',
   'client', 'response',
);

sub new {
  my $class = shift;
  my %opts = @_;
  $opts{lc $_} = delete $opts{$_} for keys %opts;
  if ( $opts{type} and defined $type_map{ $opts{type} } ) {
	$opts{type} = $type_map{ $opts{type} };
  }
  $opts{type} = 'response' unless $opts{type} and $opts{type} =~ /^(request|response)$/;
  my $self = \%opts;
  $self->{BUFFER} = [];
  $self->{parser} = HTTP::Parser->new( $self->{type} => 1 );
  bless $self, $class;
}

sub get_one_start {
  my ($self, $raw) = @_;
  push @{ $self->{BUFFER} }, $_ for @$raw;
}

sub get_one {
  my $self = shift;
  my $events = [];

  my $string = shift @{ $self->{BUFFER} };
  return [] unless $string;

  my $status;
  eval { $status = $self->{parser}->add( $string ); };

  if ( $@ and $self->{type} eq 'request' ) {
    # Build a HTTP::Response error message
    return [ $self->_build_error( RC_BAD_REQUEST, "<p><pre>$@</pre></p>" ) ];
  }

  if ( $@ and $self->{debug} ) {
     warn "$@\n";
     warn "Input was: '$string'\n";
     return $events;
  }

  if ( defined $status and $status == 0 ) {
     push @$events, $self->{parser}->object();
     my $data = $self->{parser}->data();
     unshift @{ $self->{BUFFER} }, $data if $data;
     $self->{parser} = HTTP::Parser->new( $self->{type} => 1 );
  }

  return $events;
}

sub _old_put {
  my ($self, $chunks) = @_;
  [ @$chunks ];
}

sub put {
  my $self = shift;
  my $return;
  if ( $self->{type} eq 'request' ) {
     $return = $self->_put_response( @_ );
  }
  else {
     $return = $self->_put_request( @_ );
  }
  $return;
}

sub _put_response {
  my ($self, $responses) = @_;
  my @raw;

  # HTTP::Response's as_string method returns the header lines
  # terminated by "\n", which does not do the right thing if we want
  # to send it to a client.  Here I've stolen HTTP::Response's
  # as_string's code and altered it to use network newlines so picky
  # browsers like lynx get what they expect.

  # And this is shamelessly stolen from POE::Filter::HTTPD

  foreach (@$responses) {
    my $code           = $_->code;
    my $status_message = status_message($code) || "Unknown Error";
    my $message        = $_->message  || "";
    my $proto          = $_->protocol || 'HTTP/1.0';

    my $status_line = "$proto $code";
    $status_line   .= " ($status_message)"  if $status_message ne $message;
    $status_line   .= " $message" if length($message);

    # Use network newlines, and be sure not to mangle newlines in the
    # response's content.

    my @headers;
    push @headers, $status_line;
    push @headers, $_->headers_as_string("\x0D\x0A");

    push @raw, encode_utf8(join("\x0D\x0A", @headers, "")) . $_->content;
  }

  \@raw;
}

sub _put_request {
  my ($self, $requests) = @_;
  my @raw;

  foreach (@$requests) {
    my $req_line = $_->method || "-";
    my $uri = $_->uri;
    $uri = (defined $uri) ? $uri->as_string : "-";
    $req_line .= " $uri";
    my $proto = $_->protocol;
    $req_line .= " $proto" if $proto;

    # Use network newlines, and be sure not to mangle newlines in the
    # response's content.

    my @headers;
    push @headers, $req_line;
    push @headers, $_->headers_as_string("\x0D\x0A");

    push @raw, encode_utf8(join("\x0D\x0A", @headers, "")) . $_->content;
  }

  \@raw;
}

sub clone {
  my $self = shift;
  my $nself = { };
  $nself->{$_} = $self->{$_} for keys %{ $self };
  $nself->{BUFFER} = [ ];
  $nself->{parser} = HTTP::Parser->new( $nself->{type} => 1 );
  return bless $nself, ref $self;
}

sub get_pending {
  my $self = shift;
  my $data = $self->{parser}->data();
  return unless $data or scalar @{ $self->{BUFFER} };
  return [ ( $data ? $data : () ), @{ $self->{BUFFER} } ];
}

sub _build_basic_response {
  my ($self, $content, $content_type, $status) = @_;

  # Need to check lengths in octets, not characters.
  BEGIN { eval { require bytes } and bytes->import; }

  $content_type ||= 'text/html';
  $status       ||= RC_OK;

  my $response = HTTP::Response->new($status);

  $response->push_header( 'Content-Type', $content_type );
  $response->push_header( 'Content-Length', length($content) );
  $response->content($content);

  return $response;
}

sub _build_error {
  my($self, $status, $details) = @_;

  $status  ||= RC_BAD_REQUEST;
  $details ||= '';
  my $message = status_message($status) || "Unknown Error";

  return $self->_build_basic_response(
    ( "<html>" .
      "<head>" .
      "<title>Error $status: $message</title>" .
      "</head>" .
      "<body>" .
      "<h1>Error $status: $message</h1>" .
      "<p>$details</p>" .
      "</body>" .
      "</html>"
    ),
    "text/html",
    $status
  );
}

'I filter therefore I am';

__END__

=pod

=encoding UTF-8

=head1 NAME

POE::Filter::HTTP::Parser - A HTTP POE filter for HTTP clients or servers

=head1 VERSION

version 1.08

=head1 SYNOPSIS

    use POE::Filter::HTTP::Parser;

    # For HTTP Servers

    my $request_filter = POE::Filter::HTTP::Parser->new( type => 'server' );
    my $arrayref_of_request_objects = $filter->get( [ $stream ] );

    my $arrayref_of_HTTP_stream = $filter->put( $arrayref_of_response_objects );

    # For HTTP clients

    my $response_filter = POE::Filter::HTTP::Parser->new( type => 'client' );
    my $arrayref_of_HTTP_stream = $filter->put( $arrayref_of_request_objects );

    my $arrayref_of_response_objects = $filter->get( [ $stream ] );

=head1 DESCRIPTION

POE::Filter::HTTP::Parser is a L<POE::Filter> for HTTP which is based on L<HTTP::Parser>.

It can be used to easily create L<POE> based HTTP servers or clients.

With the C<type> set to C<client>, which is the default behaviour, C<get> will parse
L<HTTP::Response> objects from HTTP streams and C<put> will accept L<HTTP::Request>
objects and convert them to HTTP streams.

With the C<type> set to C<server>, the reverse will happen. C<get> will parse L<HTTP::Request>
objects from HTTP streams and C<put> will accept L<HTTP::Response> objects and convert them to
HTTP streams. Like L<POE::Filter::HTTPD> if there is an error parsing the HTTP request, this
filter will generate a L<HTTP::Response> object instead, to encapsulate the error message,
suitable for simply sending back to the requesting client.

=head1 CONSTRUCTOR

=over

=item C<new>

Creates a new POE::Filter::HTTP::Parser object. Takes one optional argument, C<type> which
determines whether the filter will act in C<client> or C<server> mode. C<client> is the default
if C<type> is not specified.

  'type', set to either 'client' or 'server', default is 'client';

=back

=head1 METHODS

=over

=item C<get>

=item C<get_one_start>

=item C<get_one>

Takes an arrayref which contains lines of text. Returns an arrayref of either
L<HTTP::Request> or L<HTTP::Response> objects depending on the C<type> that has been
specified.

=item C<get_pending>

Returns any data remaining in a filter's input buffer. The filter's input buffer is not cleared, however.
Returns an array reference if there's any data, or undef if the filter was empty.

=item C<put>

Takes an arrayref of either L<HTTP::Response> objects or L<HTTP::Request> objects depending on whether
C<type> is set to C<server> or C<client>, respectively.

If C<type> is C<client>, then this accepts L<HTTP::Request> objects.
If C<type> is C<server>, then this accepts L<HTTP::Response> objects.

This does make sense if you think about it.

The given objects are returned to their stream form.

=item C<clone>

Makes a copy of the filter, and clears the copy's buffer.

=back

=head1 CREDITS

The C<put> method for HTTP responses was borrowed from L<POE::Filter::HTTPD>,
along with the code to generate L<HTTP::Response> on a parse error,
by Artur Bergman and Rocco Caputo.

=head1 SEE ALSO

L<POE::Filter>

L<HTTP::Parser>

L<POE::Filter::HTTPD>

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Chris Williams, Artur Bergman and Rocco Caputo.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
