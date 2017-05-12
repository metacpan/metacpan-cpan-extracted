# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# tests that the load function is called, and triggers a sleep

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 5;
#use Test::More qw(no_plan);

# test 1
BEGIN { use_ok( 'Proc::NiceSleep' ); }

#setup
use vars qw( $load_function_was_called );
$load_function_was_called = 0;

sub my_load_function { 
	#warn "$0: load function called!\n";
	$load_function_was_called++;
	return (2,2,2);
}

Proc::NiceSleep::max_load( 1.9 );
Proc::NiceSleep::sleep_factor( 0.01 );
Proc::NiceSleep::min_run_time( 0 );
Proc::NiceSleep::over_load_min_sleep_time( 0.01 );
Proc::NiceSleep::over_load_sleep_drift( 0.01 );
Proc::NiceSleep::load_function( \&main::my_load_function );
Proc::NiceSleep::over_load_sleep_drift( 0 );

# test 2
my $got_load_function = Proc::NiceSleep::load_function();	# fetch it
ok($got_load_function eq \&main::my_load_function, "my_load_function loaded");

# test 3
my @loaded_loads = &$got_load_function();
ok ($loaded_loads[0] == 2, "load_function returns results");
$load_function_was_called = 0;	# reset it for testing

# tests 4-5
my $slept = Proc::NiceSleep::maybe_sleep();
ok($slept > 0, "did_sleep (slept $slept)");
ok($load_function_was_called > 0, "function_called");

#warn Proc::NiceSleep::DumpText(); 	# for kicks

# Various ways to say "ok"
#ok($this eq $that, $test_name);
#is  ($this, $that,    $test_name);
#isnt($this, $that,    $test_name);



