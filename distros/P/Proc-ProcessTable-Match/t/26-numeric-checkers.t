#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

use Proc::ProcessTable::Process;

# Creates a mock Proc::ProcessTable::Process object. The accessors
# are provided via that module's AUTOLOAD, which maps method names
# to hash keys.
sub mock_process {
	my %process_fields = @_;
	return bless {%process_fields}, 'Proc::ProcessTable::Process';
}

# All of these checkers share the same numeric match logic, just
# with differing argument keys and process fields.
my @numeric_checkers = (
	{ module => 'EGID',     args_key => 'egids',      field => 'egid' },
	{ module => 'EUID',     args_key => 'euids',      field => 'euid' },
	{ module => 'GID',      args_key => 'gids',       field => 'gid' },
	{ module => 'JID',      args_key => 'jids',       field => 'jid' },
	{ module => 'PctCPU',   args_key => 'pctcpus',    field => 'pctcpu' },
	{ module => 'Priority', args_key => 'priorities', field => 'priority' },
	{ module => 'RSS',      args_key => 'rss',        field => 'rss' },
	{ module => 'Size',     args_key => 'sizes',      field => 'size' },
	{ module => 'Start',    args_key => 'starts',     field => 'start' },
);

foreach my $checker_info (@numeric_checkers) {
	my $module   = 'Proc::ProcessTable::Match::' . $checker_info->{module};
	my $args_key = $checker_info->{args_key};
	my $field    = $checker_info->{field};

	use_ok($module) or next;

	#
	# new, error handling
	#

	my $checker;

	eval { $checker = $module->new(); };
	ok( $@, $module . ' new dies when no argument hash is given' );

	eval { $checker = $module->new( {} ); };
	ok( $@, $module . ' new dies when the ' . $args_key . ' key is missing' );

	eval { $checker = $module->new( { $args_key => 'not a array' } ); };
	ok( $@, $module . ' new dies when ' . $args_key . ' is not a array' );

	eval { $checker = $module->new( { $args_key => [] } ); };
	ok( $@, $module . ' new dies when the ' . $args_key . ' array is empty' );

	#
	# match
	#

	$checker = $module->new( { $args_key => [42] } );

	is( $checker->match(),                0, $module . ' match returns 0 for undef' );
	is( $checker->match('not a process'), 0, $module . ' match returns 0 for a non-process' );
	is( $checker->match( mock_process( pid => 1 ) ),
		0, $module . ' match returns 0 when the process lacks the ' . $field . ' field' );

	is( $checker->match( mock_process( $field => 42 ) ), 1, $module . ' exact value matches' );
	is( $checker->match( mock_process( $field => 43 ) ), 0, $module . ' differing value does not match' );

	my %equality_tests = (
		'<=42' => { 42 => 1, 41 => 1, 43 => 0 },
		'<42'  => { 41 => 1, 42 => 0 },
		'>=42' => { 42 => 1, 43 => 1, 41 => 0 },
		'>42'  => { 43 => 1, 42 => 0 },
		'!42'  => { 43 => 1, 42 => 0 },
	);

	foreach my $equality ( sort keys %equality_tests ) {
		my $equality_checker = $module->new( { $args_key => [$equality] } );
		foreach my $test_value ( sort { $a <=> $b } keys %{ $equality_tests{$equality} } ) {
			my $expected_result = $equality_tests{$equality}{$test_value};
			is( $equality_checker->match( mock_process( $field => $test_value ) ),
				$expected_result, $module . " '" . $equality . "' vs " . $field . ' ' . $test_value );
		}
	}
}

done_testing();
