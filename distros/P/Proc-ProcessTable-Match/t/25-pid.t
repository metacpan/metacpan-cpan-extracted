#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

use Proc::ProcessTable::Match::PID;
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

eval { $checker = Proc::ProcessTable::Match::PID->new(); };
ok( $@, 'new dies when no argument hash is given' );

eval { $checker = Proc::ProcessTable::Match::PID->new( {} ); };
ok( $@, 'new dies when the pids key is missing' );

eval { $checker = Proc::ProcessTable::Match::PID->new( { pids => 'not a array' } ); };
ok( $@, 'new dies when pids is not a array' );

eval { $checker = Proc::ProcessTable::Match::PID->new( { pids => [] } ); };
ok( $@, 'new dies when the pids array is empty' );

#
# match, bad objects
#

$checker = Proc::ProcessTable::Match::PID->new( { pids => [42] } );

is( $checker->match(),                0, 'match returns 0 for undef' );
is( $checker->match('not a process'), 0, 'match returns 0 for a non-process' );
is( $checker->match( mock_process( uid => 0 ) ), 0, 'match returns 0 when the process has no pid' );

#
# match, exact values
#

is( $checker->match( mock_process( pid => 42 ) ), 1, 'exact PID matches' );
is( $checker->match( mock_process( pid => 43 ) ), 0, 'differing PID does not match' );

#
# match, equalities
#

my %equality_tests = (
	'<=42' => { 42 => 1, 41 => 1, 43 => 0 },
	'<42'  => { 41 => 1, 42 => 0 },
	'>=42' => { 42 => 1, 43 => 1, 41 => 0 },
	'>42'  => { 43 => 1, 42 => 0 },
	'!42'  => { 43 => 1, 42 => 0 },
);

foreach my $equality ( sort keys %equality_tests ) {
	my $equality_checker = Proc::ProcessTable::Match::PID->new( { pids => [$equality] } );
	foreach my $test_pid ( sort { $a <=> $b } keys %{ $equality_tests{$equality} } ) {
		my $expected_result = $equality_tests{$equality}{$test_pid};
		is( $equality_checker->match( mock_process( pid => $test_pid ) ),
			$expected_result, "'" . $equality . "' vs pid " . $test_pid );
	}
}

#
# match, multiple values in the array
#

my $multi_value_checker = Proc::ProcessTable::Match::PID->new( { pids => [ 1, 2, '>9000' ] } );
is( $multi_value_checker->match( mock_process( pid => 2 ) ),    1, 'second value in the pids array matches' );
is( $multi_value_checker->match( mock_process( pid => 9001 ) ), 1, 'equality later in the pids array matches' );
is( $multi_value_checker->match( mock_process( pid => 5 ) ),    0, 'pid matching none of the array does not match' );

done_testing();
