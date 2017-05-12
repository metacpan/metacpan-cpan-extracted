use Test::More tests => 4;

my $no_tests = 0;
{
use_ok( 'Schedule::Pluggable' );
}
$no_tests++;
{
use_ok( 'Schedule::Pluggable', ( JobsPlugin=>JobsFromArray ) );
}
$no_tests++;
use_ok( 'Schedule::Pluggable', ( JobsPlugin=>JobsFromXML ) );
$no_tests++;
use_ok( 'Schedule::Pluggable', ( JobsPlugin=>JobsFromHash ) );
$no_tests++;
done_testing( $no_tests );
#diag( "Testing Schedule::Pluggable $Proc::Scheduler::VERSION" );
