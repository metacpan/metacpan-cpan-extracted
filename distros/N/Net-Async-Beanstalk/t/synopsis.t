#!perl

use v5.10;
use Test::More;
use t::start_server;

plan tests => 1;

use IO::Async::Loop;
use Net::Async::Beanstalk;

my $loop = IO::Async::Loop->new();

my $client = Net::Async::Beanstalk->new();
$loop->add($client);

$client->connect(host => 'localhost', service => $server_port)->get;
ok $client->put("anything")->get, "Jobs can be inserted";
