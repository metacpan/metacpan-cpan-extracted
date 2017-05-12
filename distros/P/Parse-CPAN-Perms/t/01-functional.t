#!perl

use strict;
use warnings;

use Test::More;

use Parse::CPAN::Perms;

#-----------------------------------------------------------------------------

my $expect = {PkgA => {JOE => 'f', BOB => 'c'}, PkgB => {SUE => 'm'}};
my $perms = Parse::CPAN::Perms->new('t/data/06perms.txt.gz');
is_deeply( $perms->perms, $expect );

is($perms->is_authorized(BOB => 'PkgA'), 1);
is($perms->is_authorized(BOB => 'PkgB'), 0);

#-----------------------------------------------------------------------------

done_testing;