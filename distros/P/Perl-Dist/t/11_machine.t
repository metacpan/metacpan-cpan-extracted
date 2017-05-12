#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 19;
use File::Temp          ();
use Perl::Dist::Machine ();





#####################################################################
# Trivial Test

SCOPE: {
	package My::TestPackage;

	sub new {
		bless [ @_ ], 'My::TestPackage';
	}

	# Pretends to be anything
	sub isa { 1 }

	$INC{'My/TestPackage.pm'} = 'loaded';

	1;
}

my $machine = Perl::Dist::Machine->new(
	class  => 'My::TestPackage',
	output => File::Temp::tempdir( CLEANUP => 1 ),
	common => {
		foo => 1,
	},
);
isa_ok( $machine, 'Perl::Dist::Machine' );
is( $machine->class, 'My::TestPackage' );
ok( -d $machine->output, "Found output directory at '" . $machine->output . '"' );
is_deeply( [ $machine->dimensions ], [], 'No dimensions' );

# Add a dimension
ok( $machine->add_dimension('bar'), '->add_dimension ok' );
ok( $machine->add_dimension('baz'), '->add_dimension ok' );
is_deeply( [ $machine->dimensions ], [ 'bar', 'baz' ], 'No dimensions' );

# Add some options
ok( $machine->add_option( 'bar', bar => 1 ), '->add_option ok' );
ok( $machine->add_option( 'bar', bar => 2 ), '->add_option ok' );
ok( $machine->add_option( 'baz', bar => 1 ), '->add_option ok' );
ok( $machine->add_option( 'baz', bar => 2 ), '->add_option ok' );
ok( $machine->add_option( 'baz', bar => 3 ), '->add_option ok' );

# Get the full list of values
my @all = $machine->all;
is( scalar(@all), 6, 'Got 6 objects as expected' );
foreach ( @all ) {
	isa_ok( $_, 'My::TestPackage' );
}
