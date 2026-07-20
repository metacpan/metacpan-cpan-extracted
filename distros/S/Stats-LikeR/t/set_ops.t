#!/usr/bin/env perl

require 5.010;
use warnings FATAL => 'all';
use Scalar::Util 'looks_like_number';
use Stats::LikeR;
use Test::Exception; # dies_ok / throws_ok
use Test::More;
use Test::LeakTrace 'no_leaks_ok';

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

# Ordered list-equality helper (order is part of these functions' contract).
sub is_list {
	my ($got, $exp, $name) = @_;
	is_deeply($got, $exp, $name);
}

# Reusable inputs.  @a has duplicates (3,4) on purpose to exercise per-list dedup.
my @a = (1, 2, 3, 4, 5, 4, 3);
my @b = (3, 4, 5, 6, 7);
my @c = (5, 6, 7, 8);

# Coderef aliases reach the runtime no-argument guard cleanly for the variadic
# (@-prototyped) set operators.
my $UNION = \&Stats::LikeR::get_union;
my $LONLY = \&Stats::LikeR::Lonly;
my $RONLY = \&Stats::LikeR::Ronly;

#--------
# union
#--------
is_list( [get_union(\@a, \@b, \@c)], [1, 2, 3, 4, 5, 6, 7, 8], 'union: all distinct, first-appearance order');
is_list( [get_union(\@a)],           [1, 2, 3, 4, 5],          'union: single ref deduped');
is_list( [get_union([])],            [],                       'union: empty ref -> empty list');
is_list( [get_union([1], ['1'])],    [1],                      'union: number and string key coalesce');
is( scalar(get_union(\@a, \@b, \@c)), 8, 'union: scalar context returns count');
is( scalar(get_union([])),            0, 'union: scalar context of empty is 0');
ok( looks_like_number(scalar get_union(\@a, \@b)), 'union: scalar count is numeric');

throws_ok { my @x = get_union(\@a, 'not a ref') } qr/not an array reference/, 'union: croaks on non-ref arg';
throws_ok { my @x = get_union(\@a, [1, undef]) }   qr/undefined value/,        'union: croaks on undef element';
throws_ok { $UNION->() }                       qr/needs >= 1 array ref/,   'union: croaks with no args';

get_union(\@a, \@b, \@c);                       # hoist real call outside the leak closure
no_leaks_ok {
	eval {
		my @l = union(\@a, \@b, \@c);   # list  context branch
		my $s = union(\@a, \@b);        # scalar context branch
	}
} 'union(): no memory leaks' unless $INC{'Devel/Cover.pm'};

#--------
# Lonly   (values only in the first ref, in no other ref)
#--------
is_list( [Lonly(\@a, \@b, \@c)], [1, 2],       'Lonly: only-in-first values');
is_list( [Lonly(\@a)],           [1, 2, 3, 4, 5], 'Lonly: single ref -> its distinct values');
is_list( [Lonly(\@c, \@a, \@b)], [8],          'Lonly: honours which ref is first');
is_list( [Lonly([9, 9], \@b)],   [9],          'Lonly: per-list dedup of the unique value');
is_list( [Lonly(\@b, \@a)],      [6, 7],       'Lonly: two-ref case -> left-only values');
is( scalar(Lonly(\@a, \@b, \@c)), 2, 'Lonly: scalar context returns count');

throws_ok { my @x = Lonly(\@a, {}) }        qr/not an array reference/, 'Lonly: croaks on non-ref arg';
throws_ok { my @x = Lonly([undef], \@b) }   qr/undefined value/,        'Lonly: croaks on undef element';
throws_ok { $LONLY->() }                    qr/needs >= 1 array ref/,   'Lonly: croaks with no args';

Lonly(\@a, \@b, \@c);                       # hoist
no_leaks_ok {
	eval {
		my @l = Lonly(\@a, \@b, \@c);
		my $s = Lonly(\@a, \@b);
	}
} 'Lonly(): no memory leaks' unless $INC{'Devel/Cover.pm'};

#--------
# Ronly   (values only in the last ref, in no other ref -- the mirror of Lonly)
#--------
is_list( [Ronly(\@a, \@b)], [6, 7],   'Ronly: two-ref -> values only in the last (right) ref, in right order');
is_list( [Ronly(\@b, \@a)], [1, 2],   'Ronly: mirror image of Lonly with args reversed');
is_list( [Ronly(\@b, \@b)], [],       'Ronly: identical lists -> empty');
is_list( [Ronly(\@a, [])],  [],       'Ronly: empty last ref -> empty');
is_list( [Ronly([], \@b)],  [3, 4, 5, 6, 7], 'Ronly: empty first ref -> last ref distinct');
is( scalar(Ronly(\@a, \@b)), 2, 'Ronly: scalar context returns count');

# >2 args: values only in the LAST ref, present in no earlier ref
is_list( [Ronly(\@a, \@b, \@c)], [8],       'Ronly: only-in-last values across three refs');
is_list( [Ronly(\@c)],           [5, 6, 7, 8], 'Ronly: single ref -> its distinct values');
is_list( [Ronly(\@c, \@b, \@a)], [1, 2],    'Ronly: honours which ref is last');
is_list( [Ronly(\@b, [9, 9])],   [9],       'Ronly: per-list dedup of the unique value');
is( scalar(Ronly(\@a, \@b, \@c)), 1, 'Ronly: scalar context returns count (three refs)');

# Ronly(a, b, ...) == Lonly(reverse a, b, ...)
is_list( [Ronly(\@a, \@b, \@c)], [Lonly(\@c, \@b, \@a)], 'Ronly == Lonly with args reversed (three refs)');

throws_ok { my @x = Ronly('x', \@b) }        qr/not an array reference/, 'Ronly: croaks on non-ref (first)';
throws_ok { my @x = Ronly(\@a, 'x') }        qr/not an array reference/, 'Ronly: croaks on non-ref (last)';
throws_ok { my @x = Ronly([undef], \@b) }    qr/undefined value/,        'Ronly: croaks on undef in first';
throws_ok { my @x = Ronly(\@a, [undef]) }    qr/undefined value/,        'Ronly: croaks on undef in last';
throws_ok { $RONLY->() }                     qr/needs >= 1 array ref/,   'Ronly: croaks with no args';

Ronly(\@a, \@b, \@c);                        # hoist
no_leaks_ok {
	eval {
		my @l = Ronly(\@a, \@b, \@c);
		my $s = Ronly(\@a, \@b);
	}
} 'Ronly(): no memory leaks' unless $INC{'Devel/Cover.pm'};

#--------
# cross-checks: relationships that must hold together
#--------
is( scalar(get_union(\@a, \@b)),
    scalar(intersection(\@a, \@b)) + scalar(Lonly(\@a, \@b)) + scalar(Ronly(\@a, \@b)),
    'identity: |union| == |intersection| + |Lonly| + |Ronly|');

done_testing;
