# Tests: rpc error

use strict;
use warnings;

use FindBin ();
use lib "$FindBin::Bin/../lib";

use Test::More;
use RPC::Switch::Client::Tiny::Error;

plan tests => 1;

# test rpc error string
#
my $type = 'rpcswitch';
my $msg = "unsupported req";
my $err = RPC::Switch::Client::Tiny::Error->new('rpcswitch', $msg);
my $str = "$err";

is($str, "rpcswitch error: $msg", "test rpc error string");

