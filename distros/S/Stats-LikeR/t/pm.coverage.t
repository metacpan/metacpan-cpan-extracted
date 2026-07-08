#!/usr/bin/env perl
require 5.010;
use warnings FATAL => 'all';
use strict;
use File::Temp;
use Stats::LikeR qw(assign col dropna summary read_table view);
use Test::Exception; # dies_ok / lives_ok
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

# small predicate: does an arrayref of hashrefs contain a row with key=>val?
sub aoh_has {
	my ($aoh, $key, $val) = @_;
	for my $r (@$aoh) {
		return 1 if defined $r->{$key} && $r->{$key} eq $val;
	}
	return 0;
}

#============================================================
# assign
#============================================================

#---- AoH ----
{
	my $df = [ { w => 70, h => 2 }, { w => 80, h => 4 } ];
	my $out = assign($df, bmi => sub { $_->{w} / $_->{h} });
	is($out, $df, 'assign: AoH returns same ref (in place)');
	is($df->[0]{bmi}, 35, 'assign: AoH first row derived value');
	is($df->[1]{bmi}, 20, 'assign: AoH second row derived value');
}
{	# row index passed as $_[1]; chained pair uses earlier new col
	my $df = [ { x => 10 }, { x => 20 } ];
	assign($df,
		idx => sub { $_[1] },
		x2  => sub { $_->{x} + $_->{idx} },
	);
	is($df->[0]{idx}, 0, 'assign: AoH row index $_[1]');
	is($df->[1]{idx}, 1, 'assign: AoH row index increments');
	is($df->[1]{x2}, 21, 'assign: AoH later pair sees earlier new column');
}

#---- HoA ----
{
	my $df = { w => [70, 80], h => [2, 4] };
	my $out = assign($df, bmi => sub { $_->{w} / $_->{h} });
	is($out, $df, 'assign: HoA returns same ref (in place)');
	is_deeply($df->{bmi}, [35, 20], 'assign: HoA new column values');
}
{	# HoA row index + chained dependency
	my $df = { x => [1, 2, 3] };
	assign($df,
		i  => sub { $_[1] },
		xi => sub { $_->{x} + $_->{i} },
	);
	is_deeply($df->{i},  [0, 1, 2], 'assign: HoA index column');
	is_deeply($df->{xi}, [1, 3, 5], 'assign: HoA chained column sees new col');
}

#---- HoH ----
{
	my $df = {
		r1 => { w => 70, h => 2 },
		r2 => { w => 80, h => 4 },
	};
	my $out = assign($df, bmi => sub { $_->{w} / $_->{h} });
	is($out, $df, 'assign: HoH returns same ref (in place)');
	is($df->{r1}{bmi}, 35, 'assign: HoH r1 derived value');
	is($df->{r2}{bmi}, 20, 'assign: HoH r2 derived value');
}
{	# HoH passes row key as $_[2]
	my $df = { a => { v => 1 }, b => { v => 2 } };
	assign($df, key => sub { $_[2] });
	is($df->{a}{key}, 'a', 'assign: HoH row key $_[2]');
	is($df->{b}{key}, 'b', 'assign: HoH row key matches');
}

#---- assign errors ----
dies_ok { assign('not a ref', x => sub { 1 }) } 'assign: dies on non-ref df';
dies_ok { assign([{}], 'odd') } 'assign: dies on odd-length pair list';
dies_ok { assign([{}], x => 'notcode') } 'assign: AoH dies when value not CODE';
dies_ok { assign({ a => [1] }, x => 'notcode') } 'assign: HoA dies when value not CODE';
dies_ok { assign({ a => { v => 1 } }, x => 'notcode') } 'assign: HoH dies when value not CODE';
dies_ok { assign([ 'notahash' ], x => sub { 1 }) } 'assign: AoH dies when row not hashref';
dies_ok { assign({ a => \1 }, x => sub { 1 }) } 'assign: HASH dies on value neither HASH nor ARRAY';

#============================================================
# col() filter DSL (overloading) -- exercise the closures directly
#============================================================
{
	my $p = col('age') >= 18;
	ok(ref $p, 'col: comparison returns object');
	is($p->{code}->({ age => 18 }), 1, 'col: >= true at boundary');
	is($p->{code}->({ age => 17 }), 0, 'col: >= false below');
	is($p->{code}->({ age => undef }), 0, 'col: undef cell never matches');
	is($p->{code}->({ age => 'abc' }), 0, 'col: non-numeric cell never matches (num op)');
}
{	# all six numeric operators
	is((col('x') >  5)->{code}->({ x => 6 }), 1, 'col: > true');
	is((col('x') <  5)->{code}->({ x => 4 }), 1, 'col: < true');
	is((col('x') <= 5)->{code}->({ x => 5 }), 1, 'col: <= true');
	is((col('x') == 5)->{code}->({ x => 5 }), 1, 'col: == true');
	is((col('x') != 5)->{code}->({ x => 6 }), 1, 'col: != true');
}
{	# swapped operands (literal on the left)
	my $p = 18 <= col('age');
	is($p->{code}->({ age => 18 }), 1, 'col: swapped operand true at boundary');
	is($p->{code}->({ age => 10 }), 0, 'col: swapped operand false');
}
{	# string operators
	is((col('s') eq 'a')->{code}->({ s => 'a' }), 1, 'col: eq true');
	is((col('s') ne 'a')->{code}->({ s => 'b' }), 1, 'col: ne true');
	is((col('s') gt 'a')->{code}->({ s => 'b' }), 1, 'col: gt true');
	is((col('s') lt 'b')->{code}->({ s => 'a' }), 1, 'col: lt true');
	is((col('s') ge 'a')->{code}->({ s => 'a' }), 1, 'col: ge true');
	is((col('s') le 'a')->{code}->({ s => 'a' }), 1, 'col: le true');
	is((col('s') eq 'a')->{code}->({ s => undef }), 0, 'col: str undef never matches');
}
{	# logical & | !
	my $and = (col('x') > 0) & (col('y') > 0);
	is($and->{code}->({ x => 1, y => 1 }), 1, 'col: & both true');
	is($and->{code}->({ x => 1, y => -1 }), 0, 'col: & one false');
	my $or = (col('x') > 0) | (col('y') > 0);
	is($or->{code}->({ x => -1, y => 1 }), 1, 'col: | one true');
	is($or->{code}->({ x => -1, y => -1 }), 0, 'col: | both false');
	my $not = !(col('x') > 0);
	is($not->{code}->({ x => -1 }), 1, 'col: ! negates false->true');
	is($not->{code}->({ x => 1 }), 0, 'col: ! negates true->false');
}
{	# stringify / bool overloads
	my $p = col('x');
	like("$p", qr/predicate/, 'col: stringifies to a predicate label');
	ok($p ? 1 : 0, 'col: bool overload is true');
}
#---- col errors ----
dies_ok { col() } 'col: dies with no name';
dies_ok { col(undef) } 'col: dies on undef name';
dies_ok { col([1]) } 'col: dies on ref name';
dies_ok { (col('x') > 0) & col('y') } 'col: & dies when right operand is bare column';
dies_ok { col('x') & (col('y') > 0) } 'col: & dies when left operand is bare column';
dies_ok { !col('x') } 'col: ! dies on bare column';

#============================================================
# dropna
#============================================================

#---- AoH cols mode ----
{
	my $df = [ { a => 1, b => 2 }, { a => undef, b => 3 }, { a => 4, b => undef } ];
	my $out = dropna($df, cols => ['a']);
	is(scalar @$out, 2, 'dropna: AoH cols any drops undef in a');
	ok(!aoh_has($out, 'b', 3), 'dropna: AoH dropped the undef-a row');
	is(scalar @$df, 3, 'dropna: AoH original untouched');
}
{	# how => all
	my $df = [ { a => 1, b => undef }, { a => undef, b => undef } ];
	my $out = dropna($df, cols => ['a', 'b'], how => 'all');
	is(scalar @$out, 1, 'dropna: AoH how=all drops only fully-undef row');
}
{	# no cols listed keeps all; empty frame
	my $df = [ { a => 1 } ];
	is(scalar @{ dropna($df, cols => []) }, 1, 'dropna: AoH empty cols keeps all');
	is(scalar @{ dropna([], cols => ['a']) }, 0, 'dropna: AoH empty frame -> empty');
}
{	# rows mode (index deletion)
	my $df = [ { a => 1 }, { a => 2 }, { a => 3 } ];
	my $out = dropna($df, rows => [1]);
	is_deeply([ map { $_->{a} } @$out ], [1, 3], 'dropna: AoH rows deletes by index');
}

#---- HoA ----
{
	my $df = { a => [1, undef, 3], b => [9, 8, undef] };
	my $out = dropna($df, cols => ['a']);
	is_deeply($out->{a}, [1, 3], 'dropna: HoA cols rebuilds column');
	is_deeply($out->{b}, [9, undef], 'dropna: HoA keeps aligned other column');
}
{	# HoA rows mode + empty cols copy
	my $df = { a => [1, 2, 3] };
	is_deeply(dropna($df, rows => [0])->{a}, [2, 3], 'dropna: HoA rows by index');
	is_deeply(dropna($df, cols => [])->{a}, [1, 2, 3], 'dropna: HoA empty cols copies');
}

#---- HoH ----
{
	my $df = {
		r1 => { a => 1, b => 2 },
		r2 => { a => undef, b => 3 },
	};
	my $out = dropna($df, cols => ['a']);
	is(scalar keys %$out, 1, 'dropna: HoH cols drops undef row');
	ok(exists $out->{r1}, 'dropna: HoH kept r1');
}
{	# HoH rows + empty cols copy
	my $df = { r1 => { a => 1 }, r2 => { a => 2 } };
	is(scalar keys %{ dropna($df, rows => ['r1']) }, 1, 'dropna: HoH rows deletes key');
	is(scalar keys %{ dropna($df, cols => []) }, 2, 'dropna: HoH empty cols copies');
}

#---- dropna errors ----
dies_ok { dropna('x', cols => ['a']) } 'dropna: dies on non-ref df';
dies_ok { dropna([], 'odd') } 'dropna: dies on odd args';
dies_ok { dropna([], foo => 1) } 'dropna: dies on unknown arg';
dies_ok { dropna([]) } 'dropna: dies when neither cols nor rows';
dies_ok { dropna([], cols => ['a'], rows => [0]) } 'dropna: dies when both cols and rows';
dies_ok { dropna([], cols => 'a') } 'dropna: dies when cols not arrayref';
dies_ok { dropna([{a=>1}], cols => ['a'], how => 'bogus') } 'dropna: dies on bad how';
dies_ok { dropna([{a=>1}], cols => ['nope']) } 'dropna: AoH dies on missing column';
dies_ok { dropna({a=>[1]}, cols => ['nope']) } 'dropna: HoA dies on missing column';
dies_ok { dropna({ a => [1], r => { x => 1 } }) } 'dropna: dies on mixed HoA/HoH';

#============================================================
# summary
#============================================================
{	# single flat array (ref form)
	my $out = summary([1, 2, 3, 4, 5], nrows => 5);
	is(ref $out, 'ARRAY', 'summary: single array returns arrayref of lines');
	like($out->[1], qr/Min\./, 'summary: header present');
}
{	# flat list form with trailing nrows
	my $out = summary(1, 2, 3, 4, nrows => 2);
	is(ref $out, 'ARRAY', 'summary: flat list form works');
}
{	# AoH of arrays (array-of-arrays)
	my $out = summary([ [1, 2, 3], [4, 5, 6] ], nrows => 2);
	like($out->[1], qr/Index/, 'summary: AoA header has Index column');
}
{	# HoA
	my $out = summary({ x => [1, 2, 3], y => [4, 5, 6] });
	like($out->[1], qr/Key/, 'summary: HoA header has Key column');
}
dies_ok { summary(\1) } 'summary: dies when data is neither array nor hash';
dies_ok { summary([1, undef, 3]) } 'summary: dies on undef in single array';

#============================================================
# read_table  (write small temp files)
#============================================================
sub write_tmp {
	my ($content, $suffix) = @_;
	my $fh = File::Temp->new(SUFFIX => ($suffix // '.csv'), UNLINK => 1);
	print {$fh} $content;
	$fh->flush;
	return $fh;	# keep object alive for caller
}

{	# default aoh, comma sep
	my $fh = write_tmp("a,b,c\n1,2,3\n4,5,6\n");
	my $aoh = read_table("$fh");
	is(ref $aoh, 'ARRAY', 'read_table: aoh default returns arrayref');
	is($aoh->[0]{a}, 1, 'read_table: aoh first cell');
	is($aoh->[1]{c}, 6, 'read_table: aoh last cell');
}
{	# leading comment char stripped from header
	my $fh = write_tmp("#a,b\n1,2\n");
	my $aoh = read_table("$fh");
	ok(exists $aoh->[0]{a}, 'read_table: comment prefix stripped from header');
}
{	# tsv detection by extension
	my $fh = write_tmp("a\tb\n1\t2\n", '.tsv');
	my $aoh = read_table("$fh");
	is($aoh->[0]{b}, 2, 'read_table: tsv tab separator auto-detected');
}
{	# explicit sep
	my $fh = write_tmp("a;b\n1;2\n");
	my $aoh = read_table("$fh", sep => ';');
	is($aoh->[0]{a}, 1, 'read_table: explicit sep honoured');
}
{	# delim alias
	my $fh = write_tmp("a|b\n7|8\n");
	my $aoh = read_table("$fh", delim => '|');
	is($aoh->[0]{b}, 8, 'read_table: delim alias works');
}
{	# hoa output
	my $fh = write_tmp("a,b\n1,2\n3,4\n");
	my $hoa = read_table("$fh", 'output.type' => 'hoa');
	is_deeply($hoa->{a}, [1, 3], 'read_table: hoa column a');
	is_deeply($hoa->{b}, [2, 4], 'read_table: hoa column b');
}
{	# hoh output (first column is row name by default)
	my $fh = write_tmp("id,val\nr1,10\nr2,20\n");
	my $hoh = read_table("$fh", 'output.type' => 'hoh');
	is($hoh->{r1}{val}, 10, 'read_table: hoh row r1');
	is($hoh->{r2}{val}, 20, 'read_table: hoh row r2');
}
{	# explicit row.names for hoh
	my $fh = write_tmp("x,id\n1,k1\n2,k2\n");
	my $hoh = read_table("$fh", 'output.type' => 'hoh', 'row.names' => 'id');
	is($hoh->{k1}{x}, 1, 'read_table: hoh with explicit row.names');
}
{	# empty cell becomes undef
	my $fh = write_tmp("a,b\n1,\n");
	my $aoh = read_table("$fh");
	ok(!defined $aoh->[0]{b}, 'read_table: empty cell -> undef');
}
{	# CODE filter (applied to whole row, field 0)
	my $fh = write_tmp("a,b\n1,2\n9,9\n3,4\n");
	my $aoh = read_table("$fh", filter => sub { $_[0][0] != 9 });
	is(scalar @$aoh, 2, 'read_table: CODE filter drops matching rows');
}
{	# HASH filter keyed by column name
	my $fh = write_tmp("a,b\n1,2\n5,6\n");
	my $aoh = read_table("$fh", filter => { a => sub { $_ > 1 } });
	is(scalar @$aoh, 1, 'read_table: HASH filter by column name');
	is($aoh->[0]{a}, 5, 'read_table: HASH filter kept correct row');
}
{	# auto.row.names: header one field short
	my $fh = write_tmp("a,b\nr1,1,2\nr2,3,4\n");
	my $aoh = read_table("$fh", 'auto.row.names' => 1);
	is($aoh->[0]{row_name}, 'r1', 'read_table: auto.row.names synthesizes row_name');
	is($aoh->[0]{a}, 1, 'read_table: auto.row.names aligns remaining columns');
}

#---- read_table errors ----
dies_ok { read_table('/no/such/file/xyz') } 'read_table: dies on missing file';
{
	my $fh = write_tmp("a,b\n1,2\n");
	dies_ok { read_table("$fh", sep => ',', delim => ',') } 'read_table: dies on sep+delim together';
	dies_ok { read_table("$fh", bogus => 1) } 'read_table: dies on unknown arg';
	dies_ok { read_table("$fh", 'output.type' => 'zzz') } 'read_table: dies on bad output.type';
	dies_ok { read_table("$fh", filter => [1, 2]) } 'read_table: dies on non-CODE/HASH filter';
}
{	# ragged data row
	my $fh = write_tmp("a,b\n1,2,3\n");
	dies_ok { read_table("$fh") } 'read_table: dies on alignment error';
}
{	# undef row name for hoh
	my $fh = write_tmp("id,v\n,5\n");
	dies_ok { read_table("$fh", 'output.type' => 'hoh', 'row.names' => 'id') }
		'read_table: hoh dies on undefined row name';
}
{	# filter column not in header
	my $fh = write_tmp("a,b\n1,2\n");
	dies_ok { read_table("$fh", filter => { zzz => sub { 1 } }) }
		'read_table: dies on filter column not in header';
}

#============================================================
# view  (use return_only so nothing prints to the terminal)
#============================================================
{	# AoH
	my $s = view([ { a => 1, b => 2 }, { a => 3, b => 4 } ], return_only => 1);
	like($s, qr/AoH/, 'view: AoH labelled');
	like($s, qr/row/, 'view: AoH reports rows');
}
{	# HoA
	my $s = view({ a => [1, 2], b => [3, 4] }, return_only => 1);
	like($s, qr/HoA/, 'view: HoA labelled');
}
{	# HoH
	my $s = view({ r1 => { a => 1 }, r2 => { a => 2 } }, return_only => 1);
	like($s, qr/HoH/, 'view: HoH labelled');
}
{	# flat hash
	my $s = view({ a => 1, b => 2 }, return_only => 1);
	like($s, qr/Hash/, 'view: flat hash labelled');
}
{	# empty hash
	my $s = view({}, return_only => 1);
	like($s, qr/Hash/, 'view: empty hash handled');
}
{	# n limiting + "more rows" footer
	my $aoh = [ map { { a => $_ } } 1 .. 10 ];
	my $s = view($aoh, n => 3, return_only => 1);
	like($s, qr/more row/, 'view: n limit shows more-rows footer');
}
{	# na string for undef cells
	my $s = view([ { a => undef } ], na => 'NA', return_only => 1);
	like($s, qr/NA/, 'view: custom na string used for undef');
}
{	# explicit columns selection
	my $s = view([ { a => 1, b => 2 } ], cols => ['a'], return_only => 1);
	like($s, qr/\ba\b/, 'view: explicit cols selection');
	unlike($s, qr/^\s*b\s/m, 'view: unselected column omitted from header');
}
{	# color off forced
	my $s = view([ { a => 1 } ], color => 0, return_only => 1);
	unlike($s, qr/\e\[/, 'view: color=>0 emits no ANSI escapes');
}

#---- view errors ----
dies_ok { view('scalar') } 'view: dies on non-ref data';
dies_ok { view([], n => 1, rows => 1) } 'view: dies when both n and rows given';
dies_ok { view([], n => -1) } 'view: dies on non-integer n';
dies_ok { view([], bogus => 1) } 'view: dies on unknown argument';

#============================================================
# memory leak checks (skipped under Devel::Cover)
#============================================================
unless ($INC{'Devel/Cover.pm'}) {
	no_leaks_ok {
		my $df = [ { w => 70, h => 2 } ];
		assign($df, bmi => sub { $_->{w} / $_->{h} });
	} 'assign(): no memory leaks';

	no_leaks_ok {
		my $p = (col('x') > 0) & (col('y') < 5);
		$p->{code}->({ x => 1, y => 1 });
	} 'col(): no memory leaks';

	no_leaks_ok {
		dropna([ { a => 1 }, { a => undef } ], cols => ['a']);
	} 'dropna(): no memory leaks';
}

done_testing();
