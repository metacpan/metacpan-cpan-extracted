#!perl
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

my $unknown = $rcon->command('unknown_command');
like $unknown, qr/Unknown command/, 'Unknown';

my $list = $rcon->command('list');
my $re = qr/There are \d+ of a max \d+ players online:/;
if ($list !~ $re) {
    diag 'Got a response to /list but did not match regexp.';
    diag 'This may be normal if you are not on a vanilla server.';
    diag '     Got response: ' . $list;
    diag '   Expected match: ' . $re;
}

isnt $unknown, $list, 'Results from list and unknown_command differ';

done_testing;
