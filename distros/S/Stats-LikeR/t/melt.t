#!/usr/bin/env perl

require 5.010;
use warnings FATAL => 'all';
use Stats::LikeR;
use Test::Exception; # dies_ok / throws_ok
use Test::More;
use Test::LeakTrace 'no_leaks_ok';

# melt: wide -> long, like pandas DataFrame.melt.
#   * output row order is column-major: all rows for value_vars[0], then
#     value_vars[1], .. preserving input row order within each block
#   * column ids are names (AoH/HoA/HoH) or 0-based positions (AoA)
#   * 'output.type' defaults to the input family; hoh resets labels to 0..N-1

#--------
# AoH, the classic pandas example (default output family = AoH)
#--------
{
	my $df = [ { A => 'a', B => 1, C => 2 },
	           { A => 'b', B => 3, C => 4 },
	           { A => 'c', B => 5, C => 6 } ];
	my $got = melt($df, id_vars => 'A', value_vars => [ 'B', 'C' ]);
	is_deeply($got, [
		{ A => 'a', variable => 'B', value => 1 },
		{ A => 'b', variable => 'B', value => 3 },
		{ A => 'c', variable => 'B', value => 5 },
		{ A => 'a', variable => 'C', value => 2 },
		{ A => 'b', variable => 'C', value => 4 },
		{ A => 'c', variable => 'C', value => 6 },
	], 'AoH melt: column-major order, id copied across');
	is_deeply($df, [ { A => 'a', B => 1, C => 2 },
	                 { A => 'b', B => 3, C => 4 },
	                 { A => 'c', B => 5, C => 6 } ],
		'AoH melt: original frame untouched');
}

#--------
# value_vars defaults to every column not in id_vars (colnames order)
#--------
{
	my $df = [ { A => 'a', B => 1, C => 2 } ];
	is_deeply(melt($df, id_vars => 'A'), [
		{ A => 'a', variable => 'B', value => 1 },
		{ A => 'a', variable => 'C', value => 2 },
	], 'default value_vars = non-id columns, sorted');
}

#--------
# multiple id_vars, id_vars scalar accepted
#--------
{
	my $df = [ { k1 => 'x', k2 => 'p', m => 10 },
	           { k1 => 'y', k2 => 'q', m => 20 } ];
	is_deeply(melt($df, id_vars => [ 'k1', 'k2' ], value_vars => 'm'), [
		{ k1 => 'x', k2 => 'p', variable => 'm', value => 10 },
		{ k1 => 'y', k2 => 'q', variable => 'm', value => 20 },
	], 'multiple id_vars kept');
}

#--------
# custom var_name / value_name
#--------
{
	my $df = [ { id => 1, s1 => 9, s2 => 8 } ];
	is_deeply(melt($df, id_vars => 'id', var_name => 'sensor', value_name => 'reading'), [
		{ id => 1, sensor => 's1', reading => 9 },
		{ id => 1, sensor => 's2', reading => 8 },
	], 'custom var_name/value_name');
}

#--------
# HoA input, default output family = HoA
#--------
{
	my $df = { A => [ 'a', 'b' ], B => [ 1, 2 ], C => [ 3, 4 ] };
	is_deeply(melt($df, id_vars => 'A', value_vars => [ 'B', 'C' ]), {
		A        => [ 'a', 'b', 'a', 'b' ],
		variable => [ 'B', 'B', 'C', 'C' ],
		value    => [ 1, 2, 3, 4 ],
	}, 'HoA melt: column-major, HoA out');
}

#--------
# HoH input, default output family = HoH, labels reset to 0..N-1
#--------
{
	my $df = { r1 => { A => 'a', B => 1 }, r2 => { A => 'b', B => 2 } };
	my $got = melt($df, id_vars => 'A', value_vars => 'B');
	# HoH row visit order is sorted keys (r1, r2)
	is_deeply($got, {
		0 => { A => 'a', variable => 'B', value => 1 },
		1 => { A => 'b', variable => 'B', value => 2 },
	}, 'HoH melt: RangeIndex 0..N-1 labels');
}

#--------
# AoA input, positional ids; default output AoA (var/value positional)
#--------
{
	my $df = [ [ 'a', 1, 2 ], [ 'b', 3, 4 ] ];
	is_deeply(melt($df, id_vars => 0, value_vars => [ 1, 2 ]), [
		[ 'a', 1, 1 ],
		[ 'b', 1, 3 ],
		[ 'a', 2, 2 ],
		[ 'b', 2, 4 ],
	], 'AoA melt: positional variable holds source index');
}

#--------
# output.type overrides: AoH in -> HoA / AoA / HoH out
#--------
{
	my $df = [ { A => 'a', B => 1 }, { A => 'b', B => 2 } ];
	is_deeply(melt($df, id_vars => 'A', 'output.type' => 'hoa'), {
		A => [ 'a', 'b' ], variable => [ 'B', 'B' ], value => [ 1, 2 ],
	}, 'output.type hoa');
	is_deeply(melt($df, id_vars => 'A', 'output.type' => 'aoa'), [
		[ 'a', 'B', 1 ], [ 'b', 'B', 2 ],
	], 'output.type aoa (id, variable, value positional)');
	is_deeply(melt($df, id_vars => 'A', 'output.type' => 'hoh'), {
		0 => { A => 'a', variable => 'B', value => 1 },
		1 => { A => 'b', variable => 'B', value => 2 },
	}, 'output.type hoh');
}

#--------
# NA cells pass through as undef
#--------
{
	my $df = [ { A => 'a', B => undef } ];
	is_deeply(melt($df, id_vars => 'A', value_vars => 'B'),
		[ { A => 'a', variable => 'B', value => undef } ],
		'NA value melts to undef');
}

#--------
# error paths
#--------
dies_ok { melt(undef) } 'undef data dies';
throws_ok { melt([ { A => 1 } ], 'oddarg') }
	qr/name => value pairs/, 'odd trailing args die';
throws_ok { melt([ { A => 1 } ], bogus => 1) }
	qr/unknown argument/, 'unknown argument dies';
throws_ok { melt([ { A => 1 } ], id_vars => 'A', 'output.type' => 'xxx') }
	qr/output\.type/, 'bad output.type dies';
throws_ok { melt([ { A => 1 } ], value_vars => 'Z') }
	qr/column 'Z' not found/, 'unknown column dies';
throws_ok { melt([ { A => 1, v => 2 } ], id_vars => 'A', var_name => 'x', value_name => 'x') }
	qr/must differ/, 'var_name == value_name dies';
throws_ok { melt([ { A => 1, v => 2 } ], id_vars => 'A', var_name => 'A') }
	qr/collides/, 'var_name colliding with id_vars dies';

#--------
# memory
#--------
if ($INC{'Devel/Cover.pm'}) { done_testing(); exit 0 }
no_leaks_ok {
	my $x = melt([ { A => 'a', B => 1, C => 2 } ], id_vars => 'A', value_vars => [ 'B', 'C' ]);
} 'melt: no memory leaks (AoH)';

no_leaks_ok {
	my $x = melt({ A => [ 1, 2 ], B => [ 3, 4 ] }, value_vars => [ 'A', 'B' ]);
} 'melt: no memory leaks (HoA)';

no_leaks_ok {
	eval { melt([ { A => 1 } ], value_vars => 'Z') };
} 'melt: no memory leaks (die path)';

done_testing();
