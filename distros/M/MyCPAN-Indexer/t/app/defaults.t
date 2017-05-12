#!/usr/bin/perl

use Test::More 'no_plan';

my $method  = 'default';


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# DPAN should get the value through the call to SUPER
{
my $setting = 'alarm';
my $value   = 15;

foreach my $class ( map { "MyCPAN::App::$_" } qw( BackPAN::Indexer ) )
	{
	use_ok( $class );
	can_ok( $class, $method );
	is( $class->$method( $setting ), $value, "$setting in $class right" );
	}
}


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# DPAN should get the value from its own class
{
my $setting = 'indexer_class';

is( MyCPAN::App::BackPAN::Indexer->$method( $setting ), 'MyCPAN::Indexer',
	"$setting in MyCPAN::App::BackPAN::Indexer is right" );

}
