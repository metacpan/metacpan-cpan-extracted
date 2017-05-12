package POE::Component::Server::AsyncEndpoint::ChannelAdapter::Stomp;

use warnings;
use strict;
our @EXPORT = ( );
use Switch;

use Carp qw(croak);
use POE;
use base qw(Exporter POE::Component::Client::Stomp);
use vars qw($VERSION);
$VERSION = '0.10';


sub spawn{

  my $package = shift;
  croak "$package requires an even number of parameters" if @_ & 1;
  my %args = @_;

  my $alias  = $args{Alias};
  my $mq_address  = $args{mq_address};
  my $mq_port  = $args{mq_port};
  my $queue  = $args{queue};
  my $direction  = $args{direction};
  my $user  = $args{user};
  my $pass  = $args{pass};
  my $rx_callback  = $args{rx_callback};
  my $rcpt_callback = $args{rcpt_callback};
  my $err_callback  = $args{err_callback};


  croak "Cannot init Stomp Client without valid Alias!"
    unless $alias;

  croak "Cannot init Stomp Client without valid IP and Port!"
    unless ($mq_address && $mq_port);

  croak "Direction must be OB or IB!"
    unless ($direction =~ /^OB|IB$/);

  croak "Cannot init IB/OB Stomp Client without a Queue!"
    unless ($queue);

  if ($direction eq 'IB') {

    croak "If Stomp Client is IB you must define Message Handler Callback!"
      unless ($rx_callback->{to_session} && $rx_callback->{to_handler});

  }


  if ($direction eq 'OB') {
    croak "If Stomp Client is OB you must define Receipt Handler Callback!"
      unless ($rcpt_callback->{to_session} && $rcpt_callback->{to_handler});
  }

  my $self = $package->SUPER::spawn(
    Alias => $alias,
    RemoteAddress => $mq_address,
    RemotePort => $mq_port,
    Queue => $queue,
    User => $user,
    Pass => $pass,
    Direction => $direction,
    RxCallback => $rx_callback,
    RcptCallback => $rcpt_callback,
    ErrCallback => $err_callback,
  );

  # initialized flag (will be set to 1 uppon connected
  $self->{stc_stat} = 0;

  return $self;

}

# called when connected to the port
sub handle_connection {
  my ($kernel, $self) = @_[KERNEL, OBJECT];

  my $nframe = $self->stomp->connect({
    login => $self->config('User'),
    passcode => $self->config('Pass'),
  });

  $kernel->post($self->config('Alias'), 'send_data', $nframe);

}

# called when CONNECT frame is recieved from stomp server
sub handle_connected {
  my ($kernel, $self, $frame) = @_[KERNEL,OBJECT,ARG0];

  # marks stomp client as initialized
  $self->{stc_stat} = 1;

  # add the ACK_message object state
  $kernel->state('ACK_message', $self);

  # only IB stomp clients need to subscribe
  if ($self->config('Direction') eq 'IB') {

    my $nframe = $self->stomp->subscribe({
      destination => $self->config('Queue'),
      ack => 'client'
    });
    $kernel->post($self->config('Alias'), 'send_data', $nframe);
  }

}

# Main Message Handler
sub handle_message {
  my ($kernel, $self, $frame) = @_[KERNEL, OBJECT, ARG0];

  if ($self->config('Direction') eq 'IB') {
    my $to_session = $self->config('RxCallback')->{to_session};
    my $to_handler = $self->config('RxCallback')->{to_handler};
    $kernel->post($to_session, $to_handler, $frame);
  }

}

sub handle_error {
  my ($kernel, $self, $frame) = @_[KERNEL,OBJECT,ARG0];

  #TODO: Error Handling

  print STDERR "TODO: HANDLE ERROR";

}


sub handle_receipt {
  my ($kernel, $self, $frame) = @_[KERNEL,OBJECT,ARG0];
  my $receipt = $frame->headers->{receipt};

  if ($self->config('Direction') eq 'OB') {
    my $to_session = $self->config('RcptCallback')->{to_session};
    my $to_handler = $self->config('RcptCallback')->{to_handler};
    $kernel->post($to_session, $to_handler, $frame);
  }


}

sub ACK_message {

  my ($kernel, $self, $message_id) = @_[KERNEL,OBJECT,ARG0];

  my $nframe = $self->stomp->ack({'message-id' => $message_id});
  $kernel->call($self->config('Alias'), 'send_data', $nframe);

}


sub log {

  # Left to be overriden by implementation

}


# PoCo::Client::Stomp is not clear on what this is. From the doc:
#This event and corresponding method is used to "gather data". How
#that is done is up to your program. But usually a "send_data" event
#is generated.
sub gather_data {
  warn "gather_data() - please report if you see this message";
}




1;

__END__

=head1 NAME

POE::Component::Server::AsyncEndpoint::ChannelAdapter::Stomp


=head1 SYNOPSIS

When you init your Endpoint:

        # Sample Outbound STOMP Client
        my $stc = POE::Component::Server::AsyncEndpoint::ChannelAdapter::Stomp->spawn({
            Alias         => $Alias . '_STC',
            mq_address    => $self->{config}->mq_address,
            mq_port       => $self->{config}->mq_port,
            queue         => '/queue/ob_sample',
            direction     => 'OB',
            user          => $self->{config}->stcuser,
            pass          => $self->{config}->stcpass,
            rcpt_callback => {
                to_session => $Alias,
                to_handler => 'RCPT_OB_Sample',
            },
        });


Later in your Endpoint:

        my $nframe = $stc->stomp->send({
            destination => $stc->config('Queue'),
            data        => $your_data,
            receipt     => $your_message_id,
        });

        $kernel->call( $stc->config('Alias'), 'send_data', $nframe );


=head1 DESCRIPTION

This class is mainly a wrapper around POE::Component::Client::Stomp
that not only simplifies it's use in your Endpoint, but also enforces
certain rules so the implementation complies with the Channel Adapter
design pattern. For example if you initialize an Outbound STOMP
client it will refuse to initialize until you have defined a callback
for the STOMP/RECEIPT, if it's an IB client it will refuse to
initialize if you don't define a callback to handle received data from
the queue.

=head2 Methods

=over 4

=item spawn

Parameters:

    Alias:      An alias for the STOMP client session. It should be set
                to the Endpoint's Alias with a suffix as such: $Alias . '_STC',

    mq_address: The IP address of the message queue where you will 
                publish or subscribe to.

    mq_port:    The IP port of the above address.

    queue:      The MQ queue name. Example: '/queue/ob_sample',

    direction:  Must be 'OB' or 'IB' for Outbound and Inbound respectively.

    user:       STOMP User

    pass:       STOMP Password

If it's an Outbound client you must define a callback for the
STOMP/RECEIPT. The parameter is B<rcpt_callback> and it will expect a
hash ref with two parameters: B<to_session> and B<to_handler>.

    to_session: Specifies to which POE session the STOMP events should be
                posted to.

    to_handler: Specifies the object method that will be called when the
                client gets a RECEIPT.

    For example:

        rcpt_callback => {
            to_session => $Alias, #post to our Endpoint session...
            to_handler => 'RCPT_OB_Sample', # ...to this object method
        },


If it's an Inbound client you must define a callback when data is
received from the queue. The parameter is B<rx_callback> and will
expect a hash ref with the same parameters as above.

    For example:

        rx_callback => {
            to_session => $Alias,
            to_handler => 'IB_Sample',
        },



=head1 SEE ALSO

L<POE::Component::Client::Stomp>

L<POE::Component::Server::AsyncEndpoint::ChannelAdapter::SOAP>
L<POE::Component::Server::AsyncEndpoint::ChannelAdapter::Config>

L<POE::Component::Server::AsyncEndpoint>
L<POE>

=head1 AUTHOR

Alejandro Imass <ait@p2ee.org>
Alejandro Imass <aimass@corcaribe.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Alejandro Imass / Corcaribe Tecnología C.A. for the P2EE Project

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
