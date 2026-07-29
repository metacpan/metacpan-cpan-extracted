#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

use Proc::ProcessTable::Match::Cmndline;
use Proc::ProcessTable::Match::Command;
use Proc::ProcessTable::Match::Fname;
use Proc::ProcessTable::Match::State;
use Proc::ProcessTable::Match::WChan;
use Proc::ProcessTable::Process;

# Creates a mock Proc::ProcessTable::Process object. The accessors
# are provided via that module's AUTOLOAD, which maps method names
# to hash keys.
sub mock_process {
	my %process_fields = @_;
	return bless {%process_fields}, 'Proc::ProcessTable::Process';
}

# These checkers all match a single process field against a array
# of regexes.
my @regex_checkers = (
	{
		module      => 'Proc::ProcessTable::Match::Cmndline',
		args_key    => 'cmndlines',
		field       => 'cmndline',
		field_value => '/usr/local/bin/perl script.pl',
		hit_regex   => 'script\.pl$',
		miss_regex  => '^python',
	},
	{
		module      => 'Proc::ProcessTable::Match::Fname',
		args_key    => 'fnames',
		field       => 'fname',
		field_value => 'perl',
		hit_regex   => '^perl$',
		miss_regex  => '^python$',
	},
	{
		module      => 'Proc::ProcessTable::Match::State',
		args_key    => 'states',
		field       => 'state',
		field_value => 'sleep',
		hit_regex   => '^sleep$',
		miss_regex  => '^run$',
	},
	{
		module      => 'Proc::ProcessTable::Match::WChan',
		args_key    => 'wchans',
		field       => 'wchan',
		field_value => 'select',
		hit_regex   => '^select$',
		miss_regex  => '^wait$',
	},
);

foreach my $checker_info (@regex_checkers) {
	my $module   = $checker_info->{module};
	my $args_key = $checker_info->{args_key};
	my $field    = $checker_info->{field};

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

	eval { $checker = $module->new( { $args_key => ['(unclosed'] } ); };
	ok( $@, $module . ' new dies when a regex does not compile' );

	#
	# match
	#

	$checker = $module->new( { $args_key => [ $checker_info->{hit_regex} ] } );

	is( $checker->match(),                0, $module . ' match returns 0 for undef' );
	is( $checker->match('not a process'), 0, $module . ' match returns 0 for a non-process' );
	is( $checker->match( mock_process( pid => 1 ) ),
		0, $module . ' match returns 0 when the process lacks the ' . $field . ' field' );

	is( $checker->match( mock_process( $field => $checker_info->{field_value} ) ),
		1, $module . ' matching regex hits' );

	my $miss_checker = $module->new( { $args_key => [ $checker_info->{miss_regex} ] } );
	is( $miss_checker->match( mock_process( $field => $checker_info->{field_value} ) ),
		0, $module . ' non-matching regex misses' );

	my $multi_regex_checker
		= $module->new( { $args_key => [ $checker_info->{miss_regex}, $checker_info->{hit_regex} ] } );
	is( $multi_regex_checker->match( mock_process( $field => $checker_info->{field_value} ) ),
		1, $module . ' matching regex later in the array hits' );
}

#
# Command checks both fname and cmndline.
#

my $command_checker = Proc::ProcessTable::Match::Command->new( { commands => ['^perl$'] } );

is( $command_checker->match( mock_process( fname => 'perl', cmndline => '/usr/local/bin/perl script.pl' ) ),
	1, 'Command matches on fname' );

$command_checker = Proc::ProcessTable::Match::Command->new( { commands => ['script\.pl$'] } );
is( $command_checker->match( mock_process( fname => 'perl', cmndline => '/usr/local/bin/perl script.pl' ) ),
	1, 'Command matches on cmndline' );

$command_checker = Proc::ProcessTable::Match::Command->new( { commands => ['^python$'] } );
is( $command_checker->match( mock_process( fname => 'perl', cmndline => '/usr/local/bin/perl script.pl' ) ),
	0, 'Command misses when neither fname nor cmndline match' );

is( $command_checker->match( mock_process( pid => 1 ) ),
	0, 'Command returns 0 when the process has neither fname nor cmndline' );

eval { Proc::ProcessTable::Match::Command->new( {} ); };
ok( $@, 'Command new dies when the commands key is missing' );

eval { Proc::ProcessTable::Match::Command->new( { commands => ['(unclosed'] } ); };
ok( $@, 'Command new dies when a regex does not compile' );

done_testing();
