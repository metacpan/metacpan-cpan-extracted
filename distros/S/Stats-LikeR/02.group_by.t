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
dies_ok {
	group_by('not a data ref', 'a', 'b');
} 'group_by: dies when data is not a data reference';
#
# TEST SET 1: Array of Hashes (AoH)
#
my $aoh_data = [
 { 'Gender' => 'Male',   'Testosterone, total (nmol/L)' => 20.5 },
 { 'Gender' => 'Female', 'Testosterone, total (nmol/L)' => 1.8 },
 { 'Gender' => 'Male',   'Testosterone, total (nmol/L)' => 18.2 },
 { 'Gender' => 'Female' } # Intentional missing target value
];

my $res1 = group_by($aoh_data, 'Testosterone, total (nmol/L)', 'Gender');

if (scalar keys %{ $res1 } == 2) {
	pass('group_by (AoH): correct number of group keys created');
} else {
	fail('group_by (AoH): incorrect number of group keys');
}

if (scalar @{ $res1->{'Male'} } == 2 &&
(abs($res1->{'Male'}[0] - 20.5) < 1e-13) &&
(abs($res1->{'Male'}[1] - 18.2) < 1e-13)
){
	pass('group_by (AoH): Male target values grouped correctly');
} else {
	fail('group_by (AoH): Male target values NOT grouped correctly');
}

if (scalar @{ $res1->{'Female'} } == 1 && abs($res1->{'Female'}[0] - 1.8) < 1e-13) {
	pass('group_by (AoH): Female target values grouped correctly (including undef values)');
} else {
	fail('group_by (AoH): Female target values NOT grouped correctly');
}
no_leaks_ok {
	eval {
		group_by($aoh_data, 'Testosterone, total (nmol/L)', 'Gender')
	};
} 'group_by: no leaks with Array of hashes input' unless $INC{'Devel/Cover.pm'};
#
# TEST SET 2: Hash of Arrays (HoA)
#
my $hoa_data = {
	'Gender'                       => ['Male', 'Female', 'Male', 'Female'],
	'Testosterone, total (nmol/L)' => [22.1,   2.5,      19.4,   undef   ]
};

my $res2 = group_by($hoa_data, 'Testosterone, total (nmol/L)', 'Gender');

no_leaks_ok {
	eval {
		group_by($hoa_data, 'Testosterone, total (nmol/L)', 'Gender')
	};
} 'group_by: no leaks with Hash of arrays input' unless $INC{'Devel/Cover.pm'};
if (scalar keys %$res2 == 2) {
	pass('group_by (HoA): correct number of group keys created');
} else {
	fail('group_by (HoA): incorrect number of group keys');
}

if (scalar @{ $res2->{'Male'} } == 2
&& abs($res2->{'Male'}[0] - 22.1) < 1e-13
&& abs($res2->{'Male'}[1] - 19.4) < 1e-13) {
	pass('group_by (HoA): Male target values grouped correctly');
} else {
	fail('group_by (HoA): Male target values NOT grouped correctly');
}

if (!defined $res2->{'Female'}[1]) {
	pass('group_by (HoA): gracefully handled undefined target arrays element');
} else {
	fail('group_by (HoA): failed to handle undefined target array element');
}
# ==========================================
# TEST SET 3: Hash of Hashes (HoH)
# ==========================================
$test_data = {
 'Patient_A' => { 'Gender' => 'Male',   'Testosterone, total (nmol/L)' => 20.5 },
 'Patient_B' => { 'Gender' => 'Female', 'Testosterone, total (nmol/L)' => 1.8 },
 'Patient_C' => { 'Gender' => 'Male',   'Testosterone, total (nmol/L)' => 18.2 },
 'Patient_D' => { 'Gender' => 'Female' }, # Intentional missing target value
 'Patient_E' => { 'Gender' => 'Female', 'Testosterone, total (nmol/L)' => undef } # Explicit undef
};

my $res3 = group_by($test_data, 'Testosterone, total (nmol/L)', 'Gender');

if (scalar keys %$res3 == 2) {
	pass('group_by (HoH): correct number of group keys created');
} else {
	fail('group_by (HoH): incorrect number of group keys');
}

# Sort the array to protect the test against randomized hash iteration order
my @males = sort { $a <=> $b } @{ $res3->{'Male'} };

if (scalar @males == 2 && $males[0] == 18.2 && abs($males[1] - 20.5) < 1e-13) {
	pass('group_by (HoH): Male target values grouped correctly');
} else {
	fail('group_by (HoH): Male target values NOT grouped correctly');
}

my @females = @{ $res3->{'Female'} };

if (scalar @females == 1 && abs($females[0] - 1.8) < 1e-13) {
	pass('group_by (HoH): Female target correctly handled missing and undef values');
} else {
	fail('group_by (HoH): Female target improperly included undefined/missing values');
}
no_leaks_ok {
	eval {
		group_by($test_data, 'Testosterone, total (nmol/L)', 'Gender')
	};
} 'group_by: no leaks with Hash of hash input' unless $INC{'Devel/Cover.pm'};
#
# TEST SET 4: Group By with Code Filters
#

# Data representing males and females, where we only want to keep Sex => 'f'
$test_data = [
 { 'Gender' => 'Group 1', 'Sex' => 'm', 'Testosterone' => 20.5 },
 { 'Gender' => 'Group 1', 'Sex' => 'f', 'Testosterone' => 1.8 },
 { 'Gender' => 'Group 2', 'Sex' => 'm', 'Testosterone' => 18.2 },
 { 'Gender' => 'Group 2', 'Sex' => 'f', 'Testosterone' => 2.1 }
];

$test_data = group_by($test_data, 'Testosterone', 'Gender', { Sex => sub { $_ eq 'f' } });

# Verification: Only 1 item should exist in each group array (the females)
if (scalar @{ $test_data->{'Group 1'} } == 1 && abs($test_data->{'Group 1'}[0] - 1.8) < 1e-13) {
	pass('group_by (filter AoH): successfully evaluated $_ eq "f" and filtered out Group 1 Male');
} else {
	fail('group_by (filter AoH): failed to filter Group 1');
}

if (scalar @{ $test_data->{'Group 2'} } == 1 && abs($test_data->{'Group 2'}[0] - 2.1) < 1e-13) {
	pass('group_by (filter AoH): successfully evaluated $_ eq "f" and filtered out Group 2 Male');
} else {
	fail('group_by (filter AoH): failed to filter Group 2');
}

$test_data = {
 'Gender'       => [ 'Group 1', 'Group 1', 'Group 2', 'Group 2' ],
 'Sex'          => [ 'm',       'f',       'm',       'f'       ],
 'Testosterone' => [ 20.5,      1.8,       18.2,      2.1       ]
};

$test_data = group_by($test_data, 'Testosterone', 'Gender', { Sex => sub { $_ eq 'f' } });

if (scalar @{ $test_data->{'Group 1'} } == 1 && abs($test_data->{'Group 1'}[0] - 1.8) < 1e-13) {
	pass('group_by (filter HoA): successfully evaluated $_ eq "f" and filtered HoA columns');
} else {
	fail('group_by (filter HoA): failed to filter HoA array parallelly');
}
no_leaks_ok {
	eval {
		group_by($test_data, 'Testosterone', 'Gender', { Sex => sub { $_ eq 'f' } });
	};
} 'group_by: no leaks with filter' unless $INC{'Devel/Cover.pm'};
done_testing();
