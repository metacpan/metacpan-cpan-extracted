#!/usr/bin/perl
# 
# File: feed_queue.pl
# Date: 27-Sep-2007
# By  : Kevin Esteb
#
# send a message to the queue 'foo'
#

use lib '../lib';

use Net::Stomp;
use Getopt::Long;

use strict;
use warnings;

# ----------------------------------------------------------------------
# Global variables
# ----------------------------------------------------------------------

my $stomp;
my $count = 10;
my $port = '61613';
my $hostname = 'localhost';
my $queue = '/queue/testing';
my $VERSION = '0.01';

# ----------------------------------------------------------------------

sub usage {

    my ($Script) = ( $0 =~ m#([^\\/]+)$# );
    my $Line = "-" x length( $Script );

    print << "EOT";
$Script
$Line
feed_queue - Feed a STOMP message queue.
Version: $VERSION

Usage:

    $0 [--hostname] <hostname>
    $0 [--port] <port number>
    $0 [--queue] <queue name>
    $0 [--count] <number>
    $0 [--help]

    --hostname..The host where the server is localed
    --port......The port to connect too
    --queue.....The message queue to listent too
    --count.....The number of times to send the message
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
               'count=i' => \$count);

    if ($help) {

        usage();
        exit;

    }

}

main: {

    setup();

    $stomp = Net::Stomp->new({ hostname => $hostname, port => $port });
    $stomp->connect( { login => 'guest', passcode => 'guest' } );

    for (my $x = 0; $x < $count; $x++) {

        $stomp->send({ destination => $queue, body => "test message: $x"  });

    }

    $stomp->disconnect;

}

