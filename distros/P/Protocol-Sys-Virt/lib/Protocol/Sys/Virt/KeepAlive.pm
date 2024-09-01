
use v5.14;
use warnings;

package Protocol::Sys::Virt::KeepAlive;

use Carp qw(croak);

use Protocol::Sys::Virt::KeepAlive::XDR;
use Protocol::Sys::Virt::Transport::XDR;
my $msgs = 'Protocol::Sys::Virt::KeepAlive::XDR';
my $type = 'Protocol::Sys::Virt::Transport::XDR';

sub new {
    my ($class, %args) = @_;
    return bless {
        unacked     => 0,
        max_unacked => 10,
        on_ack      => sub { },
        on_fail     => sub { },
        sender      => sub { croak 'Not registered with a transport'; },
        %args
    }, $class;
}

sub _unexpected_msg {
    croak 'Unexpeced message';
}

sub register {
    my ($self, $transport) = @_;

    $self->{sender} = $transport->register(
        $msgs->PROGRAM,
        $msgs->PROTOCOL_VERSION,
        {
            on_reply   => sub {
                $self->{on_ack}->($self, $transport);
                $self->{unacked} = 0;
            },
            on_call    => \&_unexpected_msg,
            on_message => \&_unexpected_msg,
            on_stream  => \&_unexpected_msg
        });
}

sub ping {
    my ($self) = @_;
    $self->{unacked}++;
    if ($self->{unacked} > $self->{max_unacked}) {
        $self->{on_fail}->($self);
    }
    $self->{sender}->($msgs->PROC_PING, $type->CALL, data => '');
}

1;

__END__

=head1 NAME

Protocol::Sys::Virt::KeepAlive - Check transport link availability

=head1 SYNOPSIS

  use Protocol::Sys::Virt::Transport;
  use Protocol::Sys::Virt::KeepAlive;

  my $transport = Protocol::Sys::Virt::Transport->new(
     role => 'client',
     on_send => sub { ... }
  );

  my $keepalive = Protocol::Sys::Virt::KeepAlive->new(
     max_unacked => 20,
     on_ack  => sub { say 'We are still alive!'; },
     on_fail => sub { die 'Connection timed out'; },
  );
  $keepalive->register( $transport );

  $keepalive->ping;
  $keepalive->ping;

=head1 DESCRIPTION

This module defines the "Keep Alive" program of the LibVirt protocol.  Its
use as part of the connection to the libvirt daemon(s), is negotiated over
the (primary, remote) program protocol.  Support for this "program" can be
queried using the C<REMOTE_PROC_CONNECT_SUPPORTS_FEATURE> call.

Instances keep a count of unacknowledged C<PING> messages; when the number
exceeds a certain threshold, the C<on_fail> callback is called.

Note that users actively need to call the C<ping> method; there's no timer
functionality in this module which automatically calls it.

=head1 CONSTRUCTOR

=head2 new

Accepts the following options:

=over 8

=item * max_unacked

The threshold number of unacknowledged C<PING> messages (i.e., without
a C<PONG> response) before calling the C<on_fail> callback.

=item * on_ack

Callback called when a C<PONG> message is received.

=item * on_fail

Callback called when the number of unacknowledged C<PING> messages exceeds
the C<max_unacked> threshold.

=back

=head1 METHODS

=head2 ping

  $keepalive->ping;

Sends a C<PROC_PING> message over the C<$transport> on which it is registered.
If the number of unacknowledged pings grows above the threshold, triggers the
C<on_fail> event.

=head2 register

  $keepalive->register( $transport );

Registers the 'keep alive program' with C<$transport>.

=head1 LICENSE AND COPYRIGHT

See the LICENSE file in this distribution.

