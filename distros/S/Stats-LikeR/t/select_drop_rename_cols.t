#!/usr/bin/env perl

require 5.010;
use warnings FATAL => 'all';
use Stats::LikeR;
use Test::Exception; # throws_ok / dies_ok
use Test::More;
use Test::LeakTrace 'no_leaks_ok';

# select_cols / drop_cols / rename_cols: column subset / drop / rename over the
# four shapes.  Row shapes (AoH/HoH/AoA) go through XS and SHARE cell SVs; HoA
# aliases whole column arrayrefs.  Results are shallow VIEWS -- the operation
# never mutates the source, but shared cells/columns are live (see the sharing
# tests below).  AoA columns are 0-based indices; rename_cols dies on AoA.

my $aoa = [ [1,2,3], [4,5,6] ];
my $aoh = [ {a=>1,b=>2,c=>3}, {a=>4,b=>5,c=>6} ];
my $hoa = { a=>[1,4], b=>[2,5], c=>[3,6] };
my $hoh = { r1=>{a=>1,b=>2,c=>3}, r2=>{a=>4,b=>5,c=>6} };

#--------
# select_cols
#--------
is_deeply( select_cols($aoa, 0, 2),        [[1,3],[4,6]],                       'select AoA by index' );
is_deeply( select_cols($aoa, [2,0]),       [[3,1],[6,4]],                       'select AoA reordered (arrayref arg)' );
is_deeply( select_cols($aoh, 'a','c'),     [{a=>1,c=>3},{a=>4,c=>6}],           'select AoH' );
is_deeply( select_cols($hoa, 'c','a'),     {c=>[3,6], a=>[1,4]},                'select HoA' );
is_deeply( select_cols($hoh, 'b'),         {r1=>{b=>2}, r2=>{b=>5}},            'select HoH single column' );
is_deeply( select_cols([ {a=>1,b=>2}, {a=>3,c=>9} ], 'a','c'),
	[ {a=>1,c=>undef}, {a=>3,c=>9} ], 'select AoH ragged: missing cell -> undef' );

# an absent (undef-filled) cell is writable, not the read-only shared undef
{
	my $r = select_cols([ {a=>1}, {a=>2,b=>9} ], 'a','b');   # b absent from row 0
	$r->[0]{b} = 'writable';
	is( $r->[0]{b}, 'writable', 'select undef-fill is a mutable scalar' );
}

#--------
# drop_cols
#--------
is_deeply( drop_cols($aoa, 1),             [[1,3],[4,6]],                       'drop AoA index (re-indexed)' );
is_deeply( drop_cols($aoh, 'b'),           [{a=>1,c=>3},{a=>4,c=>6}],           'drop AoH' );
is_deeply( drop_cols($hoa, 'b'),           {a=>[1,4], c=>[3,6]},                'drop HoA' );
is_deeply( drop_cols($hoh, 'a','c'),       {r1=>{b=>2}, r2=>{b=>5}},            'drop HoH multiple' );
is_deeply( drop_cols([ {a=>1,b=>2}, {a=>3,c=>9} ], 'a'),
	[ {b=>2}, {c=>9} ], 'drop AoH ragged: leaves rows ragged' );

#--------
# rename_cols
#--------
is_deeply( rename_cols($aoh, a=>'x'),      [{x=>1,b=>2,c=>3},{x=>4,b=>5,c=>6}], 'rename AoH (pairs)' );
is_deeply( rename_cols($hoa, {b=>'B'}),    {a=>[1,4], B=>[2,5], c=>[3,6]},      'rename HoA (hashref)' );
is_deeply( rename_cols($hoh, a=>'x', c=>'z'),
	{r1=>{x=>1,b=>2,z=>3}, r2=>{x=>4,b=>5,z=>6}}, 'rename HoH multiple' );
is_deeply( rename_cols($aoh, a=>'b', b=>'a'),
	[{b=>1,a=>2,c=>3},{b=>4,a=>5,c=>6}], 'rename AoH swap a<->b' );

# utf8 column names survive select and rename
{
	my $u = [ { "\x{3b1}" => 1, b => 2 } ];                   # Greek alpha
	is( (select_cols($u, "\x{3b1}"))->[0]{"\x{3b1}"}, 1, 'select utf8 key' );
	my $r = rename_cols($u, "\x{3b1}" => "\x{3b2}");          # alpha -> beta
	is( $r->[0]{"\x{3b2}"}, 1, 'rename utf8 key' );
	ok( !exists $r->[0]{"\x{3b1}"}, 'old utf8 key gone' );
}

#--------
# non-destructive: the source frame is never modified by the operation
#--------
{
	my $src = [ {a=>1,b=>2} ];
	select_cols($src, 'a');
	drop_cols($src, 'b');
	rename_cols($src, a=>'z');
	is_deeply( $src, [ {a=>1,b=>2} ], 'source AoH intact after all three verbs' );
}

#--------
# VIEW semantics: results share the underlying data with the source
#--------
{
	# row shapes share the cell SV itself
	my $src = [ {a=>1, b=>2} ];
	my $sel = select_cols($src, 'a');
	ok( \($sel->[0]{a}) == \($src->[0]{a}), 'select AoH shares the cell scalar' );
	my $ren = rename_cols($src, a=>'A');
	ok( \($ren->[0]{A}) == \($src->[0]{a}), 'rename AoH shares the cell under the new key' );
	my $drp = drop_cols($src, 'b');
	ok( \($drp->[0]{a}) == \($src->[0]{a}), 'drop AoH shares the surviving cell' );

	# HoA shares the whole column arrayref
	my $h   = { a=>[1,2], b=>[3,4] };
	my $hs  = select_cols($h, 'a');
	ok( $hs->{a} == $h->{a}, 'select HoA aliases the column arrayref (view)' );
}

#--------
# ncol/nrow round-trip on results
#--------
is( ncol( select_cols($aoh, 'a','c') ), 2, 'select AoH: ncol drops to 2' );
is( ncol( drop_cols($hoa, 'b') ),       2, 'drop HoA: ncol drops to 2' );
is( nrow( select_cols($hoh, 'b') ),     2, 'select HoH: nrow preserved' );

#--------
# error paths -- validated in Perl before any XS runs
#--------
throws_ok { select_cols($aoh, 'nope') }        qr/column 'nope' not found/,          'select missing AoH col dies';
throws_ok { select_cols($hoa, 'zzz') }         qr/column 'zzz' not found/,           'select missing HoA col dies';
throws_ok { select_cols($aoa, 5) }             qr/out of range \(max index 2\)/,     'select AoA out-of-range dies';
throws_ok { select_cols($aoa, 'a') }           qr/not a non-negative integer/,       'select AoA non-integer dies';
throws_ok { select_cols($aoh, 'a','a') }       qr/duplicate column 'a'/,             'select duplicate dies';
throws_ok { select_cols($aoh) }                qr/at least one column is required/,  'select with no columns dies';
throws_ok { drop_cols($hoh, 'missing') }       qr/column 'missing' not found/,       'drop missing HoH col dies';
throws_ok { rename_cols($aoa, 0=>'x') }        qr/AoA has no column names/,          'rename AoA dies';
throws_ok { rename_cols($aoh, a=>'b') }        qr/collides/,                         'rename onto existing col dies';
throws_ok { rename_cols($aoh, nope=>'x') }     qr/column 'nope' not found/,          'rename missing col dies';
throws_ok { rename_cols($aoh, 'a') }           qr/old => new pairs/,                 'rename odd arg list dies';
throws_ok { select_cols(undef) }               qr/undefined data in first position/,'select undef frame dies';
throws_ok { rename_cols({a=>[1],b=>{x=>1}}, a=>'z') } qr/mixes array and hash/,      'rename mixed hash dies';

#--------
# non-container refs die at classification (message-agnostic, mirrors nrow.t)
#--------
dies_ok { select_cols(sub { 1 }) } 'select code ref dies';
dies_ok { drop_cols(\my $s, 0) }   'drop scalar ref dies';

#--------
# no memory leaks (guarded under Devel::Cover; the XS paths were also verified
# via a net-zero PL_sv_count delta over 20k iterations during development).
#--------
unless ($INC{'Devel/Cover.pm'}) {
	no_leaks_ok { select_cols([ [1,2,3], [4,5,6] ], 0, 2) }              'select_cols(): AoA, no leaks';
	no_leaks_ok { select_cols([ {a=>1,b=>2}, {a=>3,b=>4} ], 'a') }      'select_cols(): AoH, no leaks';
	no_leaks_ok { select_cols([ {a=>1}, {b=>2} ], 'a','b') }            'select_cols(): AoH ragged, no leaks';
	no_leaks_ok { select_cols({ a=>[1,2], b=>[3,4] }, 'a') }            'select_cols(): HoA, no leaks';
	no_leaks_ok { select_cols({ r1=>{a=>1}, r2=>{a=>2} }, 'a') }        'select_cols(): HoH, no leaks';
	no_leaks_ok { drop_cols([ [1,2,3], [4,5,6] ], 1) }                  'drop_cols(): AoA, no leaks';
	no_leaks_ok { drop_cols([ {a=>1,b=>2}, {a=>3,b=>4} ], 'b') }        'drop_cols(): AoH, no leaks';
	no_leaks_ok { drop_cols({ a=>[1,2], b=>[3,4] }, 'b') }              'drop_cols(): HoA, no leaks';
	no_leaks_ok { drop_cols({ r1=>{a=>1,b=>2}, r2=>{a=>3,b=>4} }, 'b') } 'drop_cols(): HoH, no leaks';
	no_leaks_ok { rename_cols([ {a=>1,b=>2}, {a=>3,b=>4} ], a=>'x') }   'rename_cols(): AoH, no leaks';
	no_leaks_ok { rename_cols({ a=>[1,2], b=>[3,4] }, a=>'x') }         'rename_cols(): HoA, no leaks';
	no_leaks_ok { rename_cols({ r1=>{a=>1}, r2=>{a=>2} }, a=>'x') }     'rename_cols(): HoH, no leaks';
}

done_testing();
