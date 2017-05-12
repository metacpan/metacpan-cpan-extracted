# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Net::Analysis-Utils.t'

use warnings;
use strict;
use Data::Dumper;

use Test::More tests => 3;

use Net::Analysis::Dispatcher;
use Net::Analysis::EventLoop;
use Net::Analysis::Listener::TCP;

#########################

BEGIN {
    use_ok('Net::Analysis::Listener::Example1');
    use_ok('Net::Analysis::Listener::Example2');
}

#### Create Dispatcher, TCP listener, and mock object listening for TCP events
#
my ($d)     = Net::Analysis::Dispatcher->new();
my ($l_tcp) = Net::Analysis::Listener::TCP->new (dispatcher => $d);
my ($l_ex1) = Net::Analysis::Listener::Example1->new (dispatcher => $d);
ok ($l_ex1, 'Listener::Example1');

my ($el)    = Net::Analysis::EventLoop->new (dispatcher => $d);

## Capture STDOUT and compare ...
#
#$el->loop_file (filename => "t/t1_google.tcp");
