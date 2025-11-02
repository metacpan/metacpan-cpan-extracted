#!/usr/bin/perl

# Test if version increments
use Test2::V0;
use Test::GreaterVersion;
use CPAN::Meta;

# Don't run tests during end-user installs
skip_all( 'Author tests not required for installation' )
	unless ( $ENV{RELEASE_TESTING} or $ENV{AUTOMATED_TESTING} );

plan(2);

# this compares with the system wide installed version
# has_greater_version('HO::class');
 
has_greater_version_than_cpan('Package::Subroutine');

my $meta = CPAN::Meta->load_file('META.yml');

use Package::Subroutine;

# checks if "./Build distmeta" was executed
is("$Package::Subroutine::VERSION", $meta->version,'Version updated');

1;
