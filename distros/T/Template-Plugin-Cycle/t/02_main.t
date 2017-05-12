#!/usr/bin/perl

# Main functional unit tests for Template::Plugin::Cycle module

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 76;
use Template::Plugin::Cycle ();





# Basic API test
foreach ( qw{new init reset next value list elements} ) {
	ok( Template::Plugin::Cycle->can( $_ ), "Template::Plugin::Cycle method '$_' exists" );
}




# Check that we can pass a context as the first argument
SCOPE: {
	my $Cycle1 = Template::Plugin::Cycle->new( 'foo', 'bar' );
	isa_ok( $Cycle1, 'Template::Plugin::Cycle' );
	my $Context = bless {}, 'Template::Context';
	isa_ok( $Context, 'Template::Context' );
	my $Cycle2 = Template::Plugin::Cycle->new( $Context, 'foo', 'bar' );
	isa_ok( $Cycle2, 'Template::Plugin::Cycle' );
	is( $Cycle1->elements, $Cycle2->elements, 'Context argument is correctly ignored' );
}





# Set up the main test objects
my @test_data = (
	[ []                 , 0 ],
	[ [qw{single}]       , 1 ],
	[ [qw{foo bar}]      , 2 ],
	[ [qw{one two three}], 3 ],
	);

# Additional custom instance-specific tests
my @Cycles = map { Template::Plugin::Cycle->new( @{$_->[0]} ) } @test_data;
ok( @Cycles == 4, "Four test items in test array" );

# Do some specific tests on the null form
my $Null = Template::Plugin::Cycle->new;
isa_ok( $Null, 'Template::Plugin::Cycle' );
my @nulllist = $Cycles[0]->list;
is_deeply( \@nulllist, [], '->list for null Cycle returns a null list' );
is( $Null->next, '', "->next returns '' for null list" );
is( $Null->value, '', "->value returns '' for null list" );
is( "$Null", '', "Stringification returns '' for null list" );
is( $Null->reset, '', "->reset returns '' for null list" );






# Do some basic tests on each cycle
foreach my $data ( @test_data ) {
	my $params = $data->[0];
	my $Cycle  = Template::Plugin::Cycle->new( @$params );
	ok( $Cycle, 'A cycle object is boolean true' );
	isa_ok( $Cycle, 'Template::Plugin::Cycle' );
	my $Cycle2 = Template::Plugin::Cycle->new();
	$Cycle2->init( @$params );

	# Is the number of elements correct
	is( $Cycle->elements, $data->[1], '->elements returns the correct number of elements' );

	# Do we get the same list back out?
	my @list = $Cycle->list;
	is_deeply( $data->[0], \@list, '->list retrieves the same list the Cycle was initialised with' );

	# Run a couple of cycles to make sure it returns values correctly
	if ( $data->[1] ) {
		my @testcycle    = (@{$data->[0]}) x 3;
		my @testresults1 = map { $Cycle->next  } (1 .. ($data->[1] * 3));
		my @testresults2 = map { $Cycle->value } (1 .. ($data->[1] * 3));
		my @testresults3 = map { "$Cycle" }      (1 .. ($data->[1] * 3));
		is_deeply( \@testcycle, \@testresults1, "->next returns values in the correct order" );
		is_deeply( \@testcycle, \@testresults2, "->value returns values in the correct order" );
		is_deeply( \@testcycle, \@testresults3, "Stringification returns values in the correct order" );		

		# Does reset work from every location within the set
		is( $Cycle->reset, '', '->reset returns a null string' );
		foreach my $p ( 0 .. $data->[1] ) {
			# Move to the position
			$Cycle->next foreach (1 .. ($p + 1));
			is( $Cycle->reset, '', "Reset return '' correctly at position $p" );
			is( $Cycle->next, $data->[0]->[0], '->next after reset returns the correct value' );
		}
	}

	# Initialise to different data
	is( $Cycle->init( 'a', 'b', 'c' ), '', "->init to different data works, and returns ''" );
	is( $Cycle->elements, 3, "->init returns the new correct ->elements value" );
	my @newlist = $Cycle->list;
	is_deeply( \@newlist, [ 'a', 'b', 'c' ], '->init returns the new correct ->list values' );
}
