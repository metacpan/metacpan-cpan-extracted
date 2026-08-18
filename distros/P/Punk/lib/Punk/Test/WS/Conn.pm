package Punk::Test::WS::Conn;

use 5.010;
use strict;
use warnings;
use Punk::Test::WS ();

our $VERSION = '0.17';

sub new {
    my ($class, %a) = @_;
    return bless {
        sock    => $a{sock},
        timeout => $a{timeout} // 5,
        buf     => '',
        pid     => $a{pid},
    }, $class;
}

sub sock { $_[0]{sock} }

sub read_headers {
    my ($self) = @_;
    my $buf = '';
    eval {
        local $SIG{ALRM} = sub { die "timeout\n" };
        alarm $self->{timeout};
        while (sysread $self->{sock}, my $c, 1) {
            $buf .= $c;
            last if $buf =~ /\r\n\r\n\z/;
        }
        alarm 0;
    };
    return $buf;
}

sub send_frame {
    my ($self, %a) = @_;
    return syswrite $self->{sock}, Punk::Test::WS::encode_client(%a);
}

sub read_frame {
    my ($self) = @_;
    my $f;
    eval {
        local $SIG{ALRM} = sub { die "timeout\n" };
        alarm $self->{timeout};
        while (1) {
            $f = Punk::Test::WS::decode_ref($self->{buf});
            if ($f && ref $f) {
                substr $self->{buf}, 0, $f->{consumed}, '';
                last;
            }
            die "ws protocol error: $f\n" if defined $f && !ref $f;
            my $n = sysread $self->{sock}, my $c, 4096;
            last unless $n;
            $self->{buf} .= $c;
        }
        alarm 0;
    };
    return ref $f ? $f : undef;
}

sub close {
    my ($self) = @_;
    close $self->{sock} if $self->{sock};
    $self->{sock} = undef;
    if ($self->{pid}) {
        waitpid $self->{pid}, 0;
        $self->{pid} = undef;
    }
    return;
}

sub DESTROY { $_[0]->close }

1;

__END__

=head1 NAME

Punk::Test::WS::Conn - the client side of one WebSocket connection

=head1 SYNOPSIS

    my $conn = Punk::Test::WS::Conn->new(sock => $s, timeout => 5);
    my $hdr  = $conn->read_headers;   # the raw HTTP header block
    $conn->send_frame(opcode => 1, payload => 'hi');
    my $f = $conn->read_frame;        # one decoded frame
    $conn->close;

=head1 DESCRIPTION

A connected socket wrapped with a read buffer and a timeout, speaking
the L<Punk::Test::WS> codec from the client's side. L<Punk::Test>
builds one over either of its transports - an in-process socketpair or
a live TCP connection - and the assertion methods drive it. Every read
carries the timeout, so a server that goes quiet fails the test
instead of hanging it.

=head1 METHODS

=head2 new(%args)

C<sock> (the connected socket), C<timeout> (seconds per read, default
5), C<pid> (a child process to reap when the connection closes, for
transports that forked one).

=head2 sock

The underlying socket.

=head2 read_headers

Read until a full HTTP header block (C<\r\n\r\n>) has arrived; returns
it raw - empty on EOF or timeout.

=head2 send_frame(%args)

Encode one client frame (masked, as a client must - the arguments are
L<Punk::Test::WS/encode_client>'s) and write it. Returns what
C<syswrite> returned.

=head2 read_frame

One decoded frame off the wire, buffering as needed; C<undef> on
timeout or EOF. A protocol violation in the stream dies with the
codec's error name.

=head2 close

Close the socket and reap the child, if this connection owns one.
Called on destruction.

=head1 SEE ALSO

L<Punk::Test>, L<Punk::Test::WS>.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
