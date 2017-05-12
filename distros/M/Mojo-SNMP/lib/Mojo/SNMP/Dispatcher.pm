package Mojo::SNMP::Dispatcher;
use Errno;
use Mojo::Base -base;
use Mojo::IOLoop::Stream;
use Net::SNMP::MessageProcessing ();
use Net::SNMP::Message qw( TRUE FALSE );
use Scalar::Util ();
use constant DEBUG => $ENV{MOJO_SNMP_DEBUG} ? 1 : 0;

has ioloop             => sub { Mojo::IOLoop->singleton };
has message_processing => sub { Net::SNMP::MessageProcessing->instance };
has debug => 0;    # Use MOJO_SNMP_DEBUG=1 instead

sub connections { int values %{$_[0]->{descriptors}} }

sub error {
  my ($self, $format, @args) = @_;

  return $self->{error} if @_ == 1;
  $self->{error} = defined $format ? sprintf $format, @args : undef;
  warn "[Mojo::SNMP::Dispatcher] error: $self->{error}\n" if DEBUG and defined $format;
  return $self;
}

sub send_pdu {
  my ($self, $pdu, $delay) = @_;

  unless (ref $pdu) {
    $self->error('The required PDU object is missing or invalid');
    return FALSE;
  }

  $self->error(undef);
  $self->schedule($delay, [_send_pdu => $pdu, $pdu->retries]);

  return TRUE;
}

sub return_response_pdu {
  $_[0]->send_pdu($_[1], -1);
}

sub msg_handle_alloc {
  $_[0]->message_processing->msg_handle_alloc;
}

sub schedule {
  my ($self, $time, $callback) = @_;
  my $code = shift @$callback;

  warn "[Mojo::SNMP::Dispatcher] Schedule $time $code(@$callback)\n" if DEBUG;

  Scalar::Util::weaken($self);
  $self->ioloop->timer($time => sub { $self->$code(@$callback) });
}

sub register {
  my ($self, $transport) = @_;
  my $reactor = $self->ioloop->reactor;
  my $fileno;

  unless (defined $transport and defined($fileno = $transport->fileno)) {
    $self->error('The Transport Domain object is invalid');
    return FALSE;
  }

  if ($self->{descriptors}{$fileno}++) {
    return $transport;
  }

  Scalar::Util::weaken($self);
  $reactor->io(
    $transport->socket,
    sub {
      $self->_transport_response_received($transport);
    }
  );

  $reactor->watch($transport->socket, 1, 0);
  warn "[Mojo::SNMP::Dispatcher] Add handler for descriptor $fileno\n" if DEBUG;
  return $transport;
}

sub deregister {
  my ($self, $transport) = @_;
  my $fileno = $transport->fileno;
  return if --$self->{descriptors}{$fileno} > 0;
  delete $self->{descriptors}{$fileno};
  warn "[Mojo::SNMP::Dispatcher] Remove handler for descriptor $fileno\n" if DEBUG;
  $self->ioloop->reactor->remove($transport->socket);
}

sub _send_pdu {
  my ($self, $pdu, $retries) = @_;
  my $mp  = $self->message_processing;
  my $msg = $mp->prepare_outgoing_msg($pdu);

  unless (defined $msg) {
    warn "[Mojo::SNMP::Dispatcher] prepare_outgoing_msg: @{[$mp->error]}\n" if DEBUG;
    $pdu->status_information($mp->error);
    return;
  }
  unless (defined $msg->send) {
    if ($pdu->expect_response) {
      $mp->msg_handle_delete($msg->msg_id);
    }
    if ($retries-- > 0 and $!{EAGAIN} or $!{EWOULDBLOCK}) {
      warn "[Mojo::SNMP::Dispatcher] Attempt to recover from temporary failure: $!\n" if DEBUG;
      $self->schedule($pdu->timeout, [_send_pdu => $pdu, $retries]);
      return FALSE;
    }

    $pdu->status_information($msg->error);
    return;
  }

  if ($pdu->expect_response) {
    $self->register($msg->transport);
    $msg->timeout_id($self->schedule($pdu->timeout, ['_transport_timeout', $pdu, $retries, $msg->msg_id,]));
  }

  return TRUE;
}

sub _transport_timeout {
  my ($self, $pdu, $retries, $handle) = @_;

  $self->deregister($pdu->transport);
  $self->message_processing->msg_handle_delete($handle);

  if ($retries-- > 0) {
    warn "[Mojo::SNMP::Dispatcher] Retries left: $retries\n" if DEBUG;
    return $self->_send_pdu($pdu, $retries);
  }
  else {
    warn "[Mojo::SNMP::Dispatcher] No response from remote host @{[ $pdu->hostname ]}\n" if DEBUG;
    $pdu->status_information(q{No response from remote host "%s"}, $pdu->hostname);
    return;
  }
}

sub _transport_response_received {
  my ($self, $transport) = @_;
  my $mp = $self->message_processing;
  my ($msg, $error) = Net::SNMP::Message->new(-transport => $transport);

  $self->error(undef);

  if (not defined $msg) {
    die sprintf 'Failed to create Message object: %s', $error;
  }
  if (not defined $msg->recv) {
    $self->error($msg->error);
    $self->deregister($transport) unless $transport->connectionless;
    return;
  }
  if (not $msg->length) {
    warn "[Mojo::SNMP::Dispatcher] Ignoring zero length message\n" if DEBUG;
    return;
  }
  if (not defined $mp->prepare_data_elements($msg)) {
    $self->error($mp->error);
    return;
  }
  if ($mp->error) {
    $msg->error($mp->error);
  }

  warn "[Mojo::SNMP::Dispatcher] Processing pdu\n" if DEBUG;
  $self->ioloop->remove($msg->timeout_id);
  $self->deregister($transport);
  $msg->process_response_pdu;
}

1;

=encoding utf8

=head1 NAME

Mojo::SNMP::Dispatcher - Instead of Net::SNMP::Dispatcher

=head1 DESCRIPTION

This module works better with L<Mojo::IOLoop> since it register the
L<IO::Socket::INET> sockets in with the mojo reactor.

=head1 ATTRIBUTES

=head2 ioloop

Holds a L<Mojo::IOLoop> object. Same as L<Mojo::SNMP/ioloop>.

=head2 message_processing

Holds an instance of L<Net::SNMP::MessageProcessing>.

=head2 debug

Does nothing. Use C<MOJO_SNMP_DEBUG=1> instead to get debug information.

=head2 error

Holds the last error.

=head2 connections

Holds the number of active sockets.

=head1 METHODS

=head2 send_pdu

This method will send a PDU to the SNMP server.

=head2 return_response_pdu

No idea what this does (?)

=head2 msg_handle_alloc

No idea what this does (?)

=head2 schedule

Used to schedule events at a given time. Use L<Mojo::IOLoop/timer> to
do the heavy lifting.

=head2 register

Register a new transport object with L<Mojo::IOLoop::Reactor>.

=head2 deregister

The opposite of L</register>.

=head1 COPYRIGHT & LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Jan Henning Thorsen - C<jhthorsen@cpan.org>

=cut
