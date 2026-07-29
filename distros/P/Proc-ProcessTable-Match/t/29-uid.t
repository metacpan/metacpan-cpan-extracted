#!perl
use 5.006;
use strict;
use warnings;
use Test::More;
use User::pwent;

use Proc::ProcessTable::Match::UID;
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

eval { $checker = Proc::ProcessTable::Match::UID->new( {} ); };
ok( $@, 'new dies when the uids key is missing' );

eval { $checker = Proc::ProcessTable::Match::UID->new( { uids => [] } ); };
ok( $@, 'new dies when the uids array is empty' );

#
# match, numeric
#

$checker = Proc::ProcessTable::Match::UID->new( { uids => [1000] } );

is( $checker->match( mock_process( uid => 1000 ) ), 1, 'exact numeric UID matches' );
is( $checker->match( mock_process( uid => 0 ) ),    0, 'differing numeric UID does not match' );
is( $checker->match( mock_process( pid => 1 ) ),    0, 'match returns 0 when the process has no uid' );

$checker = Proc::ProcessTable::Match::UID->new( { uids => ['>=1000'] } );
is( $checker->match( mock_process( uid => 1000 ) ), 1, "'>=1000' matches uid 1000" );
is( $checker->match( mock_process( uid => 999 ) ),  0, "'>=1000' does not match uid 999" );

#
# match, by username
#

SKIP: {
	my $root_pw = getpwnam('root');
	skip 'no root user on this system', 3 unless defined($root_pw);

	my $name_checker = Proc::ProcessTable::Match::UID->new( { uids => ['root'] } );
	is( $name_checker->match( mock_process( uid => $root_pw->uid ) ), 1, "username 'root' matches root's uid" );
	is( $name_checker->match( mock_process( uid => $root_pw->uid + 1 ) ),
		0, "username 'root' does not match a differing uid" );

	my $negated_name_checker = Proc::ProcessTable::Match::UID->new( { uids => ['!root'] } );
	is( $negated_name_checker->match( mock_process( uid => $root_pw->uid + 1 ) ),
		1, "'!root' matches a uid other than root's" );
}

#
# match, a nonexistent username never matches
#

my $bogus_name_checker
	= Proc::ProcessTable::Match::UID->new( { uids => ['thereisnosuchuserasthis'] } );
is( $bogus_name_checker->match( mock_process( uid => 0 ) ), 0, 'a nonexistent username does not match' );

done_testing();
