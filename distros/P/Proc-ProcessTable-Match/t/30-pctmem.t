#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

use Proc::ProcessTable::Match::PctMem;
use Proc::ProcessTable::Process;

# Creates a mock Proc::ProcessTable::Process object. The accessors
# are provided via that module's AUTOLOAD, which maps method names
# to hash keys.
sub mock_process {
	my %process_fields = @_;
	return bless {%process_fields}, 'Proc::ProcessTable::Process';
}

#
# new, error handling
#

my $checker;

eval { $checker = Proc::ProcessTable::Match::PctMem->new( {} ); };
ok( $@, 'new dies when the pctmems key is missing' );

eval { $checker = Proc::ProcessTable::Match::PctMem->new( { pctmems => [] } ); };
ok( $@, 'new dies when the pctmems array is empty' );

#
# match, using the pctmem method directly
#

$checker = Proc::ProcessTable::Match::PctMem->new( { pctmems => ['2.5'] } );

is( $checker->match( mock_process( pctmem => 2.5 ) ), 1, 'exact pctmem matches' );
is( $checker->match( mock_process( pctmem => 3 ) ),   0, 'differing pctmem does not match' );

$checker = Proc::ProcessTable::Match::PctMem->new( { pctmems => ['>=2.5'] } );
is( $checker->match( mock_process( pctmem => 2.5 ) ), 1, "'>=2.5' matches pctmem 2.5" );
is( $checker->match( mock_process( pctmem => 5 ) ),   1, "'>=2.5' matches pctmem 5" );
is( $checker->match( mock_process( pctmem => 1 ) ),   0, "'>=2.5' does not match pctmem 1" );

$checker = Proc::ProcessTable::Match::PctMem->new( { pctmems => ['<0.1'] } );
is( $checker->match( mock_process( pctmem => 0.05 ) ), 1, "'<0.1' matches pctmem 0.05" );
is( $checker->match( mock_process( pctmem => 0.5 ) ),  0, "'<0.1' does not match pctmem 0.5" );

#
# match, falling back onto rss/physmem when pctmem is not available
#

SKIP: {
	my $physmem_checker = Proc::ProcessTable::Match::PctMem->new( { pctmems => ['>=50'] } );
	skip 'could not determine the physical memory size', 2
		unless defined( $physmem_checker->{physmem} );

	my $rss_over_half = int( $physmem_checker->{physmem} * 0.75 );
	is( $physmem_checker->match( mock_process( rss => $rss_over_half ) ),
		1, 'rss fallback matches when the computed pctmem hits' );
	is( $physmem_checker->match( mock_process( rss => 0 ) ),
		0, 'rss fallback does not match when the computed pctmem misses' );
}

done_testing();
