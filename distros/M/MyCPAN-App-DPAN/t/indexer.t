#!perl

use strict;
use warnings;

use Test::More 'no_plan';

BEGIN { $INC{'Log/Log4perl.pm'} = 1; package Log::Log4perl; sub AUTOLOAD { __PACKAGE__ }; }

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
my $class = 'MyCPAN::App::DPAN::Indexer';
use_ok( $class );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
{
can_ok( $class, 'new' );
my $indexer = $class->new;
isa_ok( $indexer, $class );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
{
my @methods = qw(
	examine_dist_steps
	find_module_techniques
	get_module_info_tasks
	);
	
foreach my $method ( @methods )
	{
	can_ok( $class, $method );
	
	my @r = $class->$method();
	
	foreach my $item ( @r )
		{
		ok( ref $item eq ref [], "Item in $method is an array ref" );
		can_ok( $class, $item->[0] );
		ok( $item->[1], "There's a description for $item->[0] in $method" );
		}
	}
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
{
my $method = 'setup_run_info';
my $indexer = $class->new;
isa_ok( $indexer, $class );
can_ok( $indexer, $method );
can_ok( $class, 'set_run_info' );

$indexer->setup_run_info;

can_ok( $indexer, 'run_info' );

like( $indexer->run_info( 'pid' ), qr/^\d+$/, 'Pid looks like a number' );

}




# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
{
my @misc_methods = qw(_exit setup_run_info setup_dist_info);

foreach my $method ( @misc_methods )
	{
	can_ok( $class, $method );
	}

}
