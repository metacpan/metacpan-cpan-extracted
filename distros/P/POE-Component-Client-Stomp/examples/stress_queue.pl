#!/usr/bin/perl
#
# File: stress_queue.pl
# Date: 15-Oct-2007
# By  : Kevin Esteb
#
# Simple test program to test POE interaction.
#

use lib '../lib';

package Client;

use POE;
use Data::Dumper;
use base qw(POE::Component::Client::Stomp);

use strict;
use warnings;

# ----------------------------------------------------------------------

sub spawn {
    my $class = shift;

    my %args = @_;
    my $self = $class->SUPER::spawn(%args);

    $self->{counter} = 0;
    $self->{alarm_id} = 0;

    return $self;

}

sub handle_connection {
    my ($kernel, $self) = @_[KERNEL,OBJECT];

    my $frame;
    my $buffer = sprintf("Connected to %s on %s", $self->host, $self->port);

    $self->log($kernel, 'info', $buffer);
    $frame = $self->stomp->connect({login => 'guest', 
                                    passcode => 'guest'});
    $kernel->yield('send_data' => $frame);

}

sub handle_connected {
    my ($kernel, $self, $frame) = @_[KERNEL,OBJECT,ARG0];

    $kernel->yield('gather_data');

}

sub gather_data {
    my ($kernel, $self) = @_[KERNEL,OBJECT];
    
    $self->{counter}++;
    my $body = sprintf("Message #%s", $self->{counter});
    my $frame = $self->stomp->send({destination => $self->config('Queue'),
                                    data => $body});

    $self->{alarm_id} = $kernel->delay_set('gather_data', 15);
    $kernel->yield('send_data' => $frame);

}

sub log {
    my ($self, $kernel, $level, @args) = @_;

    if ($level eq 'error') {

        print "ERROR - @args\n";

    } elsif ($level eq 'warn') {

        print "WARN  - @args\n";

    } elsif ($level eq 'debug') {

        print "DEBUG - @args\n" if $self->config('Debug');

    } else {

        print "INFO  - @args\n";

    }

}

# =====================================================================

package main;

use POE;
use Getopt::Long;

use strict;
use warnings;

my $debug = 0;
my $port = '61613';
my $hostname = 'localhost';
my $queue = '/queue/testing';

my $VERSION = '0.01';

# ----------------------------------------------------------------------

sub handle_signals {

    $poe_kernel->yield('shutdown');

}

sub usage {

    my ($Script) = ( $0 =~ m#([^\\/]+)$# );
    my $Line = "-" x length( $Script );

    print << "EOT";
$Script
$Line
stress_queue - Send messages to a STOMP message queue.
Version: $VERSION

Usage:

    $0 [--hostname] <hostname>
    $0 [--port] <port number>
    $0 [--queue] <queue name>
    $0 [--dump]
    $0 [--help]
    $0 [--debug]

    --hostname..The host where the server is localed
    --port......The port to connect too
    --queue.....The message queue to listent too
    --debug.....Print debugging messages
    --help......Print this help message.

Examples:

    $0 --hostname mq.example.com --port 61613 --queue /queue/testing
    $0 --help

EOT

}

sub setup {

    my $help;

    GetOptions('help|h|?' => \$help, 
               'hostname=s' => \$hostname,
               'port=s' => \$port,
               'queue=s' => \$queue,
               'debug' => \$debug);

    if ($help) {

        usage();
        exit 0;

    }

}

main: {

    setup();

    Client->spawn(
        RemoteAddress => $hostname,
        RemotePort => $port,
        Alias => 'testing',
        Queue => $queue,
        Debug => $debug,
    );

    $poe_kernel->state('got_signal', \&handle_signals);
    $poe_kernel->sig(INT => 'got_signal');
    $poe_kernel->sig(TERM => 'got_signal');
    $poe_kernel->sig(QUIT => 'got_signal');

    $poe_kernel->run();

    exit 0;

}

