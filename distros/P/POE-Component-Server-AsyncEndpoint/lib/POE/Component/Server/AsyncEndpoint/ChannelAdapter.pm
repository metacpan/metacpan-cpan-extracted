package POE::Component::Server::AsyncEndpoint::ChannelAdapter;


use warnings;
use strict;
our @EXPORT = ( );
use Switch;
use base qw(Exporter);
use vars qw($VERSION);
$VERSION = '0.10';

use Carp qw(croak);
use POE;

use POE::Component::IKC::Client;
use POE::Component::Server::AsyncEndpoint::ChannelAdapter::Config;


use constant SHUTDOWN_SIGNALS => ('TERM', 'HUP', 'INT');


sub new{
  my $package = shift;
  croak "$package requires an even number of parameters" if @_ & 1;
  my %args = @_;
  my $self = bless ({}, $package);


  croak "cannot init CA without a POE session alias" unless $args{Alias};

  $self->{CONFIG} = \%args;
  $self->{alias} = $args{Alias};
  $self->{config} = POE::Component::Server::AsyncEndpoint::ChannelAdapter::Config->init($self->{alias});
  $self->{ikc_stat} = 0;

  my @ostates = @{$args{OStates}} or undef;

  POE::Component::IKC::Client->spawn(
    ip => $self->{config}->ikc_addr,
    port => $self->{config}->ikc_port,
    name => $$."_IKCC",
    on_connect => sub {
      POE::Kernel->post('IKC', 'publish', 'CA_SESSION', ['aesstat', 'shutdown']);
      $self->{ikc_stat} = 1;
    },
  );


  # Main AES Session
  @ostates = (qw( child_sig aesstat start shutdown_endpoint logit ),@ostates);
  POE::Session->create(
    object_states => [
      $self => {
        _start => '_client_start',
        _stop => 'stop',
        shutdown => '_shutdown',
      },
      $self => \@ostates,
    ],
    (ref $args{options} eq 'HASH' ? (options => $args{options}) : () ),
  );

  return $self;

}

# only for debug
sub child_sig {
 $_[KERNEL]->post('logit','debug',"CHLD:".$_[ARG1]."\n");
}

sub _client_start {
  my ($kernel, $self) = @_[KERNEL, OBJECT];
  $kernel->alias_set($self->{alias});
  $kernel->alias_set('CA_SESSION'); # for IKC
  $kernel->sig(CHLD => 'child_sig');

  foreach my $signal ( SHUTDOWN_SIGNALS ){
    $kernel->sig($signal => 'shutdown');
  }
  $kernel->yield('start');
}


# derived classes may override this method
sub start {
  my ($kernel, $session) = @_[KERNEL, SESSION];
  return;
}

sub stop {
  my ($kernel, $session) = @_[KERNEL, SESSION];
  return;
}


# AES Status Request
sub aesstat {
  my ($kernel, $self) = @_[KERNEL, OBJECT];
  return "CASTAT|$$|OK";
}

# AES Shutdown Request
sub _shutdown {
  my ($kernel, $self) = @_[KERNEL, OBJECT];
  $kernel->delay_set('shutdown_endpoint', 1);
}

# may be overriden but must call SUPER
sub shutdown_endpoint {
  my ($kernel, $self) = @_[KERNEL, OBJECT];
  $kernel->post('IKC','shutdown');
  $kernel->alias_remove($self->{alias});
  $kernel->alias_remove('CA_SESSION');
}

sub run {
  POE::Kernel->run();
  exit(0);
}


# logger via IKC
sub logit {
  my ($kernel, $self, $level, $message) = @_[KERNEL, OBJECT, ARG0, ARG1];
  my $alias = $self->{alias};
  $kernel->post( 'IKC', 'post', 'poe://IKCS/AES_SESSION/ikc_event', "LOGIT|$$|$alias;;$level;;$message");
}



1;


__END__


=head1 NAME

POE::Component::Server::AsyncEndpoint::ChannelAdapter

=head1 SYNOPSIS

  shell$ endpointcreate

This will create the Endpoint subdirectory and files. Depending on the
endpoint type, it should create a module similar to the one below. For
simplicity, we show the single phase Outbound endpoint skeleton. For
further information, generate one and read the fully commented
skeleton code.

=head2 Typical single-phase Outbound Endpoint

        package OB_SampleSP;

        use POE;
        use base POE::Component::Server::AsyncEndpoint::ChannelAdapter;
        use POE::Component::Server::AsyncEndpoint::ChannelAdapter::Stomp;
        use POE::Component::Server::AsyncEndpoint::ChannelAdapter::SOAP;
        use POE::Component::Server::AsyncEndpoint::ChannelAdapter::Config;
        use JSON; #optional

        sub new {

            my $class = shift;

            # Init the new class with added Object States
            my $Alias = OB_SampleSP;
            my $self = $class->SUPER::new({
                Alias => $Alias,
                OStates =>
                    [ 'pop_fifo', 'RCPT_OB_SampleSP' ],
            });

            # Init the Stomp Client
            my $stc = POE::Component::Server::AsyncEndpoint::ChannelAdapter::Stomp->spawn({
                Alias         => $Alias . '_STC',
                mq_address    => $self->{config}->mq_address,
                mq_port       => $self->{config}->mq_port,
                queue         => '/queue/ob_sample_sp',
                direction     => 'OB',
                user          => $self->{config}->stcuser,
                pass          => $self->{config}->stcpass,
                # For OB Endpoints you MUST specicfy the callback for STOMP RECEIPT
                rcpt_callback => {
                    to_session => $Alias,
                    to_handler => 'RCPT_OB_SampleSP',
                },

            });

            # Init the SOAP Client
            my $soc = POE::Component::Server::AsyncEndpoint::ChannelAdapter::SOAP->spawn({
                proxy   => $self->{config}->soap_proxy,
                service => $self->{config}->soap_service,
            });

            # Save the STOMP Client
            $self->{STC} = $stc;

            # Save the SOAP Client
            $self->{SOC} = $soc;

            # Init the popper
            POE::Kernel->post( 'OB_SampleSP', 'pop_fifo' );

            return $self;

        }

        # Sample overload of run
        sub run {
            my $self = shift;
            $self->SUPER::run();
        }

        # Sample FIFO popper routine
        sub pop_fifo {
            my ( $self, $kernel, $session ) = @_[ OBJECT, KERNEL, SESSION ];

            # reset the popper
            $kernel->delay_set('pop_fifo', $self->{config}->popper_freq);

            # not yet completely initialized
            return unless ($self->{ikc_stat} && $self->{STC}->{stc_stat});

            # return if a fifo record is being processed 
            # (see POE::Component::Server::AsyncEndpoint)
            return if defined($self->{fifo_id});

            my $soc = $self->{SOC};

            # pop the FIFO via SOAP (sample)
            my $call = $soc->popOBSampleOutboundFIFO(
                $self->{config}->socuser,
                $self->{config}->socpass
            );

            my $stc = $self->{STC};

            unless ( $call->fault ) {
                # Sample use of JSON Serialization
                # (why JSON? see POE::Component::Server::AsyncEndpoint)
                my $retval = from_jason( $call->result );

                # Sample data retrieval
                if ( my $fifo_id = $retval->{fifo_id} ) {

                    $self->{fifo_id} = $fifo_id;
                    $self->{data}  = from_json( $retval->{params} );

                    # publish the data on the MQ, and ask for RECEIPT
                    my $nframe = $stc->stomp->send({
                        destination => $stc->config('Queue'),
                        data        => to_json($self->{data}),
                        receipt     => $fifo_id,
                    });
                    $kernel->call( $stc->config('Alias'), 'send_data', $nframe );

                }
                else {
                    $self->{fifo_id} = undef;
                    $self->{data}  = undef;
                }
            }
            else {
                my $logmsg = "FAILED pop_fifo (".
                    $call->faultstring.")\n";
                $kernel->yield('logit', 'alert', $logmsg);
            }

        }

        # RECEIPT callback
        sub RCPT_OB_SampleSP {

            my ($self, $kernel, $frame) = @_[OBJECT, KERNEL, ARG0];

            my $receipt_id = $frame->headers->{receipt};
            my $fifo_id    = $self->{fifo_id};

            # sanity
            if($receipt_id != $fifo_id){
                my $logmsg = "ENDPOINT PANIC! THE RECEIPT ID DOES NOT MATCH THE FIFO ID! BAILING OUT...!\n";
                $kernel->yield('logit', 'emergency', $logmsg);
                croak $logmsg;
            }

            my $soc = $self->{SOC};

            # Mark the FIFO record as 'popped' via SOAP
            my $call = $soc->poppedOBSampleSPFIFO(
                $self->{config}->socuser,
                $self->{config}->socpass,
                $fifo_id
            );

            my $popped_fail = 0;

            unless ( $call->fault ) {
                if ( $call->result eq 'OK' ) {
                    $self->{fifo_id} = undef;
                    $self->{params}  = undef;
                }
                else {
                    my $logmsg = "The popped WS executed fine, ".
                        "but it did NOT return OK (".$call->result.")\n";
                    $kernel->yield('logit', 'alert', $logmsg);
                    $popped_fail = 1;
                }

            }
            else {
                my $logmsg = "poppedOB_SampleSPFIFO FAILED for FIFO ID $fifo_id (".
                    $call->faultstring.")\n";
                $kernel->yield('logit', 'alert', $logmsg);
                $popped_fail = 1;
            }

            # retry popped service if failure
            if($popped_fail){
                $kernel->delay_set('RCPT_OB_SampleSP', int($self->{config}->soc_retry), $frame);
            }


        }

        1;



=head1 DESCRIPTION

The ChannelAdapter class is the base of all Endpoints, so you should
start your endpoint by using this class as base (as the example above
suggests). If you use the helper scripts this will all be done for you
automatically.

=head2 Methods

=over 4

=item new

You should override this method and then call SUPER::new to initialize
the Channel Adapter. The parameter OStates allows you to add object
states to the main Channel Adapter session so you can post events and
handle them in your object methods. Like any object methods these will
call back to subroutines in your object of the same name.

        my $self = $class->SUPER::new({
            Alias => $Alias,
            OStates =>
                [ 'pop_fifo', 'RCPT_OB_SampleSP' ],
        });

        sub pop_fifo {

        }

        sub RCPT_OB_SampleSP {


        }

In this example we are declaring two object methods that will be
called when an event is posted to the session identified by
$Alias. The new method is also a good place to initialize the clients
for the different protocols your Endpoint is going to support. For
example to initialize a STOMP Client for an Outbound Endpoint you
would do something like:

        my $stc = POE::Component::Server::AsyncEndpoint::ChannelAdapter::Stomp->spawn({
            Alias         => $Alias . '_STC',
            mq_address    => $self->{config}->mq_address,
            mq_port       => $self->{config}->mq_port,
            queue         => '/queue/ob_sample_sp',
            direction     => 'OB',
            user          => $self->{config}->stcuser,
            pass          => $self->{config}->stcpass,
            rcpt_callback => {
                to_session => $Alias,
                to_handler => 'RCPT_OB_SampleSP',
            },

        });

Here we initialize a STOMP client and since it's an Outbound Endpoint
we are obligated to specify the session and handler that the STOMP
client will call when it has had a RECEIPT from the MQ. As you can
see, we use one of the object states declared in SUPER::new
above. This means that when the STOMP RECEIPT arrives, the client will
post this to the session in $Alias (which is the main Channel Adapter
session) and it, in turn, will call our local object method (local
subroutine). For more information on how this is actually done see
L<POE> and
L<POE::Component::Server::AsyncEndpoint::ChannelAdapter::Stomp>

=item run

If you don't override this method, it will just call the Channel
Adapter's CA run method which at the moment just runs the POE Kernel.

=head1 EXAMPLES

Just use the B<endpointcreate> helper script, follow the prompts and
look inside the generated code which is fully documented.

=head1 SEE ALSO

L<POE::Component::Server::AsyncEndpoint::ChannelAdapter::SOAP>
L<POE::Component::Server::AsyncEndpoint::ChannelAdapter::Stomp>
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



