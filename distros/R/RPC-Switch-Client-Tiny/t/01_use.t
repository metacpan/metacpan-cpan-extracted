# Tests: use

use strict;
use warnings;

use FindBin ();
use lib "$FindBin::Bin/../lib";

use Test::More tests => 5;

use_ok('RPC::Switch::Client::Tiny::Error');
use_ok('RPC::Switch::Client::Tiny::Netstring');
use_ok('RPC::Switch::Client::Tiny::Async');
use_ok('RPC::Switch::Client::Tiny::SessionCache');
use_ok('RPC::Switch::Client::Tiny');

