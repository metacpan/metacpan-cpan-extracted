# -*- Perl -*-
#
# a Gemini protocol server, mostly to test the Net::Gemini client with
#
#   "They are great warriors: their greatness is like the empty desert
#   wastes. They are both the lords of the River, the River of the
#   Ordeal which clears the just man. They weigh upon the evil man like
#   a neck-stock. In Kisiga, their very anciently founded city, the
#   trustworthy does not get caught, but the evil cannot pass through."

package Net::Gemini::Server;
our $VERSION = '0.11';
use strict;
use warnings;
# the below code mostly cargo culted from example/ssl_server.pl
use IO::Socket::IP;
use IO::Socket::SSL;

DESTROY { undef $_[0]{_context}; undef $_[0]{_socket} }

sub new {
    my ( $class, %param ) = @_;
    $param{listen}{LocalPort} = 1965
      unless defined $param{listen}{LocalPort};
    my %obj;
    $obj{_socket} = IO::Socket::IP->new(
        Listen => 5,
        Reuse  => 1,
        %{ $param{listen} },
    ) or die "server failed: $!";
    # server default is not to perform any verification
    $obj{_context} =
      IO::Socket::SSL::SSL_Context->new( %{ $param{context} },
        SSL_server => 1, )
      or die "context failed: $SSL_ERROR";
    $obj{_port} = $obj{_socket}->sockport;
    bless \%obj, $class;
}

sub context { $_[0]{_context} }
sub port    { $_[0]{_port} }
sub socket  { $_[0]{_socket} }

# this, as noted elsewhere, is mostly for testing the client
sub withforks {
    my ( $self, $callback, %param ) = @_;
    my $server = $self->{_socket};
    while (1) {
        my $client = $server->accept or do {
            warn "accept failed: $!\n";
            next;
        };
        if ( $param{close_on_accept} ) {
            close $client;
            next;
        }
        my $parent = fork;
        die "fork failed: $!" unless defined $parent;
        if ($parent) {
            close $client;
            next;
        }
        unless ( $param{no_ssl} ) {
            unless (
                IO::Socket::SSL->start_SSL(
                    $client,
                    SSL_server    => 1,
                    SSL_reuse_ctx => $self->{_context}
                )
            ) {
                warn "ssl handshake failed: $SSL_ERROR\n";
                close $client;
                exit;
            }
        }
        if ( $param{close_before_read} ) {
            close $client;
            exit;
        }
        binmode $client, ':raw';
        # NOTE this assumes the client isn't sending bytes one by one slow
        my $n = sysread( $client, my $buf, 1024 );
        # does not suss out any new client edge cases
        #if ( $param{close_after_read} ) {
        #    close $client;
        #    exit;
        #}
        eval {
            # NOTE the buffer is raw bytes and may need a decode
            $callback->( $client, $n, $buf );
            1;
        } or do {
            # KLUGE random stderr from a fork can confuse TAP and get
            # the tests out of sequence?
            #warn "callback error: $@";
            close $client;
        };
        exit;
    }
}

1;
__END__

=head1 NAME

Net::Gemini::Server - test gemini server

=head1 SYNOPSIS

  use Net::Gemini::Server;
  my $server = Net::Gemini::Server->new(
    listen => {
      LocalAddr => '127.0.0.1',
      LocalPort => 0,
    },
    context => {
      SSL_cert_file => ...,
      SSL_key_file  => ...,
    }
  );
  $server->withforks(
    sub {
        my ( $client, $size, $request) = @_;
        ...
        close $client;
    }
  );

=head1 DESCRIPTION

This module provides a simple test server for L<Net::Gemini>; see the
test code for that module.

=head1 METHODS

=over 4

=item B<new> I<param>

Constructor. The I<param> should include I<listen> and I<context> key
values to configure the listen object and SSL context object.

=item B<context>
=item B<port>
=item B<socket>

Accessors; return the context object (see L<IO::Socket::SSL>), listen
port, and socket of the server.

=item B<withforks> I<callback>

Accepts connections and forks child processes to handle the client
request with the given I<callback>. The I<callback> is passed the client
socket, size of the request, and the request string.

=back

=head1 BUGS

None known. But it is a rather incomplete module; that may be
considered a bug?

=head1 SEE ALSO

L<gemini://gemini.circumlunar.space/docs/specification.gmi> (v0.16.1)

RFC 3986

=head1 COPYRIGHT AND LICENSE

Copyright 2022 Jeremy Mates

This program is distributed under the (Revised) BSD License:
L<https://opensource.org/licenses/BSD-3-Clause>

=cut
