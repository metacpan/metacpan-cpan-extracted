#!/usr/bin/env perl
use v5.40;
use strict;
use warnings;

use Test::More;
use Params::Filter qw/make_filter/;

# ============================================================================
# Variant 1: Required-only (no accepted fields)
# ============================================================================
subtest "Required-only variant (empty accepted list)" => sub {
	plan tests => 6;

	my @req = qw/id name email/;
	my @ok = ();
	my @no = ();

	my $filter = make_filter(\@req, \@ok, \@no);

	# Should pass with all required fields
	my $data1 = {
		id => 123,
		name => 'Alice',
		email => 'alice@example.com',
		extra => 'ignored',
	};

	my $result1 = $filter->($data1);

	ok($result1, "Returns hashref when all required present");
	is_deeply([sort keys %$result1], [qw/email id name/], "Only required fields returned");
	is($result1->{id}, 123, "Required field 1 correct");
	is($result1->{name}, 'Alice', "Required field 2 correct");
	is($result1->{email}, 'alice@example.com', "Required field 3 correct");
	ok(!exists $result1->{extra}, "Extra field not included");
};

subtest "Required-only variant - missing required field" => sub {
	plan tests => 1;

	my @req = qw/id name email/;
	my @ok = ();
	my @no = ();

	my $filter = make_filter(\@req, \@ok, \@no);

	my $data2 = {
		id => 456,
		name => 'Bob',
		# email missing
	};

	my $result2 = $filter->($data2);

	ok(!defined($result2), "Returns undef when required field missing");
};

# ============================================================================
# Variant 2: Wildcard (accepted = ['*'])
# ============================================================================
subtest "Wildcard variant - accept all except exclusions" => sub {
	plan tests => 8;

	my @req = qw/id name/;
	my @ok = ('*');
	my @no = qw/password secret/;

	my $filter = make_filter(\@req, \@ok, \@no);

	my $data = {
		id => 789,
		name => 'Charlie',
		email => 'charlie@example.com',
		phone => '555-9999',
		city => 'LA',
		password => 'secret123',
		secret => 'top secret data',
		token => 'abc123',
	};

	my $result = $filter->($data);

	ok($result, "Returns hashref");
	is($result->{id}, 789, "Required field 1 present");
	is($result->{name}, 'Charlie', "Required field 2 present");
	is($result->{email}, 'charlie@example.com', "Non-required non-excluded field present");
	is($result->{phone}, '555-9999', "Another non-excluded field present");
	ok(!exists $result->{password}, "Excluded field 1 not present");
	ok(!exists $result->{secret}, "Excluded field 2 not present");
	is($result->{token}, 'abc123', "Wildcard accepts all non-excluded fields");
};

subtest "Wildcard variant - missing required field" => sub {
	plan tests => 1;

	my @req = qw/id name/;
	my @ok = ('*');
	my @no = qw/password/;

	my $filter = make_filter(\@req, \@ok, \@no);

	my $data = {
		id => 999,
		# name missing
		email => 'test@example.com',
	};

	my $result = $filter->($data);

	ok(!defined($result), "Returns undef when required field missing");
};

# ============================================================================
# Variant 3: Accepted-specific (normal case)
# ============================================================================
subtest "Accepted-specific variant" => sub {
	plan tests => 8;

	my @req = qw/id name email/;
	my @ok = qw/phone city/;
	my @no = qw/password/;

	my $filter = make_filter(\@req, \@ok, \@no);

	my $data = {
		id => 111,
		name => 'Diana',
		email => 'diana@example.com',
		phone => '555-1111',
		city => 'Seattle',
		password => 'pass123',
		extra => 'ignored',
	};

	my $result = $filter->($data);

	ok($result, "Returns hashref");
	is($result->{id}, 111, "Required field 1 present");
	is($result->{name}, 'Diana', "Required field 2 present");
	is($result->{email}, 'diana@example.com', "Required field 3 present");
	is($result->{phone}, '555-1111', "Accepted field 1 present");
	is($result->{city}, 'Seattle', "Accepted field 2 present");
	ok(!exists $result->{password}, "Excluded field not present");
	ok(!exists $result->{extra}, "Field not in required or accepted not present");
};

subtest "Accepted-specific - accepted field excluded" => sub {
	plan tests => 3;

	my @req = qw/id/;
	my @ok = qw/name email password/;
	my @no = qw/password/;  # password in both ok and no

	my $filter = make_filter(\@req, \@ok, \@no);

	my $data = {
		id => 222,
		name => 'Eve',
		email => 'eve@example.com',
		password => 'evepass',
	};

	my $result = $filter->($data);

	is($result->{id}, 222, "Required field present");
	is($result->{name}, 'Eve', "Accepted non-excluded field present");
	ok(!exists $result->{password}, "Excluded field not present even if in accepted list");
};

subtest "Accepted-specific - missing required field" => sub {
	plan tests => 1;

	my @req = qw/id name/;
	my @ok = qw/email/;
	my @no = ();

	my $filter = make_filter(\@req, \@ok, \@no);

	my $data = {
		id => 333,
		# name missing
		email => 'test@test.com',
	};

	my $result = $filter->($data);

	ok(!defined($result), "Returns undef when required field missing");
};

# ============================================================================
# Non-destructive behavior
# ============================================================================
subtest "Non-destructive behavior across all variants" => sub {
	plan tests => 6;

	# Variant 1
	my $filter1 = make_filter(['id'], [], []);
	my $data1 = {id => 1, extra => 'test'};
	$filter1->($data1);
	ok(exists $data1->{extra}, "Variant 1: Original data not modified");

	# Variant 2
	my $filter2 = make_filter(['id'], ['*'], ['secret']);
	my $data2 = {id => 2, secret => 'hidden', other => 'data'};
	$filter2->($data2);
	ok(exists $data2->{secret}, "Variant 2: Original data not modified");

	# Variant 3
	my $filter3 = make_filter(['id'], ['name'], ['password']);
	my $data3 = {id => 3, name => 'Test', password => 'pass', extra => 'x'};
	$filter3->($data3);
	ok(exists $data3->{password}, "Variant 3: Original data not modified");
	ok(exists $data3->{extra}, "Variant 3: Extra field still in original");
	is($data3->{id}, 3, "Variant 3: Original data unchanged");
	is($data3->{name}, 'Test', "Variant 3: Original fields intact");
};

# ============================================================================
# Edge cases
# ============================================================================
subtest "Empty data hashref" => sub {
	plan tests => 3;

	my $filter1 = make_filter(['id'], [], []);
	my $filter2 = make_filter(['id'], ['*'], []);
	my $filter3 = make_filter(['id'], ['name'], []);

	ok(!defined($filter1->({})), "Variant 1: Empty data returns undef");
	ok(!defined($filter2->({})), "Variant 2: Empty data returns undef");
	ok(!defined($filter3->({})), "Variant 3: Empty data returns undef");
};

subtest "No required fields" => sub {
	plan tests => 3;

	my $filter1 = make_filter([], [], []);
	my $filter2 = make_filter([], ['*'], ['password']);
	my $filter3 = make_filter([], ['name'], []);

	my $data = {id => 1, name => 'Test', password => 'secret'};

	my $result1 = $filter1->($data);
	is_deeply($result1, {}, "Variant 1: No required, no accepted returns empty hash");

	my $result2 = $filter2->($data);
	ok(!exists $result2->{password}, "Variant 2: Excluded field not included");
	is($result2->{name}, 'Test', "Variant 2: Other fields included");
};

done_testing();
