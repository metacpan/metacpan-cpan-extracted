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

# Coderef aliases let us bypass the ($$)/(@) prototypes to reach the runtime
# argument-count and non-ref guards (a straight Lonly(\@a) is a compile error).
my $UNION = \&Stats::LikeR::get_union;
my $UNIQ  = \&Stats::LikeR::get_unique;
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
# get_unique   (values only in the first ref, in no other ref)
#--------
is_list( [get_unique(\@a, \@b, \@c)], [1, 2],       'get_unique: only-in-first values');
is_list( [get_unique(\@a)],           [1, 2, 3, 4, 5], 'get_unique: single ref -> its distinct values');
is_list( [get_unique(\@c, \@a, \@b)], [8],          'get_unique: honours which ref is first');
is_list( [get_unique([9, 9], \@b)],   [9],          'get_unique: per-list dedup of the unique value');
is_list( [get_unique(\@b, \@a)],      [6, 7],       'get_unique: two-ref case matches Lonly');
is( scalar(get_unique(\@a, \@b, \@c)), 2, 'get_unique: scalar context returns count');

throws_ok { my @x = get_unique(\@a, {}) }        qr/not an array reference/, 'get_unique: croaks on non-ref arg';
throws_ok { my @x = get_unique([undef], \@b) }   qr/undefined value/,        'get_unique: croaks on undef element';
throws_ok { $UNIQ->() }                          qr/needs >= 1 array ref/,   'get_unique: croaks with no args';

get_unique(\@a, \@b, \@c);                  # hoist
no_leaks_ok {
	eval {
		my @l = get_unique(\@a, \@b, \@c);
		my $s = get_unique(\@a, \@b);
	}
} 'get_unique(): no memory leaks' unless $INC{'Devel/Cover.pm'};

#--------
# Lonly   (values in left ref, absent from right ref)
#--------
is_list( [Lonly(\@a, \@b)], [1, 2],   'Lonly: left-only values, deduped, in left order');
is_list( [Lonly(\@b, \@a)], [6, 7],   'Lonly: not symmetric with the reversed call');
is_list( [Lonly(\@b, \@b)], [],       'Lonly: identical lists -> empty');
is_list( [Lonly([], \@b)],  [],       'Lonly: empty left -> empty');
is_list( [Lonly(\@a, [])],  [1, 2, 3, 4, 5], 'Lonly: empty right -> left distinct');
is( scalar(Lonly(\@a, \@b)), 2, 'Lonly: scalar context returns count');

throws_ok { my @x = Lonly('x', \@b) }        qr/first \(left\) argument/,  'Lonly: croaks on non-ref left';
throws_ok { my @x = Lonly(\@a, 'x') }        qr/second \(right\) argument/,'Lonly: croaks on non-ref right';
throws_ok { my @x = Lonly([undef], \@b) }    qr/undefined value in left/,  'Lonly: croaks on undef in left';
throws_ok { my @x = Lonly(\@a, [undef]) }    qr/undefined value in right/, 'Lonly: croaks on undef in right';
throws_ok { $LONLY->(\@a) }                  qr/exactly 2 array refs/,     'Lonly: croaks on 1 ref';
throws_ok { $LONLY->(\@a, \@b, \@c) }        qr/exactly 2 array refs/,     'Lonly: croaks on 3 refs';

Lonly(\@a, \@b);                            # hoist
no_leaks_ok {
	eval {
		my @l = Lonly(\@a, \@b);
		my $s = Lonly(\@a, \@b);
	}
} 'Lonly(): no memory leaks' unless $INC{'Devel/Cover.pm'};

#--------
# Ronly   (values in right ref, absent from left ref)
#--------
is_list( [Ronly(\@a, \@b)], [6, 7],   'Ronly: right-only values, deduped, in right order');
is_list( [Ronly(\@b, \@a)], [1, 2],   'Ronly: mirror image of Lonly with args reversed');
is_list( [Ronly(\@b, \@b)], [],       'Ronly: identical lists -> empty');
is_list( [Ronly(\@a, [])],  [],       'Ronly: empty right -> empty');
is_list( [Ronly([], \@b)],  [3, 4, 5, 6, 7], 'Ronly: empty left -> right distinct');
is( scalar(Ronly(\@a, \@b)), 2, 'Ronly: scalar context returns count');

throws_ok { my @x = Ronly('x', \@b) }        qr/first \(left\) argument/,  'Ronly: croaks on non-ref left';
throws_ok { my @x = Ronly(\@a, 'x') }        qr/second \(right\) argument/,'Ronly: croaks on non-ref right';
throws_ok { my @x = Ronly([undef], \@b) }    qr/undefined value in left/,  'Ronly: croaks on undef in left';
throws_ok { my @x = Ronly(\@a, [undef]) }    qr/undefined value in right/, 'Ronly: croaks on undef in right';
throws_ok { $RONLY->(\@a) }                  qr/exactly 2 array refs/,     'Ronly: croaks on 1 ref';
throws_ok { $RONLY->(\@a, \@b, \@c) }        qr/exactly 2 array refs/,     'Ronly: croaks on 3 refs';

Ronly(\@a, \@b);                            # hoist
no_leaks_ok {
	eval {
		my @l = Ronly(\@a, \@b);
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
