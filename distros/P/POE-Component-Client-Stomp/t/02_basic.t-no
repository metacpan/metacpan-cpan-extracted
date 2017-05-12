use strict;
use warnings;

my $count = 10;
my $body = join(
    "\n",
    ("0123456789abcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmnopqrstuvwxyz") x 10
);

package Listener;

use POE;
use base qw(POE::Component::Client::Stomp);
use Test::More (tests => 40);

sub spawn {
    my $class = shift;

    my %args = @_;
    my $self = $class->SUPER::spawn(%args);

    $self->{counter} = 0;

    return $self;

}

sub handle_connection {
    my ($kernel, $self) = @_[KERNEL,OBJECT];

    my $frame;

    $frame = $self->stomp->connect(
        {
            login => 'testing', 
            passcode => 'testing'
        }
    );

    $kernel->yield('send_data', $frame);

}

sub handle_connected {
    my ($kernel, $self, $frame) = @_[KERNEL,OBJECT,ARG0];

    my $nframe;

    $nframe = $self->stomp->subscribe(
        {
            destination => $self->config('Queue'), 
            ack => 'client'
        }
    );

    $kernel->yield('send_data', $nframe);

}

sub handle_message {
    my ($kernel, $self, $frame) = @_[KERNEL,OBJECT,ARG0];

    my $nframe;
    my $message_id = $frame->headers->{'message-id'};
    $nframe = $self->stomp->ack({'message-id' => $message_id});

    ok($frame);
    isa_ok($frame, 'Net::Stomp::Frame');
    isa_ok($nframe, 'Net::Stomp::Frame');
    is($frame->body, $body);

    $self->{counter}++;

    $kernel->yield('send_data', $nframe);

    if ($self->{counter} >= $count) {

       $nframe = $self->stomp->disconnect();
       $kernel->yield('send_data', $nframe);
       $kernel->stop();

     }

}

sub log {
    my ($self, $kernel, $level, @args) = @_;

}

# =====================================================================

package Sender;

use POE;
use base qw(POE::Component::Client::Stomp);

sub handle_connection {
    my ($kernel, $self) = @_[KERNEL,OBJECT];

    my $frame;

    $frame = $self->stomp->connect(
        {
            login => 'testing', 
            passcode => 'testing'
        }
    );

    $kernel->yield('send_data', $frame);

}

sub handle_connected {
    my ($kernel, $self, $frame) = @_[KERNEL,OBJECT,ARG0];

    $kernel->yield('gather_data');

}

sub gather_data {
    my ($kernel, $self) = @_[KERNEL,OBJECT];

    my $x;
    my $frame;

    for ($x = 0; $x < $count; $x++) {

        $frame = $self->stomp->send(
            {
                destination => $self->config('Queue'),
                data => $body
            }
        );

        $kernel->yield('send_data', $frame);

    }

    $frame = $self->stomp->disconnect();
    $kernel->yield('send_data', $frame);

}

sub log {
    my ($self, $kernel, $level, @args) = @_;

}

# =====================================================================

package main;

use POE;

sub handle_shutdown {

    $poe_kernel->yield('shutdown');

}

main: {

    Listener->spawn(
        Queue => '/queue/testing'
    );

    Sender->spawn(
        Queue => '/queue/testing'
    );

    $poe_kernel->state('got_signal', 'main', \&handle_shutdown);
    $poe_kernel->sig(INT => 'got_signal');
    $poe_kernel->run();

}

