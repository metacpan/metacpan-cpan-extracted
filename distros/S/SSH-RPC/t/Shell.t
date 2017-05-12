use lib '../lib';

use strict;
use Test::More;

plan tests => 4;


use_ok('SSH::RPC::Shell');
is(ref SSH::RPC::Shell::run_noop(), 'HASH', 'noop returns hash');
is(SSH::RPC::Shell->run_noop()->{status}, 200, 'noop returns success');
my $response = SSH::RPC::Shell->processRequest({command=>'noop'});
is (ref $response, 'HASH', "can get a response");



