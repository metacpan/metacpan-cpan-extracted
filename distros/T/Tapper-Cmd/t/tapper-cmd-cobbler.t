#!perl

use 5.010;

use warnings;
use strict;

use Test::More;

use Tapper::Cmd::Cobbler;

my $cmd = Tapper::Cmd::Cobbler->new();
my $retval = $cmd->host_new({name => 'Nobel'});
like($retval, qr/^Need a string/, 'Wrong API use detected');

done_testing();
