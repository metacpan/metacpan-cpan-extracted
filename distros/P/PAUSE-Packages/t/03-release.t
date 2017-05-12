#!perl

use strict;
use warnings;

use Test::More 0.88 tests => 4;
use PAUSE::Packages;

#-----------------------------------------------------------------------
# construct PAUSE::Packages
#-----------------------------------------------------------------------

my $pp = PAUSE::Packages->new(path => 't/02packages-mini.txt');
my $release;

ok(defined($pp), "instantiate PAUSE::Packages");

#-----------------------------------------------------------------------
$release = $pp->release('Module-Does-Not-Exist');
ok(!defined($release), 'non-existent module should result in undef');

#-----------------------------------------------------------------------
$release = $pp->release('Module-Path');
ok(defined($release), 'We should find something for Module-Path');

# Construct a string with info
#-----------------------------------------------------------------------
my $expected = <<"END_EXPECTED";
Module-Path|Module::Path
END_EXPECTED

my $string = '';

$string .= $release->distinfo->dist
           .'|'
           .join(',', map { $_->name } @{ $release->modules })
           ."\n";

is($string, $expected, "rendered release details");

