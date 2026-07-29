#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

use Proc::ProcessTable::Match;
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

my $matcher;

eval { $matcher = Proc::ProcessTable::Match->new(); };
ok( $@, 'new dies when no argument hash is given' );

eval { $matcher = Proc::ProcessTable::Match->new( {} ); };
ok( $@, 'new dies when the checks key is missing' );

eval { $matcher = Proc::ProcessTable::Match->new( { checks => 'not an array' } ); };
ok( $@, 'new dies when checks is not a array' );

eval { $matcher = Proc::ProcessTable::Match->new( { checks => [] } ); };
ok( $@, 'new dies when the checks array is empty' );

eval { $matcher = Proc::ProcessTable::Match->new( { checks => ['not a hash'] } ); };
ok( $@, 'new dies when the first check is not a hash' );

eval { $matcher = Proc::ProcessTable::Match->new( { checks => [ { args => {} } ] } ); };
ok( $@, 'new dies when a check has no type' );

eval {
	$matcher = Proc::ProcessTable::Match->new(
		{ checks => [ { type => 'PID; system("true")', args => { pids => [42] } } ] } );
};
ok( $@, 'new dies when the type contains invalid characters' );

eval { $matcher = Proc::ProcessTable::Match->new( { checks => [ { type => 'PID' } ] } ); };
ok( $@, 'new dies when a check has no args' );

eval {
	$matcher = Proc::ProcessTable::Match->new( { checks => [ { type => 'PID', args => 'not a hash' } ] } );
};
ok( $@, 'new dies when the args for a check is not a hash' );

eval {
	$matcher = Proc::ProcessTable::Match->new(
		{ checks => [ { type => 'PID', args => { pids => [42] }, invert => [] } ] } );
};
ok( $@, 'new dies when invert is not a scalar' );

eval {
	$matcher = Proc::ProcessTable::Match->new(
		{ checks => [ { type => 'ThereIsNoSuchCheckerAsThis', args => {} } ] } );
};
ok( $@, 'new dies when the checker module does not exist' );

#
# new, valid usage
#

$matcher = undef;
eval {
	$matcher = Proc::ProcessTable::Match->new( { checks => [ { type => 'PID', args => { pids => [42] } } ] } );
};
ok( !$@,               'new works with a valid single check' ) or diag($@);
ok( defined($matcher), 'new returned a defined object' );
isa_ok( $matcher, 'Proc::ProcessTable::Match' );

#
# match, error handling
#

eval { $matcher->match(); };
ok( $@, 'match dies when given nothing' );

eval { $matcher->match('not a process object'); };
ok( $@, 'match dies when given something other than a Proc::ProcessTable::Process' );

#
# match, single check
#

my $matching_process     = mock_process( pid => 42 );
my $non_matching_process = mock_process( pid => 43 );

is( $matcher->match($matching_process),     1, 'match returns 1 when the single check hits' );
is( $matcher->match($non_matching_process), 0, 'match returns 0 when the single check misses' );

#
# match, invert
#

my $inverted_matcher = Proc::ProcessTable::Match->new(
	{ checks => [ { type => 'PID', invert => 1, args => { pids => [42] } } ] } );

is( $inverted_matcher->match($matching_process),     0, 'invert flips a hit to a miss' );
is( $inverted_matcher->match($non_matching_process), 1, 'invert flips a miss to a hit' );

#
# match, multiple checks must all hit
#

my $multi_check_matcher = Proc::ProcessTable::Match->new(
	{
		checks => [
			{ type => 'PID', invert => 0, args => { pids => [42] } },
			{ type => 'UID', invert => 0, args => { uids => [1000] } },
		]
	}
);

my $process_matching_both = mock_process( pid => 42, uid => 1000 );
my $process_matching_one  = mock_process( pid => 42, uid => 0 );
my $process_matching_none = mock_process( pid => 1,  uid => 0 );

is( $multi_check_matcher->match($process_matching_both), 1, 'match returns 1 when all checks hit' );
is( $multi_check_matcher->match($process_matching_one),  0, 'match returns 0 when only one check hits' );
is( $multi_check_matcher->match($process_matching_none), 0, 'match returns 0 when no checks hit' );

done_testing();
