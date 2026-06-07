#!/usr/bin/env perl

require 5.010;
use warnings FATAL => 'all';
use Stats::LikeR; # Adjust this if add_data is exported from a different module
use Test::Exception; # dies_ok
use Test::More;
use Test::LeakTrace 'no_leaks_ok';

# 1. Input Validation Tests
dies_ok {
	add_data(undef, {});
} 'add_data: dies with undefined first argument';

dies_ok {
	add_data({}, "string");
} 'add_data: dies with scalar for second argument';

# 2. Hash of Hashes (HoH) Merging
my $h_hoh = { A => { 'x' => 1 } };
my $i_hoh = { A => { 'y' => 2 }, B => { z => 3 } };

add_data($h_hoh, $i_hoh);

my $n = scalar keys %{ $h_hoh };
if ($n == 2) {
	pass('add_data (HoH): has the correct # of primary hash keys');
} else {
	fail("add_data (HoH): has $n primary hash keys, when it should have 2");
}

if (defined $h_hoh->{A}{'x'} && defined $h_hoh->{A}{y}) {
	pass('add_data (HoH): correctly merged keys into existing row');
} else {
	fail('add_data (HoH): failed to merge keys into existing row');
}

if (defined $h_hoh->{B}{z}) {
	pass('add_data (HoH): correctly created new row from secondary hash');
} else {
	fail('add_data (HoH): failed to create new row');
}

no_leaks_ok {
	my $h_test = { A => { 'x' => 1 } };
	my $i_test = { A => { 'y' => 2 }, B => { z => 3 } };
	add_data($h_test, $i_test);
} 'add_data: no leaks when merging Hash of Hashes' unless $INC{'Devel/Cover.pm'};

# 3. Hash of Arrays (HoA) Merging (New Functionality)
my $h_hoa = { A => [1, 2] };
my $i_hoa = { A => [3, 4], B => [5] };

add_data($h_hoa, $i_hoa);

$n = scalar keys %{ $h_hoa };
if ($n == 2) {
	pass('add_data (HoA): has the correct # of primary hash keys');
} else {
	fail("add_data (HoA): has $n primary hash keys, when it should have 2");
}

my $a_len = scalar @{ $h_hoa->{A} };
if ($a_len == 4) {
	pass('add_data (HoA): correctly appended elements to existing array row');
} else {
	fail("add_data (HoA): existing array has $a_len elements, should have 4");
}

my $b_len = scalar @{ $h_hoa->{B} };
if ($b_len == 1 && $h_hoa->{B}[0] == 5) {
	pass('add_data (HoA): correctly created new array row from secondary hash');
} else {
	fail('add_data (HoA): failed to properly create new array row');
}

no_leaks_ok {
	my $h_test = { A => [1, 2] };
	my $i_test = { A => [3, 4], B => [5] };
	add_data($h_test, $i_test);
} 'add_data: no leaks when merging Hash of Arrays' unless $INC{'Devel/Cover.pm'};

# 4. Target Inference (Empty Target Hash)
my $h_empty_hoa = {};
my $i_source_hoa = { X => [9, 10] };

add_data($h_empty_hoa, $i_source_hoa);

if (ref($h_empty_hoa->{X}) eq 'ARRAY') {
	pass('add_data (Inference): correctly inferred HoA intent from empty target');
} else {
	fail("add_data (Inference): failed to infer HoA intent, created " . ref($h_empty_hoa->{X}) . " instead");
}

my $h_empty_hoh = {};
my $i_source_hoh = { Y => { k => 'v' } };

add_data($h_empty_hoh, $i_source_hoh);

if (ref($h_empty_hoh->{Y}) eq 'HASH') {
	pass('add_data (Inference): correctly inferred HoH intent from empty target');
} else {
	fail("add_data (Inference): failed to infer HoH intent, created " . ref($h_empty_hoh->{Y}) . " instead");
}

no_leaks_ok {
	my $h_test = {};
	my $i_test = { X => [9, 10] };
	add_data($h_test, $i_test);
} 'add_data: no leaks during empty target inference' unless $INC{'Devel/Cover.pm'};

# 5. Legacy Fallback (Target is HoH, Source row is Array)
my $h_legacy = { A => { key1 => 'val1' } };
my $i_legacy = { A => [ key2 => 'val2', key3 => 'val3' ] }; # Array acting as kv pairs

add_data($h_legacy, $i_legacy);

if (defined $h_legacy->{A}->{key2} && $h_legacy->{A}->{key3} eq 'val3') {
	pass('add_data (Legacy): correctly processed array as key-value pairs for HoH target');
} else {
	fail('add_data (Legacy): failed to process array as key-value pairs');
}
# 6. Cross-Merging (Mixed Types Coerced to Target Structure)

# 6a. Target is HoA, Source is HoH
my $h_target_hoa = { A => [ 'k1', 'v1' ] };
$i_source_hoh = { A => { k2 => 'v2' }, B => { k3 => 'v3' } };

add_data($h_target_hoa, $i_source_hoh);

if (ref($h_target_hoa->{B}) eq 'ARRAY') {
	pass('add_data (Cross-Merge): output matches structure of h_ref (HoA created)');
} else {
	fail('add_data (Cross-Merge): output failed to match HoA structure of h_ref');
}

# Checking the array acting as k/v pairs (hash keys are unordered, check length)
my $a_len_hoa = scalar @{ $h_target_hoa->{A} };
if ($a_len_hoa == 4) {
	pass('add_data (Cross-Merge): correctly flattened/pushed hash keys and values into existing HoA row');
} else {
	fail("add_data (Cross-Merge): expected 4 elements in HoA row A, got $a_len_hoa");
}

my $b_len_hoa = scalar @{ $h_target_hoa->{B} };
if ($b_len_hoa == 2) {
	pass('add_data (Cross-Merge): correctly flattened/pushed hash keys and values into new HoA row');
} else {
	fail("add_data (Cross-Merge): expected 2 elements in HoA row B, got $b_len_hoa");
}

# 6b. Target is HoH, Source is HoA
my $h_target_hoh = { A => { k1 => 'v1' } };
$i_source_hoa = { A => [ k2 => 'v2' ], B => [ k3 => 'v3' ] };

add_data($h_target_hoh, $i_source_hoa);

if (ref($h_target_hoh->{B}) eq 'HASH') {
	pass('add_data (Cross-Merge): output matches structure of h_ref (HoH created)');
} else {
	fail('add_data (Cross-Merge): output failed to match HoH structure of h_ref');
}

if ($h_target_hoh->{A}->{k2} eq 'v2' && $h_target_hoh->{B}->{k3} eq 'v3') {
	pass('add_data (Cross-Merge): correctly merged array pairs into HoH rows');
} else {
	fail('add_data (Cross-Merge): failed to merge array pairs into HoH rows');
}

no_leaks_ok {
	my $h_test_hoa = { A => [ 1, 2 ] };
	my $i_test_hoh = { A => { 3 => 4 }, B => { 5 => 6 } };
	add_data($h_test_hoa, $i_test_hoh);

	my $h_test_hoh = { A => { 1 => 2 } };
	my $i_test_hoa = { A => [ 3, 4 ], B => [ 5, 6 ] };
	add_data($h_test_hoh, $i_test_hoa);
} 'add_data: no leaks when cross-merging mismatched structures' unless $INC{'Devel/Cover.pm'};

# 7. Array of Hashes (AoH) and Array of Arrays (AoA) Merging
my $h_aoh = [ { a => 1 } ];
my $i_aoh = [ { b => 2 }, { c => 3 } ];

add_data($h_aoh, $i_aoh);

if (ref($h_aoh) eq 'ARRAY' && scalar @{ $h_aoh } == 2) {
	pass('add_data (AoH): correctly detected array root and expanded indices');
} else {
	fail('add_data (AoH): failed to properly establish array root length');
}

if ($h_aoh->[0]->{a} == 1 && $h_aoh->[0]->{b} == 2 && $h_aoh->[1]->{c} == 3) {
	pass('add_data (AoH): correctly merged hash elements within array root');
} else {
	fail('add_data (AoH): failed to merge hash elements within array root');
}

# 8. Cross-Merging Root Types (Root Coercion)

# 8a. Target is AoH, Source is HoH
my $h_root_aoh = [ { x => 1 } ];
my $i_root_hoh = { 0 => { y => 2 }, 1 => { z => 3 }, ignored => { k => 'v' } }; # 'ignored' should be safely dropped

add_data($h_root_aoh, $i_root_hoh);

if (ref($h_root_aoh) eq 'ARRAY' && scalar @{ $h_root_aoh } == 2) {
	pass('add_data (Root Cross-Merge): output matches structure of h_ref (Array root created)');
} else {
	fail('add_data (Root Cross-Merge): output failed to match Array root structure of h_ref');
}

if ($h_root_aoh->[0]->{y} == 2 && $h_root_aoh->[1]->{z} == 3) {
	pass('add_data (Root Cross-Merge): correctly mapped source hash numeric keys to target array indices');
} else {
	fail('add_data (Root Cross-Merge): failed to map source hash numeric keys to target array indices');
}

# 8b. Target is HoH, Source is AoH
my $h_root_hoh = { '0' => { alpha => 1 } };
my $i_root_aoh = [ { beta => 2 }, { gamma => 3 } ];

add_data($h_root_hoh, $i_root_aoh);

if (ref($h_root_hoh) eq 'HASH' && scalar keys %{ $h_root_hoh } == 2) {
	pass('add_data (Root Cross-Merge): output matches structure of h_ref (Hash root created)');
} else {
	fail('add_data (Root Cross-Merge): output failed to match Hash root structure of h_ref');
}

if ($h_root_hoh->{'0'}->{beta} == 2 && $h_root_hoh->{'1'}->{gamma} == 3) {
	pass('add_data (Root Cross-Merge): correctly mapped source array indices to target hash strings');
} else {
	fail('add_data (Root Cross-Merge): failed to map source array indices to target hash strings');
}

no_leaks_ok {
	# Array target, Array source
	my $h_test_aoh = [ { x => 1 } ];
	my $i_test_aoh = [ { y => 2 }, { z => 3 } ];
	add_data($h_test_aoh, $i_test_aoh);

	# Array target, Hash source
	my $h_test_cross_1 = [ { a => 1 } ];
	my $i_test_cross_1 = { 0 => { b => 2 }, 1 => { c => 3 } };
	add_data($h_test_cross_1, $i_test_cross_1);

	# Hash target, Array source
	my $h_test_cross_2 = { '0' => { a => 1 } };
	my $i_test_cross_2 = [ { b => 2 }, { c => 3 } ];
	add_data($h_test_cross_2, $i_test_cross_2);
} 'add_data: no leaks during array root parsing or root cross-merging structures' unless $INC{'Devel/Cover.pm'};

# my own tests, I don't completely trust AI
$h_hoa = {
	A => ['a','b','c'], # strings instead of numerics prevent floating pt errors
	B => ['x','y','z']
};
$i_hoa = {
	A => ['d','e','f'],
	B => ['g','h','i']
};
add_data($h_hoa, $i_hoa);
is_deeply(
	$h_hoa,
	{ A => ['a'..'f'], B => ['x','y','z','g','h','i'] },
	'add_data: HoA to HoA works'
);
done_testing();
