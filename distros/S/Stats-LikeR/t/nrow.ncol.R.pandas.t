#!/usr/bin/env perl
# nrow() and ncol(), against R's and pandas' own cases.
#
# Provenance:
#   R     R 4.6.1 src/library/base/man/nrow.Rd, \examples: nrow(ma) 3 and
#         ncol(ma) 4 for ma <- matrix(1:12, 3, 4), NCOL(1:12) 1, NROW(1:12)
#         12.  The values are the Rd's own comments; R 4.6.2 printed the same
#         on 2026-11-26.  matrix() fills by column, so ma is the AoA below.
#   pandas  pandas 3.0.4, the DataFrame constructor cases whose input has a
#         Stats::LikeR frame shape, in pandas/tests/frame/test_constructors.py
#         and pandas/tests/frame/constructors/test_from_dict.py.  Each case is
#         named after its pandas test in %PANDAS below.  t/nrow.ncol.R.pandas.py
#         (committed next to this file) printed every shape and column list;
#         re-run it with
#             python3 -I t/nrow.ncol.R.pandas.py
#         This test never runs R or Python.
#
# A list of dicts is an AoH, a list of lists an AoA, a dict of lists a HoA, and
# a dict of dicts read with orient="index" a HoH.  pandas lists columns in
# first-seen order; colnames() sorts them, so the names here are sorted.
#
# Five of these failed on 0.3430: ncol() died on list_of_dict_order and
# list_of_odicts (it required every record to have as many keys as the first);
# on mix_dict_and_array nrow() returned 2 on about half the hash seeds, and
# both functions' messages depended on the hash order; and nrow()'s message
# for ragged named its reference column in hash order and ended in " at
# .../LikeR.pm line N".
#
# Deliberate differences, kept so that changing one is a decision:
#   - R's NCOL(numeric()) is 1, a zero-length vector being one column; ncol([])
#     is 0, since [] is as much an empty frame as an empty vector.
#   - R's NCOL(NULL) is 0; ncol(undef) dies, as for any non-reference.
#   - pandas refuses a ragged dict of lists outright; nrow() dies on it, but
#     ncol() counts its keys, which are the columns whatever their lengths
#     (colnames() lists them too).
#   - R's 3-d case in nrow.Rd, ncol(array(1:24, dim = 2:4)), has no frame
#     shape here.

require 5.010;
use strict;
use warnings FATAL => 'all';
use Stats::LikeR;
use Test::Exception; # throws_ok / lives_and
use Test::More;
use Test::LeakTrace 'no_leaks_ok';

#--------
# R, nrow.Rd
#--------
{
	my $ma = [ [1, 4, 7, 10], [2, 5, 8, 11], [3, 6, 9, 12] ]; # matrix(1:12, 3, 4)
	is(nrow($ma), 3, 'R nrow.Rd: nrow(matrix(1:12, 3, 4)) is 3');
	is(ncol($ma), 4, 'R nrow.Rd: ncol(matrix(1:12, 3, 4)) is 4');
	is(ncol([1 .. 12]), 1,  'R nrow.Rd: NCOL(1:12) is 1');
	is(nrow([1 .. 12]), 12, 'R nrow.Rd: NROW(1:12) is 12');
	is(ncol([]), 0, 'R nrow.Rd: NCOL(numeric()) is 1 in R, 0 here (see header)');
	throws_ok { ncol(undef) } qr/expected an ARRAY or HASH ref \(got undef\)/,
		'R nrow.Rd: NCOL(NULL) is 0 in R; ncol(undef) dies (see header)';
}

#--------
# pandas 3.0.4
#--------
my %PANDAS = (
	# test_constructor_list_of_dict_order (GH10056)
	list_of_dict_order => {
		df => [
			{ First => 1, Second => 4, Third => 7, Fourth => 10 },
			{ Second => 5, First => 2, Fourth => 11, Third => 8 },
			{ Second => 6, First => 3, Fourth => 12, Third => 9, YYY => 14, XXX => 13 },
		],
		nrow => 3, ncol => 6, cols => [qw(First Fourth Second Third XXX YYY)],
	},
	# test_from_dict.py test_constructor_list_of_odicts
	list_of_odicts => {
		df => [
			{ a => 1.5, b => 3, c => 4, d => 6 },
			{ a => 1.5, b => 3, d => 6 },
			{ a => 1.5, d => 6 },
			{},
			{ a => 1.5, b => 3, c => 4 },
			{ b => 3, c => 4, d => 6 },
		],
		nrow => 6, ncol => 4, cols => [qw(a b c d)],
	},
	# test_constructor_list_of_dicts
	list_of_dicts_empty => { df => [ {} ], nrow => 1, ncol => 0, cols => [] },
	# test_from_dict.py test_constructor_single_row
	single_row => {
		df => [ { a => 1.5, b => 3, c => 4, d => 6 } ],
		nrow => 1, ncol => 4, cols => [qw(a b c d)],
	},
	# test_from_dict.py test_constructor_from_ordered_dict (GH8425), orient="index"
	from_ordered_dict_index => {
		df => {
			one   => { col_a => 'foo1', col_b => 'bar1' },
			two   => { col_a => 'foo2', col_b => 'bar2' },
			three => { col_a => 'foo3', col_b => 'bar3' },
		},
		nrow => 3, ncol => 2, cols => [qw(col_a col_b)],
	},
	# test_from_dict.py test_constructor_orient, "dict of sequence", as columns
	dict_of_sequence => {
		df => { hi => [32, 3, 3], there => [3, 5, 3] },
		nrow => 3, ncol => 2, cols => [qw(hi there)],
	},
	# test_constructor_list_of_lists (GH484)
	list_of_lists => { df => [ [1, 'a'], [2, 'b'] ], nrow => 2, ncol => 2, cols => [0, 1] },
	# test_constructor_list_of_lists (GH4851): ten 0-d arrays, a plain vector
	list_of_0d => { df => [ 0 .. 9 ], nrow => 10, ncol => 1 },
	# test_constructor_dict, "Corner cases": len(DataFrame()) == 0
	empty => { df => {}, nrow => 0, ncol => 0, cols => [] },
	# test_constructor_empty_list (GH9939): no rows, columns A and B
	empty_list_columns => { df => { A => [], B => [] }, nrow => 0, ncol => 2, cols => [qw(A B)] },
);
for my $name (sort keys %PANDAS) {
	my $c = $PANDAS{$name};
	# lives_and: up to 0.3430 ncol() died on two of these, which would end the file
	lives_and { is(nrow($c->{df}), $c->{nrow}) } "pandas $name: nrow";
	lives_and { is(ncol($c->{df}), $c->{ncol}) } "pandas $name: ncol";
	next unless $c->{cols}; # colnames() of a plain vector is not pandas' column 0
	is_deeply([ colnames($c->{df}) ], $c->{cols}, "pandas $name: colnames, sorted");
}

# test_constructor_dict, "mix dict and array, wrong size": pandas raises
# "Mixing dicts with non-Series may lead to ambiguous ordering."  Which value
# nrow() and ncol() saw first used to decide the form, so the pair is renamed
# 50 times to cover both hash orders within one process.
for my $fn ([ nrow => \&nrow ], [ ncol => \&ncol ]) {
	my ($fname, $f) = @$fn;
	my $died = 0;
	for my $i (1 .. 50) {
		my $ok = eval { $f->({ "A$i" => { a => 'a', b => 'b' }, "B$i" => [qw(a b c)] }); 1 };
		$died++ if !$ok && $@ =~ /\A$fname: hash mixes HASH values \(key 'A$i'\) and ARRAY values \(key 'B$i'\)/;
	}
	is($died, 50, "pandas mix_dict_and_array: $fname refuses a hash of a dict and a list, naming both");
}

# test_constructor_ragged: pandas raises "All arrays must be of the same length"
# for columns of 10 and 8.
{
	my $ragged = { A => [ (0) x 10 ], B => [ (0) x 8 ] };
	throws_ok { nrow($ragged) }
		qr/\Anrow: ragged HoA — column 'B' has 8 rows, but 'A' has 10\n\z/,
		'pandas ragged: nrow refuses columns of 10 and 8';
	is(ncol($ragged), 2, 'pandas ragged: ncol still counts the two columns (see header)');
}

# eval: up to 0.3430 ncol() died on two of these frames, which would end the file
no_leaks_ok {
	eval {
		for my $name (sort keys %PANDAS) {
			my $r = nrow($PANDAS{$name}{df});
			my $c = ncol($PANDAS{$name}{df});
		}
	};
} 'nrow()/ncol(): the pandas frames, no memory leaks' unless $INC{'Devel/Cover.pm'};

done_testing();
