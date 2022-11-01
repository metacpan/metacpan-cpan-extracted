# -*- Perl -*-
#
# a Gemini protocol client
#
#   "The conjunction of Jupiter with one of the stars of Gemini, which
#   'we ourselves have seen' (1.6.343b30) has been dated in recent years
#   to December 337 BC."
#    -- Malcolm Wilson. Structure and Method in Aristotle's Meteorologica

package Net::Gemini;
our $VERSION = '0.03';
use 5.10.0;
use Encode ();
use IO::Socket::SSL;
use Net::Gemini::URI;

sub code    { $_[0]{_code} }
sub content { $_[0]{_buf} }
sub error   { $_[0]{_error} }
sub host    { $_[0]{_host} }
sub meta    { $_[0]{_meta} }
sub port    { $_[0]{_port} }
sub socket  { $_[0]{_socket} }
sub status  { $_[0]{_status} }
sub uri     { $_[0]{_uri} }

sub get {
    my ( $class, $source, %param ) = @_;
    my %obj;
    unless ( defined $source ) {
        @obj{qw(_code _error)} = ( 0, "source is not defined" );
        goto BLESSING;
    }
    my $type = ref $source;
    if ( $type eq "" ) {
        my $err;
        ( $obj{_uri}, $err ) = Net::Gemini::URI->new($source);
        unless ( defined $obj{_uri} ) {
            @obj{qw(_code _error)} = ( 0, "could not parse '$source': $err" );
            goto BLESSING;
        }
        @obj{qw/_host _port/} = $obj{_uri}->hostport;
    } elsif ( $type eq 'ARRAY' ) {
        # one use of this is if there is already a Net::Gemini::URI
        # object, another is to use a different host and port for the
        # connection than otherwise would be used. SNI will by default
        # use PeerHost which comes from the _host
        @obj{qw/_uri _host _port/} = @$source[ 0 .. 2 ];
    } else {
        @obj{qw(_code _error)} = ( 0, "unknown type '$type'" );
        goto BLESSING;
    }
    my $yuri;
    eval {
        $yuri = Encode::encode( 'UTF-8', $obj{_uri}->canonical, Encode::FB_CROAK );
        1;
    } or do {
        @obj{qw(_code _error)} = ( 0, "failed to encode URI: $@" );
        goto BLESSING;
    };
    if ( length $yuri > 1024 ) {
        @obj{qw(_code _error)} = ( 0, "URI is too long" );
        goto BLESSING;
    }

    eval {
        # NOTE the default here is to verify the peer, which is not the
        # TOFU advised by the gemini specification.
        $obj{_socket} = IO::Socket::SSL->new(
            ( exists $param{ssl} ? %{ $param{ssl} } : () ),
            PeerHost => $obj{_host},
            PeerPort => $obj{_port},
        ) or die $!;
        1;
    } or do {
        @obj{qw(_code _error)} = ( 0, "IO::Socket::SSL failed: $@" );
        goto BLESSING;
    };

    binmode $obj{_socket}, ':raw';

    my $n = syswrite $obj{_socket}, "$yuri\r\n";
    unless ( defined $n ) {
        @obj{qw(_code _error)} = ( 0, "send URI failed: $!" );
        goto BLESSING;
    }

    # get the STATUS SPACE header response (and, probably, more)
    $obj{_buf} = '';
    while (1) {
        my $n = sysread $obj{_socket}, my $buf, $param{bufsize} || 4096;
        unless ( defined $n ) {
            @obj{qw(_code _error)} = ( 0, "recv response failed: $!" );
            goto BLESSING;
        }
        if ( $n == 0 ) {
            @obj{qw(_code _error)} = ( 0, "recv EOF" );
            goto BLESSING;
        }
        $obj{_buf} .= $buf;
        last if length $obj{_buf} >= 3;
    }
    if ( $obj{_buf} =~ m/^(([1-6])[0-9])[ ]/ ) {
        @obj{qw(_status _code)} = ( $1, $2 );
        substr $obj{_buf}, 0, 3, '';
    } else {
        @obj{qw(_code _error)} =
          ( 0, "invalid response " . sprintf "%vx", substr $obj{_buf}, 0, 3 );
        goto BLESSING;
    }

    # META -- at most 1024 characters, followed by \r\n. the loop is in
    # the event the server is being naughty and trickling bytes in one
    # by one (probably you will want a timeout somewhere, or an async
    # version of this code)
    while (1) {
        if ( $obj{_buf} =~ m/^(.{0,1024}?)\r\n/ ) {
            $obj{_meta} = $1;
            my $len = length $obj{_meta};
            if ( $len == 0 ) {
                # special case mentioned in the specification
                $obj{_meta} = 'text/gemini; charset=utf-8';
            } else {
                eval {
                    $obj{_meta} = Encode::decode( 'UTF-8', $obj{_meta}, Encode::FB_CROAK );
                    1;
                } or do {
                    @obj{qw(_code _error)} = ( 0, "failed to decode meta" );
                    goto BLESSING;
                };
                substr $obj{_buf}, 0, $len + 2, ''; # +2 for the \r\n
            }
            last;
        } else {
            my $len = length $obj{_buf};
            if ( $len > 1024 ) {
                @obj{qw(_code _error)} = ( 0, "meta is too long" );
                goto BLESSING;
            }
            my $n = sysread $obj{_socket}, my $buf, $param{bufsize} || 4096;
            unless ( defined $n ) {
                @obj{qw(_code _error)} = ( 0, "recv response failed: $!" );
                goto BLESSING;
            }
            if ( $n == 0 ) {
                @obj{qw(_code _error)} = ( 0, "recv EOF" );
                goto BLESSING;
            }
            $obj{_buf} .= $buf;
        }
    }

  BLESSING:
    bless( \%obj, $class ), $obj{_code};
}

sub getmore {
    my ( $self, $callback, %param ) = @_;

    my $len = length $self->{_buf};
    $callback->( $len, $self->{_buf} ) or return;
    # _buf is not cleared on the assumption that the object will go out
    # of scope soon enough

    while (1) {
        $len = sysread $self->{_socket}, my $buf, $param{bufsize} || 4096;
        $callback->( $len, $buf ) or return;
    }
}

1;
__END__

=head1 NAME

Net::Gemini - a small gemini client

=head1 SYNOPSIS

  use Net::Gemini;
  my ($gem, $code) = Net::Gemini->get('gemini://example.org/');

  use Syntax::Keyword::Match;
  match($code : ==) {
    case(0) { die "request failed " . $gem->error }
    case(1) { ... $gem->meta as prompt for input ... }
    case(2) { ... $gem->meta and $gem->content and ... }
    case(3) { ... $gem->meta as redirect ... }
    case(4) { ... $gem->meta as temporary failure ... }
    case(5) { ... $gem->meta as permanent failure ... }
    case(6) { ... $gem->meta as client certificate message ... }
  }


=head1 DESCRIPTION

This module implements code that may help implement a gemini client.

=head2 CAVEATS

The default SSL verification scheme is used. So it's not TOFU (Trust on
First Use); that will require customizing L<IO::Socket::SSL>.

=head1 METHODS

=over 4

=item B<get> I<URI> [ parameters ... ]

Tries to obtain the given gemini I<URI>. Returns an object and a result
code. The result code will be C<0> if there was a problem with the
request (e.g. that the URI failed to parse, or the connection failed) or
otherwise a gemini code in the range of C<1> to C<6> inclusive, which
will indicate the next steps any subsequent code probably should take.

For code C<2> responses the response body may be split between
B<content> and whatever remains unread in the socket, and will be
undecoded.

Parameters include:

=over 4

=item B<bufsize> => I<strictly-positive-integer>

Size of buffer to use for requests, 4096 by default. Note that a naughty
server may return data in far smaller increments than this.

=item B<ssl> => { params }

Passes the given parameters to the L<IO::Socket::SSL> constructor. These
could be used to configure e.g. the C<SSL_verify_mode> or to set a
verification callback.

IO::Socket::SSL::set_defaults may also be of use in client code.

=back

=item B<getmore> I<callback> [ bufsize => n ]

A callback interface is provided to consume the response body, if
any. Generally this should only be present for response code C<2>.
The B<meta> line should be consulted for details on the MIME type
and encoding of the bytes; C<$body> in the following code may need
to be decoded.

  my $body = '';
  $gem->getmore(
      sub {
          my ( $status, $buffer ) = @_;
          return 0 if !defined $status or $status == 0;
          $body .= $buffer;
          return 1;
      }
  );

The I<bufsize> parameter is as for B<get>.

=back

=head1 ACCESSORS

=over 4

=item B<code>

Code of the request, C<0> to C<6> inclusive. Pretty important, so is
also returned by B<get>.

=item B<content>

The content, if any. Raw bytes. Only if the B<code> is C<2>.

=item B<error>

The error message, if any.

=item B<host>

Host used for the request.

=item B<meta>

Gemini meta line. Use varies depending on the code.

=item B<port>

Port used for the request.

=item B<socket>

Socket to the server. May not be of much use after B<getmore> is
done with.

=item B<status>

Status of the request, a two digit number. Only set when the code is a
gemini response (that is, not an internal C<0> code).

=item B<uri>

URI used for the request. Probably could be used with any relative URL
returned from the server.

=back

=head1 BUGS

None known. But it is a rather incomplete module; that may be
considered a bug?

=head1 SEE ALSO

L<Net::Gemini::URI>

L<gemini://gemini.circumlunar.space/docs/specification.gmi> (v0.16.1)

RFC 3986

=head1 COPYRIGHT AND LICENSE

Copyright 2022 Jeremy Mates

This program is distributed under the (Revised) BSD License:
L<https://opensource.org/licenses/BSD-3-Clause>

=cut
