#!perl
use 5.008;
use strict;
use warnings FATAL => 'all';
use lib 't/lib';
use Net::RCON::Minecraft;
use Local::Helpers;

use Test::More;

my $rcon;

ok $rcon = Net::RCON::Minecraft->new, 'No options';
ok $rcon = Net::RCON::Minecraft->new({ password => 'secret' }), 'Synopsis';
ok $rcon = Net::RCON::Minecraft->new(  password => 'secret'  ), 'Not a HASH ref';

ok $rcon = Net::RCON::Minecraft->new({foo => 'bar'});
is ref($rcon), 'Net::RCON::Minecraft', 'Correct ref';

done_testing;
