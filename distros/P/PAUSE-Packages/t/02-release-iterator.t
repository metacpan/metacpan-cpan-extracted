#!perl

use strict;
use warnings;

use Test::More 0.88 tests => 3;
use PAUSE::Packages;

#-----------------------------------------------------------------------
# construct PAUSE::Packages
#-----------------------------------------------------------------------

my $pp = PAUSE::Packages->new(path => 't/02packages-mini.txt');

ok(defined($pp), "instantiate PAUSE::Packages");

#-----------------------------------------------------------------------
# construct the iterator
#-----------------------------------------------------------------------
my $iterator = $pp->release_iterator();

ok(defined($iterator), 'create release iterator');

#-----------------------------------------------------------------------
# Construct a string with info
#-----------------------------------------------------------------------
my $expected = <<"END_EXPECTED";
Module-Path|Module::Path
PAUSE-Permissions|PAUSE::Permissions,PAUSE::Permissions::Module
undef|Tie::RevRefHash
END_EXPECTED

my $string = '';

while (my $release = $iterator->next_release) {
    $string .= ($release->distinfo->dist || 'undef')
               .'|'
               .join(',', map { $_->name } @{ $release->modules })
               ."\n";
}

is($string, $expected, "rendered release details");

