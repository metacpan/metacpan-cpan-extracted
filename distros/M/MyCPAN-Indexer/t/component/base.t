use utf8;
use strict;
use warnings;

use Test::More 'no_plan';

my $class = 'MyCPAN::Indexer::Component';
use_ok( $class );
can_ok( $class, 'new' );

my $base = $class->new;
isa_ok( $base, $class );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Non-composite types
{
my @types = qw( collator dispatcher indexer interface queue reporter worker );

foreach my $type ( @types )
	{
	my $method = "${type}_type";
	my $magic  = $base->$method();
	diag "type is " . sprintf( "%b", $magic ) if $ENV{DEBUG};
	my $check_method = "is_${type}_type";

	ok( $base->is_type( $magic, $base->$method ), "is_type is true for $type" );
	ok( $base->$check_method( $magic ), "$check_method is true for $type" );
	}
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Composite types
{
my @types = qw( collator dispatcher indexer interface queue reporter worker );

my @pairs = map {
	my $one = $_;
	map { [ $one, $_ ] } @types
	} @types;
	
foreach my $pair ( @pairs )
	{
	my( $m1, $m2 ) = map { "${_}_type" } @$pair;
	my $composite = $base->combine_types(
		$base->$m1(),
		$base->$m2(),
		);
	diag "1) $pair->[0] 2) $pair->[1] t) type is " 
		. sprintf( "%b", $composite ) if $ENV{DEBUG};
		
	foreach my $type ( @$pair )
		{
		my $method = "is_${type}_type";
		diag "method is $method" if $ENV{DEBUG};
		ok( $base->$method( $composite ), "Combined (@$pair) is a $type" );
		}
	
	}

}

1;
