#!/usr/bin/env perl

require 5.010;
use warnings FATAL => 'all';
use feature 'say';
use Scalar::Util qw(looks_like_number refaddr);
use Test::Exception; # dies_ok
use Test::More;
use Test::LeakTrace 'no_leaks_ok';
use Scalar::Util 'looks_like_number';
use Stats::LikeR;

# Assume Stats::LikeR handles the `assign` export natively in your build.
# use Stats::LikeR;

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

# --------
# Setup basic test HoH
# --------
my $hoh = {
	Alice => { weight => 65, height => 1.70 },
	Bob   => { weight => 90, height => 1.85 },
};

# --------
# Standard Assignment & Chaining Operations
# --------
my $returned_ref = assign($hoh,
    bmi   => sub { $_->{weight} / ($_->{height} ** 2) },
    class => sub { $_->{bmi} > 25 ? 'high' : 'ok' }
);

# 1. Output structure check
is($hoh->{'Alice'}{'class'}, 'ok', 'Chained column uses earlier calculated column properly (Alice)');
is($hoh->{'Bob'}{'class'}, 'high', 'Chained column uses earlier calculated column properly (Bob)');

# 2. Math check via is_approx
is_approx($hoh->{'Alice'}{'bmi'}, 22.49134948, 'BMI dynamically calculated correctly');
is_approx($hoh->{'Bob'}{'bmi'}, 26.29656683, 'BMI dynamically calculated correctly');

# 3. Check exact reference returned
is(refaddr($returned_ref), refaddr($hoh), 'assign() successfully returned original hash reference for chaining');

# --------
# Indexing ($_[1]) and Row Key ($_[2]) Context checks
# --------
my $metadata_hoh = { 'Row A' => { data => 1 }, 'Row B' => { data => 2 } };

assign($metadata_hoh,
    numeric_index => sub { $_[1] },
    row_key_name  => sub { $_[2] }
);

is($metadata_hoh->{'Row A'}{'numeric_index'}, 0, 'First alphabetically sorted row gets index 0');
is($metadata_hoh->{'Row B'}{'numeric_index'}, 1, 'Second alphabetically sorted row gets index 1');
is($metadata_hoh->{'Row A'}{'row_key_name'}, 'Row A', '$_[2] context exposes exact outer hash key successfully');

# --------
# Exception Trapping
# --------
dies_ok { assign('not a ref', a => sub {}) } 'assign dies gracefully on non-reference frame';
dies_ok { assign($hoh, 'lone_key') } 'assign dies gracefully on odd number of arguments (missing code block)';
dies_ok { assign($hoh, new_col => 'not a code ref') } 'assign dies gracefully when value is not a CODE ref';
dies_ok { assign({ bad => 'string' }, col => sub {}) } 'assign dies gracefully if an inner HoH row is not a hashref';

# --------
# Memory Integrity
# --------
no_leaks_ok {
    eval {
        my $tmp_frame = { r1 => { val => 10 } };
        assign($tmp_frame, new_val => sub { $_[0]->{val} * 2 });
    }
} 'assign(HoH): no memory leaks' unless $INC{'Devel/Cover.pm'};

done_testing();
