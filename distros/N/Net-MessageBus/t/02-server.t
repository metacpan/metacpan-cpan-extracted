#!perl

use 5.006;
use strict;
use warnings;
use Test::More tests => 5;

use Net::MessageBus::Server;

my $MessageBus_server = Net::MessageBus::Server->new();

isa_ok($MessageBus_server,"Net::MessageBus::Server");

ok($MessageBus_server->daemon(),'Server started');

ok($MessageBus_server->is_running(),'Server is running');

ok($MessageBus_server->stop(),'Stop command worked');

ok(! $MessageBus_server->is_running(),'Server is not running anymore');