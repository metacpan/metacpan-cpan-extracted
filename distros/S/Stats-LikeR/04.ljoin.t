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
#-------
# ljoin
#-------
$data = { 'Jack Smith' => { age => 30 } };
$n = { 'Jack Smith' => { dept => 'Engineering' }, 'Jane Doe' => { age => 25 } };

ljoin($data, $n);
$size = scalar keys %{ $data };
if ($size == 1) {
	pass('ljoin: only 1 key in $data');
} else {
	fail("ljoin: should have 1 key, but has $size keys");
}
if (defined $data->{'Jack Smith'}) {
	pass('ljoin: correct key is defined');
} else {
	fail('ljoin: correct key is NOT defined');
}
foreach my $key ('age', 'dept') {
	if (defined $data->{'Jack Smith'}{$key}) {
		pass("ljoin: \"$key\" is defined");
	} else {
		fail("ljoin: \"$key\" is NOT defined");
	}
}
if (
	(abs($data->{'Jack Smith'}{age} - 30) < 1e-13)
	&&
	($data->{'Jack Smith'}{dept} eq 'Engineering')
	) {
	pass('ljoin: values are correct');
} else {
	fail('ljoin: values are NOT correct');
}
# --- Test: Hash of Arrays support in secondary hash ---
$data = { 'Sarah Connor' => { role => 'Leader' } };
$n    = { 'Sarah Connor' => [ 'status', 'Active', 'target', 'Skynet' ] };

ljoin($data, $n);

if (defined $data->{'Sarah Connor'}{status} && $data->{'Sarah Connor'}{status} eq 'Active') {
	pass('ljoin (HoA): "status" key from array is defined and correct');
} else {
	fail('ljoin (HoA): "status" key from array is NOT correct');
}

if (defined $data->{'Sarah Connor'}{target} && $data->{'Sarah Connor'}{target} eq 'Skynet') {
	pass('ljoin (HoA): "target" key from array is defined and correct');
} else {
	fail('ljoin (HoA): "target" key from array is NOT correct');
}
# --- Test: Overwriting existing columns ---
$data = { 'Bob Brown' => { score => 50, active => 1 } };
$n    = { 'Bob Brown' => { score => 99 } };

ljoin($data, $n);

if (abs($data->{'Bob Brown'}{score} - 99) < 1e-13) {
	pass('ljoin: existing column value is overwritten correctly');
} else {
	fail('ljoin: existing column value was NOT overwritten');
}

if (defined $data->{'Bob Brown'}{active} && (abs($data->{'Bob Brown'}{active} - 1) < 1e-13)) {
	pass('ljoin: untouched existing column remains intact');
} else {
	fail('ljoin: untouched existing column was lost or modified');
}
# --- Test: Invalid inner structures (Segfault protection) ---
$data = { 'Eve' => 'Just a string, not a hash' };
$n    = { 'Eve' => { status => 'Online' } };

# If the XS is unsafe, the next line will immediately segfault and kill the test script.
ljoin($data, $n);

if (!ref($data->{'Eve'}) && $data->{'Eve'} eq 'Just a string, not a hash') {
	pass('ljoin: gracefully ignores rows where primary value is a string');
} else {
	fail('ljoin: improperly modified a non-reference row value');
}
done_testing();
