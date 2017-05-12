use lib '../lib';

use strict;
use Test::More;

plan tests => 2;


use_ok('SSH::RPC::Client');
my $client = SSH::RPC::Client->new('127.0.0.1');
isa_ok($client,'SSH::RPC::Client');

