use strict;
use POSIX qw/SIGKILL/;
use Test::More tests => 3;
use Test::Builder;
use Net::Jabber::Loudmouth;

require 't/server_helper.pl';
my $pid = start_server();

my $c = Net::Jabber::Loudmouth::Connection->new("localhost");

ok($c->open_and_block());

ok($c->authenticate_and_block("foo", "bar", "TestSuite"));

ok($c->close());

kill SIGKILL, $pid;
