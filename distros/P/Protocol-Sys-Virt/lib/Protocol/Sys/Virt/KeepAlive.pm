####################################################################
#
#     This file was generated using XDR::Parse version v1.0.1,
#        XDR::Gen version 1.0.0 and LibVirt version v12.0.0
#
#      Don't edit this file, use the source template instead
#
#                 ANY CHANGES HERE WILL BE LOST !
#
####################################################################

use v5.14;
use warnings;

package Protocol::Sys::Virt::KeepAlive v12.0.6;

use Carp qw(croak);
use Log::Any qw($log);

use Protocol::Sys::Virt::KeepAlive::XDR;
use Protocol::Sys::Virt::Transport::XDR;
my $msgs = 'Protocol::Sys::Virt::KeepAlive::XDR';
my $type = 'Protocol::Sys::Virt::Transport::XDR';

sub new {
    my ($class, %args) = @_;
    return bless {
        inactive     => 0,
        max_inactive => 10,
        on_ack       => sub { },
        on_fail      => sub { },
        on_ping      => sub { },
        sender       => sub { croak 'Not registered with a transport'; },
        %args
    }, $class;
}

sub _unexpected_msg {
    croak 'Unexpected message';
}

sub register {
    my ($self, $transport) = @_;

    $self->{sender} = $transport->register(
        $msgs->PROGRAM,
        $msgs->PROTOCOL_VERSION,
        {
            on_reply   => \&_unexpected_msg,
            on_call    => \&_unexpected_msg,
            on_message => sub {
                my %args = @_;

                if ($args{header}->{proc} == $msgs->PROC_PONG) {
                    $self->{inactive} = 0; # our PING; keep pinging
                    return $self->{on_ack}->($self, $transport);
                }

                $self->mark_active;
                if ($args{header}->{proc} == $msgs->PROC_PING) {
                    return $self->{on_ping}->($self, $transport);
                }
                return;
            },
            on_stream  => \&_unexpected_msg
        });
}


sub mark_active {
    $_[0]->{inactive} = -1; # external activity
}

sub ping {
    my ($self) = @_;

    $self->{inactive}++;
    if ($self->{inactive} > $self->{max_inactive}) {
        return $self->{on_fail}->($self);
    }
    if ($self->{inactive}) {
        $log->trace("Inactivity timer: $self->{inactive}");
        return $self->{sender}->($msgs->PROC_PING, $type->MESSAGE, data => '');
    }
    else {
        $log->trace("Activity found; no need to PING");
        return;
    }
}

sub pong {
    my ($self) = @_;
    $self->{sender}->($msgs->PROC_PONG, $type->MESSAGE, data => '');
}

1;

__END__

=head1 NAME

Protocol::Sys::Virt::KeepAlive - Check transport link availability

=head1 VERSION

v12.0.6

Based on LibVirt tag v12.0.0

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
     on_ping => sub {
        my ($ka, $trnsp) = @_;
        $ka->pong;
     },
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

=item * max_inactive

The threshold number of C<ping> calls without activity; when the number
of calls exceeds this value, the C<on_fail> callback will be invoked.

Note that activity can be signalled through C<mark_active> as well as
receiving C<PING> or C<PONG> messages.

=item * on_ack

Callback called when a C<PONG> message is received.

=item * on_fail

Callback called when the number of unacknowledged C<PING> messages exceeds
the C<max_unacked> threshold.

=item * on_ping

  $on_ping->( $keepalive, $transport );

Callback called when a PING message is received. Typically should call
C<< $keepalive->pong >> (and deal with its return value).

=back

=head1 METHODS

=head2 mark_active

  $keepalive->mark_active;

Makes the keep alive tracker aware of connection activity other than
the PING and PONG messages it registered itself for with the C<$transport>.

This function may be called on incoming data but should not be called
when data is transmitted.  When this function has been called between two
calls to C<< $keepalive->ping >>, it will not send a C< PING > message,
taking the current activity as sufficient proof of an open connection.

=head2 ping

  $keepalive->ping;

Sends a C<PROC_PING> message over the C<$transport> on which it is registered.
If the number of unacknowledged pings grows above the threshold, triggers the
C<on_fail> event, returning the callbacks results.

Otherwise returns either nothing at all (in case no PING message needed to be
sent), or the return value of the sender routine registered with the transport
when a PING message was sent.

=head2 pong

  $keepalive->pong;

Sends a C<PROC_PONG> message over the C<$transport> on which it is registered.

Returns the return value of the sender routine registered with the transport.

=head2 register

  $keepalive->register( $transport );

Registers the 'keep alive program' with C<$transport>.

=head1 LICENSE AND COPYRIGHT

See the LICENSE file in this distribution.


