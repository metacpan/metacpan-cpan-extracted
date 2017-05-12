#!/usr/bin/perl
use strict;
use warnings;

use Test::More 'no_plan';

my $class = 'Module::Release';
my $file  = ".releaserc";

use_ok( $class );
can_ok( $class, 'new' );

my $old_dir = cwd();

BEGIN {
	use File::Spec;
	my $file = File::Spec->catfile( qw(t lib setup_common.pl) );
	require $file;
	}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Create object with no parameters
{
my $release = $class->new( quiet => 1 );
isa_ok( $release, $class );
}

