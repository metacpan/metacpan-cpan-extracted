#!/usr/bin/env perl

# avals(): the list-returning twin of vals(). There is no R or SciPy
# equivalent to take reference values from -- pandas' Series.to_list() is the
# closest analogue and pins no numbers -- so the reference here is vals()
# itself, which t/vals.t and t/vals2.t already cover: every case below asserts
# that avals(...) returns exactly the list vals(...) returns behind its
# array-ref, and adds the cases that only exist for a list return (context,
# slicing, and the empty list).

require 5.010;
use strict;
use warnings FATAL => 'all';
use Test::Exception; # dies_ok
use Test::More;
use Stats::LikeR qw(avals vals);
use Test::LeakTrace 'no_leaks_ok';

# Setup Test Data Shapes -- the same three frames t/vals.t uses
my $aoh = [
 { id => 1, val => 10, tag => 'A' },
 { id => 2, val => 20, tag => 'B' },
 { id => 3 } # intentional missing 'val'
];

my $hoa = {
 id  => [1, 2, 3],
 val => [10, 20, undef],
 tag => ['A', 'B', 'C']
};

my $hoh = {
 row_c => { id => 3, val => 30, tag => 'C' },
 row_a => { id => 1, val => 10, tag => 'A' },
 row_b => { id => 2, val => 20, tag => 'B' },
 row_d => { id => 4 } # intentional missing 'val'
};

# Array of Hashes (AoH)
my @res_aoh = avals($aoh, 'val');
no_leaks_ok {
	my @tmp = avals($aoh, 'val');
} 'avals(AoH): no memory leaks' unless $INC{'Devel/Cover.pm'};

is(scalar @res_aoh, 3, 'avals(AoH) returns the correct column length');
is($res_aoh[0], 10, 'avals(AoH) element 0 extracted correctly');
is($res_aoh[1], 20, 'avals(AoH) element 1 extracted correctly');
is($res_aoh[2], undef, 'avals(AoH) missing cell safely yields undef');
is_deeply(\@res_aoh, vals($aoh, 'val'), 'avals(AoH) is vals(AoH) as a list');

# Hash of Arrays (HoA)
my @res_hoa = avals($hoa, 'val');
no_leaks_ok {
	my @tmp = avals($hoa, 'val');
} 'avals(HoA): no memory leaks' unless $INC{'Devel/Cover.pm'};

is(scalar @res_hoa, 3, 'avals(HoA) returns the correct column length');
is($res_hoa[0], 10, 'avals(HoA) element 0 extracted correctly');
is($res_hoa[1], 20, 'avals(HoA) element 1 extracted correctly');
is($res_hoa[2], undef, 'avals(HoA) explicit undef element extracted safely');
is_deeply(\@res_hoa, vals($hoa, 'val'), 'avals(HoA) is vals(HoA) as a list');

dies_ok { my @x = avals($hoa, 'missing_col') } 'avals(HoA) gracefully dies when asked for a non-existent column';
no_leaks_ok {
	eval { my @x = avals($hoa, 'missing_col') };
} 'avals(HoA): no memory leaks when it croaks' unless $INC{'Devel/Cover.pm'};

# Hash of Hashes (HoH)
my @res_hoh = avals($hoh, 'val');
no_leaks_ok {
	my @tmp = avals($hoh, 'val');
} 'avals(HoH): no memory leaks' unless $INC{'Devel/Cover.pm'};

is(scalar @res_hoh, 4, 'avals(HoH) returns the correct column length');
# Expect alphabetical alignment: row_a, row_b, row_c, row_d
is($res_hoh[0], 10, 'avals(HoH) row_a extracted in proper alphabetical order');
is($res_hoh[1], 20, 'avals(HoH) row_b extracted in proper alphabetical order');
is($res_hoh[2], 30, 'avals(HoH) row_c extracted in proper alphabetical order');
is($res_hoh[3], undef, 'avals(HoH) row_d (missing) safely yields undef');
is_deeply(\@res_hoh, vals($hoh, 'val'), 'avals(HoH) is vals(HoH) as a list');

# List-return specifics
is(scalar(() = avals($aoh, 'val')), 3, 'avals returns a 3-element list, not one arrayref');
is(scalar(() = avals([], 'col')), 0, 'avals on an empty AoH yields the empty list');
is(scalar(() = avals({}, 'col')), 0, 'avals on an empty HoA/HoH yields the empty list');
is_deeply([ (avals($hoh, 'val'))[1, 2] ], [20, 30], 'the returned list slices directly');
{
	# a list-returning XSUB is still callable where one value is wanted;
	# perl takes the last element of the returned list
	my $one = avals($aoh, 'val');
	is($one, undef, 'scalar assignment takes the last returned value (undef here)');
}

# the result is a copy: mutating it must not reach back into the frame
{
	my @copy = avals($aoh, 'val');
	$copy[0] = 999;
	is($aoh->[0]{val}, 10, 'avals copies every cell out of the frame');
	my @undefs = avals($aoh, 'val');
	$undefs[2] = 'writable';	# not the read-only PL_sv_undef
	is($undefs[2], 'writable', 'a missing cell comes back as a writable undef');
}

# Exceptions -- same messages as vals(), with the function name changed
throws_ok { my @x = avals('not_a_ref', 'val') }
	qr/^avals: first argument must be an array-ref/,
	'avals croaks on a string instead of a reference';
throws_ok { my @x = avals(\my $scalar, 'val') }
	qr/^avals: first argument must be an array-ref/,
	'avals croaks on a scalar reference';
throws_ok { my @x = avals($aoh, undef) }
	qr/^avals: column name must be defined/,
	'avals croaks on an undefined column name';
throws_ok { my @x = avals([ { a => 1 }, undef ], 'a') }
	qr/^avals: AoH row 1 is undef/,
	'avals croaks on an undef AoH row, naming the index';
throws_ok { my @x = avals([ { a => 1 }, [1] ], 'a') }
	qr/^avals: AoH row 1 is not a hash-ref/,
	'avals croaks on a non-hashref AoH row, naming the index';
{
	# a hash with one non-hashref value is classified by whichever value
	# hv_iternext hands back first, so which of the two croaks fires depends on
	# hash order -- what must hold is that avals() croaks exactly where vals()
	# does, with the same message. Iteration order is a property of the HV, so
	# both calls peek the same key.
	my $bad = { row_a => { v => 1 }, row_b => { v => 2 }, row_c => 'x' };
	my ($e_vals, $e_avals);
	eval { vals($bad, 'v') };            $e_vals  = $@;
	eval { my @x = avals($bad, 'v') };  $e_avals = $@;
	s/ at \S+ line \d+\.?\n?\z// for $e_vals, $e_avals;
	like($e_avals,
		qr/^avals: (?:HoH value for key 'row_c' is not a hash-ref|no column named "v")$/,
		'avals croaks on a HoH holding a non-hashref row');
	$e_vals =~ s/^vals:/avals:/;
	is($e_avals, $e_vals, '... with exactly the message vals() gives');
}
dies_ok { my @x = avals($aoh) } 'avals croaks when the column argument is missing';

# a column that no row has dies in every shape, rather than giving all-undef
throws_ok { my @x = avals($aoh, 'Method') } qr/^avals: no column named "Method" at /,
	'an absent AoH column dies';
throws_ok { my @x = avals($hoh, 'Method') } qr/^avals: no column named "Method" at /,
	'an absent HoH column dies';
throws_ok { my @x = avals($hoa, 'Method') } qr/^avals: no column named "Method" at /,
	'an absent HoA column dies';
is_deeply([ avals([ {}, { Method => 'x' } ], 'Method') ], [undef, 'x'],
	'a column that only one AoH row has yields undef for the others');

# UTF-8 column names and HoH keys
{
	my $u_aoh = [ { "\x{394}G" => -1.5 }, { "\x{394}G" => -2.5 } ];
	is_deeply([ avals($u_aoh, "\x{394}G") ], [-1.5, -2.5], 'UTF-8 AoH column name');
	my $u_hoh = { "\x{3b2}" => { v => 2 }, "\x{3b1}" => { v => 1 } };
	is_deeply([ avals($u_hoh, 'v') ], [1, 2], 'UTF-8 HoH keys sort by Perl string order');
}

# a long column exercises the sized-once AvARRAY fill in the HoA branch
{
	my @big = (1 .. 5000);
	my @got = avals({ x => \@big }, 'x');
	is_deeply(\@got, \@big, 'a 5000-row HoA column round-trips');
}

# a magical (tied) cell must be fetched, not returned as the tied SV itself
{
	package t::TiedCell;
	my $fetches = 0;	# FETCHes since the last reset_fetches()
	sub TIESCALAR { my ($class, $v) = @_; return bless \$v, $class }
	sub FETCH { my $self = shift; $fetches++; return $$self }
	sub STORE { }
	sub fetches { return $fetches }
	sub reset_fetches { $fetches = 0; return }
}
# The cell itself is tied, rather than a tied scalar being copied into a freshly
# built frame: copying one in fetches it before avals() ever sees it, and how
# many times that fetch happens is a property of the perl, not of this module.
# The earlier form of this block used a FETCH that counted up (7, 8, 9, ...) and
# asserted the caller saw 7; a CPAN tester on perl 5.18.4
# (x86_64-linux-thread-multi) reported 8 for Stats::LikeR 0.31, i.e. that perl
# ran get-magic twice on the one copy, where 5.10.1, 5.12.5 and 5.44.0 each run
# it once. So FETCH returns a constant here: what is asserted is that avals()
# fetches the cell at extraction time and hands back a plain copy -- not how
# many mg_get() calls that copy took.
{
	my %row;
	tie $row{v}, 't::TiedCell', 7;
	t::TiedCell::reset_fetches();
	my $aoh_tied = [ \%row ];
	is(t::TiedCell::fetches(), 0, 'building the frame does not fetch a tied cell');
	my @got = avals($aoh_tied, 'v');
	is(scalar @got, 1, 'a tied cell yields one value');
	cmp_ok(t::TiedCell::fetches(), '>=', 1, 'a tied AoH cell is fetched at extraction time');
	is($got[0], 7, '... and the fetched value, not the tied SV, comes back');
	ok(!defined tied $got[0], '... as a plain copy carrying no tie magic');
	my $n = t::TiedCell::fetches();
	my $again = $got[0];
	is(t::TiedCell::fetches(), $n, '... so re-reading it does not fetch again');
	is($again, 7, '... and reads back the same value');
	is_deeply(vals($aoh_tied, 'v'), \@got, '... exactly what vals() returns for the same frame');
}
{
	# the HoH branch copies its cells the same way
	my %row;
	tie $row{v}, 't::TiedCell', 7;
	t::TiedCell::reset_fetches();
	my @got = avals({ r => \%row }, 'v');
	cmp_ok(t::TiedCell::fetches(), '>=', 1, 'a tied HoH cell is fetched at extraction time');
	is_deeply(\@got, [7], '... and comes back as its fetched value');
	ok(!defined tied $got[0], '... with no tie magic on the copy');
}
{
	# the HoA branch fills AvARRAY directly, so it gets its own check
	my @col;
	tie $col[0], 't::TiedCell', 7;
	$col[1] = 9;
	t::TiedCell::reset_fetches();
	my @got = avals({ v => \@col }, 'v');
	cmp_ok(t::TiedCell::fetches(), '>=', 1, 'a tied HoA cell is fetched at extraction time');
	is_deeply(\@got, [7, 9], '... and comes back as its fetched value');
	ok(!defined tied $got[0], '... with no tie magic on the copy');
}

done_testing();
