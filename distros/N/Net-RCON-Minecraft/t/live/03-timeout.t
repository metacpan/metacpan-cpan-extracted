#!perl
use 5.008;
use strict;
use warnings FATAL => 'all';
use lib 't/lib';
use Test::Exception;
use Test::More;
use Local::Helpers;

use Net::RCON::Minecraft;

my %opts = env_rcon;
plan(skip_all => live_skip) unless %opts;

my $rcon = Net::RCON::Minecraft->new(%opts);

lives_ok { $rcon->connect };

# Set timeout after connect so we don't prematurely fail
ok $rcon->timeout(0.1), 'Timeout set';

my $res;
throws_ok { $res = $rcon->command('reload') } qr/Server timeout/, 'Timeout';
diag "Unexpected result `$res'" if defined $res;

done_testing;
