use lib '../lib';

use strict;
use Test::More;

plan tests => 1;


use_ok('SSH::RPC::Client');

# Can't really test any more than this because we don't have an SSH to connect to
