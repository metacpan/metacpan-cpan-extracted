#!/usr/bin/env perl

require 5.010;
use warnings FATAL => 'all';
use feature 'say';
use Digest::SHA 'sha512_base64';
use File::Temp;
use Scalar::Util 'looks_like_number';
use Stats::LikeR;
use Test::Exception; # die_ok
use Test::More;
use Test::LeakTrace 'no_leaks_ok';

# Gemini helped to write some of the tests
# Custom helper for floating-point comparisons
sub is_approx {
	my ($got, $expected, $test_name, $epsilon) = @_;
	$epsilon = 1e-7 if not defined $epsilon;
	my $current_sub = ( split( /::/, ( caller(0) )[3] ) )[-1];
	my $i = 0;
	foreach my $arg ($got, $expected, $test_name) {
		next if defined $arg;
		die "\$arg[$i] (see subroutine signature for name) isn't defined in $current_sub";
		$i++;
	}
	my $diff = abs($got - $expected);
	if ($diff <= $epsilon) {
		pass("$test_name: within $epsilon");
		return 1;
	} else {
		fail($test_name);
		diag("         got: $got\n    expected: $expected; diff = $diff");
		return 0;
	}
}
#---------
# add_data
#---------
$data = { 'Jack Smith' => { age => 30 } };
$n = { 
    'Jack Smith' => { dept => 'Engineering' },             # Update existing (Hash)
    'Jane Doe'   => { age => 25, dept => 'Sales' },        # Add new (Hash)
    'Bob Brown'  => [ 'age', 40, 'dept', 'IT' ],           # Add new (Array)
    'Invalid'    => 'Not a reference'                      # Edge case safety
};

add_data($data, $n);

# --- Test 1: Total key count ---
$size = scalar keys %{ $data };
if ($size == 3) {
    pass('add_data: correct number of keys (3) in $data');
} else {
    fail("add_data: should have 3 keys, but has $size keys");
}

# --- Test 2: Existing row updated correctly ---
if (defined $data->{'Jack Smith'} && 
    (abs($data->{'Jack Smith'}{age} - 30) < 1e-13) && 
    $data->{'Jack Smith'}{dept} eq 'Engineering') {
    pass('add_data: existing row updated correctly');
} else {
    fail('add_data: existing row was NOT updated correctly');
}

# --- Test 3: New row added from Hash ---
if (defined $data->{'Jane Doe'}) {
	pass('add_data: new row from hash is defined');
	if ((abs($data->{'Jane Doe'}{age} - 25) < 1e-13) && $data->{'Jane Doe'}{dept} eq 'Sales') {
		pass('add_data: new row from hash has correct values');
	} else {
		fail('add_data: new row from hash has INCORRECT values');
	}
} else {
    fail('add_data: new row from hash is NOT defined');
}

# --- Test 4: New row added from Array ---
if (defined $data->{'Bob Brown'}) {
	pass('add_data: new row from array is defined');
	if ((abs($data->{'Bob Brown'}{age} - 40) < 1e-13) && $data->{'Bob Brown'}{dept} eq 'IT') {
		pass('add_data: new row from array has correct values');
	} else {
		fail('add_data: new row from array has INCORRECT values');
	}
} else {
	fail('add_data: new row from array is NOT defined');
}

# --- Test 5: Safety check for invalid inner data ---
if (!defined $data->{'Invalid'}) {
	pass('add_data: gracefully skipped non-reference data without crashing');
} else {
	fail('add_data: improperly added a row for non-reference data');
}
done_testing();
