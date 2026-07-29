#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

use Proc::ProcessTable::Match::Time;
use Proc::ProcessTable::Process;

# Creates a mock Proc::ProcessTable::Process object. The accessors
# are provided via that module's AUTOLOAD, which maps method names
# to hash keys.
sub mock_process {
	my %process_fields = @_;
	return bless {%process_fields}, 'Proc::ProcessTable::Process';
}

# On Linux Proc::ProcessTable returns time in microseconds, which
# the checker converts to seconds, so the raw value used in the
# mock needs adjusting for that.
sub raw_time_for_seconds {
	my $seconds = $_[0];
	if ( $^O =~ /^linux$/ ) {
		return $seconds * 1000000;
	}
	return $seconds;
}

#
# new, error handling
#

my $checker;

eval { $checker = Proc::ProcessTable::Match::Time->new( {} ); };
ok( $@, 'new dies when the times key is missing' );

eval { $checker = Proc::ProcessTable::Match::Time->new( { times => [] } ); };
ok( $@, 'new dies when the times array is empty' );

#
# match
#

$checker = Proc::ProcessTable::Match::Time->new( { times => [5] } );

is( $checker->match( mock_process( time => raw_time_for_seconds(5) ) ), 1, 'exact time matches' );
is( $checker->match( mock_process( time => raw_time_for_seconds(6) ) ), 0, 'differing time does not match' );
is( $checker->match( mock_process( pid => 1 ) ), 0, 'match returns 0 when the process has no time' );

$checker = Proc::ProcessTable::Match::Time->new( { times => ['>60'] } );
is( $checker->match( mock_process( time => raw_time_for_seconds(120) ) ), 1, "'>60' matches 120 seconds" );
is( $checker->match( mock_process( time => raw_time_for_seconds(30) ) ),  0, "'>60' does not match 30 seconds" );

$checker = Proc::ProcessTable::Match::Time->new( { times => ['<=60'] } );
is( $checker->match( mock_process( time => raw_time_for_seconds(60) ) ),  1, "'<=60' matches 60 seconds" );
is( $checker->match( mock_process( time => raw_time_for_seconds(120) ) ), 0, "'<=60' does not match 120 seconds" );

done_testing();
