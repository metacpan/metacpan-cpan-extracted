# Tests: netstring

use strict;
use warnings;

use FindBin ();
use lib "$FindBin::Bin/../lib";

use Test::More;
use Socket;
use RPC::Switch::Client::Tiny::Netstring;
use Data::Dumper;

plan tests => 3;

socketpair(my $out, my $in, AF_UNIX, SOCK_STREAM, PF_UNSPEC) or die "socketpair: $!";

my $msg = 'test 123';
my $res = netstring_write($out, $msg);
isnt($res, undef, 'test netstring write');

my $b = eval { netstring_read($in) };
my $err = $@;
is($err, '', 'test netstring read result');
is($b, $msg, 'test netstring read msg');

