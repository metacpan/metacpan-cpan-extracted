#!/usr/bin/perl
use strict;
use warnings;

use Test::More;

my $class = "SourceCode::LineCounter::Perl";
my @methods = qw( 
	_total total
	);

use_ok( $class );
can_ok( $class, @methods );

my $counter = $class->new;
isa_ok( $counter, $class );
can_ok( $counter, @methods );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Test things that should be code, no comments 
{
is( $counter->total, 0, "No lines yet" );

my @tests = (
	'my $x = 0;',
	'foreach my $test ( qw#a b c# ) { 1; }',
	'',
	"\n",
	"#cooment",
	"=pod",
	"=cut",
	);

foreach my $line ( @tests )
	{
	ok( $counter->_total( \$line ), "_total works for [$line]" );
	}

is( $counter->total,  scalar @tests, "Right number of lines so far" );
}

done_testing();
