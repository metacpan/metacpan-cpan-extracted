#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;
use SMS::Send;

plan tests => 2;

# Check for available drivers
my @drivers = SMS::Send->installed_drivers;

ok scalar(grep { $_ eq 'CMTelecom' } @drivers) == 1, 'Found "CMTelecom" driver';

# In detecting the drivers, they should NOT be loaded
ok !defined $SMS::Send::CMTelecom::VERSION, 'did not load driver when locating them';

