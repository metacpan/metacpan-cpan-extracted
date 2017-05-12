# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Net::Analysis-Utils.t'

use warnings;
use strict;
use Data::Dumper;

use Test::More tests => 3;
#use t::TestMockListener;
#use t::TestEtherealGlue;

use Net::Analysis::Dispatcher;
use Net::Analysis::EventLoop;
use Net::Analysis::Listener::TCP;
use Net::Analysis::Listener::HTTP;

#########################

BEGIN { use_ok('Net::Analysis::Listener::HTTPClientPerf') }

#### Create Dispatcher, TCP listener, and mock object listening for TCP events
#
my ($d)        = Net::Analysis::Dispatcher->new();
my ($el)       = Net::Analysis::EventLoop->new (dispatcher => $d);
my ($l_tcp)    = Net::Analysis::Listener::TCP->new (dispatcher => $d);
my ($l_http)   = Net::Analysis::Listener::HTTP->new (dispatcher => $d);


my ($l_httpcp) = Net::Analysis::Listener::HTTPClientPerf->new
    (dispatcher => $d, config => {file=>'out.ps'});

isa_ok ($l_httpcp, 'Net::Analysis::Listener::HTTPClientPerf');

$el->loop_file (filename => 't/ft.tcp');
#$el->loop_file (filename => '/tmp/bah.tcp');

ok (-f('out.ps'), "out.ps can be found")
