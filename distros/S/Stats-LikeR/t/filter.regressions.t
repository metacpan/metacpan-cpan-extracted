#!/usr/bin/env perl
# filter() regressions fixed in 0.3217.  Each block names what went wrong up to
# 0.3216; the expected values are what the documented behaviour says, worked by
# hand from the frames here.
#
# - A col() predicate naming a column the frame does not have dies, as R's
#   subset(df, agee > 18) does ("object 'agee' not found").  It used to read
#   undef in every row, so it kept nothing -- or, under !, everything.
# - && || and or on predicates die: a predicate has no truth value.  `&&`
#   used to drop its left operand, because bool returned 1.
# - col('x') > col('y') dies.  It used to keep every row with a numeric x.
# - The result shares the input's rows but not its reference SVs, so writing
#   to a slot of the result no longer writes to the same slot of the input.
# - $_ and $_[0] are the predicate's own reference to the row: `$_ = undef`
#   used to clear the caller's AoH row, and on a HoA crashed perl.
# - A predicate that deletes and re-stores a cell of the HoA row buffer, or
#   deletes its own row from a HoH or a column from a HoA, sees and returns the
#   right rows; the first used to overwrite a value the predicate kept, the
#   other two to crash perl.
# - Integer literals and cells compare exactly when either is a UV.
# - A tied cell is FETCHed once by a string comparison (perl 5.14 and later;
#   5.10 and 5.12 have no sv_eq_flags() and FETCH it twice).
# - A cell that is an object with overloaded operators is compared by its
#   class, as the closure compares it: the compiled test hands that row to the
#   closure.  It used to take the object for a non-number (and compare a
#   string op on its stringification), so the two paths disagreed.
require 5.010;
use strict;
use warnings FATAL => 'all';
use Stats::LikeR;
use Test::More;
use Test::LeakTrace 'no_leaks_ok';
use B ();

# the same predicate with its plan removed: forces the closure path
sub noplan { bless { code => $_[0]{code}, cols => $_[0]{cols} }, 'Stats::LikeR::col' }
sub frames {	# the same 3-row frame in each shape
	my $aoh = [ { x => 1, s => 'a' }, { x => 2, s => 'b' }, { x => 3, s => 'c' } ];
	my $hoa = { x => [ 1, 2, 3 ], s => [ qw(a b c) ] };
	my $hoh = { r1 => { %{ $aoh->[0] } }, r2 => { %{ $aoh->[1] } }, r3 => { %{ $aoh->[2] } } };
	return ([ AoH => $aoh ], [ HoA => $hoa ], [ HoH => $hoh ]);
}

# --- an unknown column dies --------------------------------------------------
{
	my $re = qr/^filter: column 'agee' not found in data at /;
	my @preds = (
		[ 'numeric'        => col('agee') > 18 ],
		[ 'string'         => col('agee') eq 'x' ],
		[ 'closure path'   => noplan(col('agee') > 18) ],
		[ 'negated'        => !(col('agee') > 18) ],
		[ 'right of &'     => (col('x') > 0) & (col('agee') > 18) ],
		[ 'left of |'      => (col('agee') > 18) | (col('x') > 0) ],
		[ '->match'        => col('agee')->match('^1') ],
		[ '->nomatch'      => col('agee')->nomatch('^1') ],
	);
	for my $f (frames()) {
		for my $p (@preds) {
			for my $out (undef, 'aoh', 'hoa') {
				my @o = defined $out ? ('output_type' => $out) : ();
				my $label = "$f->[0] -> " . ($out // 'own shape') . ", $p->[0]";
				eval { filter($f->[1], $p->[1], @o) };
				like($@, $re, "unknown column dies: $label");
			}
		}
	}
	# the name in the message keeps its characters
	my $u = { "\x{e9}t\x{e9}" => [ 1, 2 ] };
	eval { filter($u, col("\x{e9}t\x{e0}") > 0) };
	like($@, qr/^filter: column '\x{e9}t\x{e0}' not found/, 'a UTF-8 name is reported as itself');
	ok(eval { filter($u, col("\x{e9}t\x{e9}") > 0); 1 }, 'and the UTF-8 name that is there is found');
	# the first missing name is the one reported
	eval { filter({ x => [1] }, (col('p') > 0) & (col('q') > 0)) };
	like($@, qr/column 'p'/, 'the first missing column is named');
}

# --- what is not an unknown column ------------------------------------------
{
	# a column only some rows have is a column of the frame
	my $sparse = [ { x => 1 }, { x => 2 }, { y => 5 } ];
	is_deeply(filter($sparse, col('y') > 0), [ { y => 5 } ], 'AoH: a column in one row only is found');
	is_deeply(filter($sparse, col('y') > 9), [], 'AoH: and can still keep nothing');
	my $hsparse = { a => { x => 1 }, b => { y => 5 } };
	is_deeply(filter($hsparse, col('y') > 0), { b => { y => 5 } }, 'HoH: a column in one row only is found');
	# no rows: an AoH or HoH has no columns to check against
	is_deeply(filter([], col('nope') > 0), [], 'empty AoH: nothing to check');
	is_deeply(filter({}, col('nope') > 0), {}, 'empty hash: nothing to check');
	is_deeply(filter([], col('nope') > 0, 'output_type' => 'hoa'), {}, 'empty AoH -> hoa');
	# a HoA's columns are its keys, rows or not
	is_deeply(filter({ x => [] }, col('x') > 0), { x => [] }, 'HoA with no rows: its column is found');
	eval { filter({ x => [] }, col('nope') > 0) };
	like($@, qr/column 'nope' not found/, 'HoA with no rows: an unknown column still dies');
	# a plain sub names no columns, and a hand-built col object without {cols}
	# is not checked
	is_deeply(filter([ { x => 1 } ], sub { defined $_->{nope} }), [], 'a sub is not checked');
	my $bare = bless { code => (col('nope') > 0)->{code} }, 'Stats::LikeR::col';
	is_deeply(filter([ { x => 1 } ], $bare), [], 'a col object without {cols} is not checked');
	# a column present in every row but undef everywhere is still a column
	is_deeply(filter([ { x => undef } ], col('x') > 0), [], 'an all-undef column is found');
	# cols are recorded once each, in first-use order
	my $p = ((col('b') > 0) & (col('a') > 0)) | !(col('b') eq 'z');
	is_deeply($p->{cols}, [ 'b', 'a' ], '{cols}: distinct names, first use first');
	is_deeply(col('m')->match('x')->{cols}, [ 'm' ], '{cols}: ->match records its column');
}

# --- predicates have no truth value; columns are not operands ----------------
{
	my $hoa = { x => [ 1 .. 6 ], y => [ 6, 5, 4, 3, 2, 1 ] };
	my $re = qr/^col\(\): a predicate has no truth value/;
	eval { filter($hoa, col('x') > 4 && col('y') > 1) };
	like($@, $re, '&& dies (it used to keep only col(y) > 1)');
	eval { filter($hoa, col('x') > 4 || col('y') > 1) };
	like($@, $re, '|| dies');
	eval { my $r = (col('x') > 4 and col('y') > 1) };
	like($@, $re, 'and dies');
	eval { if (col('x') > 4) { 1 } };
	like($@, $re, 'if (predicate) dies');
	is_deeply(filter($hoa, (col('x') > 4) & (col('y') > 1)), { x => [5], y => [2] },
		'& is the way to say it');
	for my $op (qw(> < >= <= == != gt lt ge le eq ne)) {
		my $x = col('x');
		my $y = col('y');
		eval "my \$p = \$x $op \$y; 1" and fail("$op between two columns lived");
		like($@, qr/^col\(\): '\Q$op\E' compares a column with a value, not with another column/,
			"col('x') $op col('y') dies");
	}
}

# --- the result does not share the input's reference SVs ----------------------
{
	my $aoh = [ { x => 1 }, { x => 2 } ];
	my $r = filter($aoh, col('x') > 0);
	$r->[0] = 'gone';
	is_deeply($aoh, [ { x => 1 }, { x => 2 } ], 'AoH -> AoH: writing a result slot leaves the input alone');
	$r = filter($aoh, sub { 1 });
	$r->[1] = undef;
	is_deeply($aoh, [ { x => 1 }, { x => 2 } ], 'AoH -> AoH, sub: the same');
	$r = filter($aoh, col('x') > 0);
	$r->[0]{x} = 10;
	is($aoh->[0]{x}, 10, 'AoH -> AoH: the rows themselves are still shared, as documented');
	$aoh->[0]{x} = 1;

	my $hoh = { a => { x => 1 }, b => { x => 2 } };
	for my $pred (col('x') > 0, sub { 1 }) {
		my $h = filter($hoh, $pred);
		$h->{a} = 'gone';
		is_deeply($hoh, { a => { x => 1 }, b => { x => 2 } }, 'HoH -> HoH: writing a result slot leaves the input alone');
		my $a = filter($hoh, $pred, 'output_type' => 'aoh');
		$_ = 'gone' for @$a;
		is_deeply($hoh, { a => { x => 1 }, b => { x => 2 } }, 'HoH -> AoH: the same');
	}
}

# --- $_ and $_[0] are the predicate's own -------------------------------------
{
	my $aoh = [ { x => 1 }, { x => 2 }, { x => 3 } ];
	my $r = filter($aoh, sub { my $k = $_->{x} > 1; $_ = undef; $k });
	is_deeply($aoh, [ { x => 1 }, { x => 2 }, { x => 3 } ], 'AoH: $_ = undef leaves the input row alone');
	is_deeply($r, [ { x => 2 }, { x => 3 } ], 'AoH: and the rows kept are the rows tested');
	$r = filter($aoh, sub { my $k = $_[0]{x} < 3; $_[0] = 5; $k });
	is_deeply($aoh, [ { x => 1 }, { x => 2 }, { x => 3 } ], 'AoH: $_[0] = 5 leaves the input row alone');
	is_deeply($r, [ { x => 1 }, { x => 2 } ], 'AoH: and the rows kept are the rows tested');

	my $hoh = { a => { x => 1 }, b => { x => 2 } };
	$r = filter($hoh, sub { my $k = $_->{x} > 1; $_ = undef; $k });
	is_deeply($hoh, { a => { x => 1 }, b => { x => 2 } }, 'HoH: $_ = undef leaves the input row alone');
	is_deeply($r, { b => { x => 2 } }, 'HoH: and the rows kept are the rows tested');

	# HoA: this used to free the row buffer under filter() and crash perl
	my $hoa = { x => [ 1 .. 6 ], y => [ 11 .. 16 ] };
	is_deeply(filter($hoa, sub { my $k = $_->{x} > 4; $_ = 5; $k }), { x => [ 5, 6 ], y => [ 15, 16 ] },
		'HoA -> HoA: $_ = 5 in the predicate');
	is_deeply(filter($hoa, sub { my $k = $_->{x} > 4; $_[0] = undef; $k }, 'output_type' => 'aoh'),
		[ { x => 5, y => 15 }, { x => 6, y => 16 } ], 'HoA -> AoH: $_[0] = undef in the predicate');
	is_deeply($hoa, { x => [ 1 .. 6 ], y => [ 11 .. 16 ] }, 'HoA: the input is untouched');
}

# --- predicates that rearrange the row or the frame ---------------------------
{
	my $hoa = { x => [ 1 .. 6 ], y => [ 11 .. 16 ] };
	for my $out (undef, 'aoh') {
		my @o = defined $out ? ('output_type' => $out) : ();
		my (@kept, @seen);
		my $r = filter($hoa, sub {
			push @seen, $_->{x};
			push @kept, \(delete $_->{x});	# keep the cell itself
			$_->{x} = 0;					# and put another under its name
			$_[1] % 2;
		}, @o);
		is_deeply(\@seen, [ 1 .. 6 ], 'HoA ' . ($out // 'hoa') . ': a predicate that re-stores a cell sees every row');
		is_deeply([ map { $$_ } @kept ], [ 1 .. 6 ], 'HoA ' . ($out // 'hoa') . ': and the cells it kept are not overwritten');
		is_deeply($r, defined $out ? [ { x => 0, y => 12 }, { x => 0, y => 14 }, { x => 0, y => 16 } ]
		                           : { x => [ 2, 4, 6 ], y => [ 12, 14, 16 ] },
			'HoA ' . ($out // 'hoa') . ': and the result is right');
	}
	is_deeply($hoa, { x => [ 1 .. 6 ], y => [ 11 .. 16 ] }, 'HoA: the input is untouched');

	# a HoH predicate that deletes its own row used to free it before it was stored
	for my $out (undef, 'aoh', 'hoa') {
		my $hoh = { map { ("r$_" => { x => $_ }) } 1 .. 5 };
		my $r = filter($hoh, sub { delete $hoh->{ $_[1] }; $_->{x} != 3 }, defined $out ? ('output_type' => $out) : ());
		my @x = !defined $out ? map { $_->{x} } values %$r
		      : $out eq 'aoh' ? map { $_->{x} } @$r
		      : @{ $r->{x} };
		is_deeply([ sort @x ], [ 1, 2, 4, 5 ], 'HoH -> ' . ($out // 'hoh') . ': a predicate that deletes its own row');
		is_deeply($hoh, {}, 'HoH -> ' . ($out // 'hoh') . ': and the frame is as the predicate left it');
	}

	# a HoA predicate that deletes a column used to free the array being read
	for my $out (undef, 'aoh') {
		my $f = { x => [ 1 .. 4 ], y => [ 5 .. 8 ] };
		my $r = filter($f, sub { delete $f->{y}; $_->{x} > 2 }, defined $out ? ('output_type' => $out) : ());
		is_deeply($r, defined $out ? [ { x => 3, y => 7 }, { x => 4, y => 8 } ] : { x => [ 3, 4 ], y => [ 7, 8 ] },
			'HoA -> ' . ($out // 'hoa') . ': a predicate that deletes a column');
	}
}

# --- integers compare exactly, IV or UV ---------------------------------------
{
	my $ivmax = ~0 >> 1;	# IV_MAX for this perl: 2**63-1, or 2**31-1 where ivsize is 4
	my $uv = $ivmax;
	$uv++;				# IV_MAX + 1, which only a UV holds
	ok(B::svref_2object(\$uv)->FLAGS & B::SVf_IVisUV(), 'the cell is a UV');
	my $f = { x => [ $uv ] };
	my @cases = (	# [ predicate, keeps the row ]
		[ '<= IV_MAX', col('x') <= $ivmax, 0 ],
		[ '>  IV_MAX', col('x') >  $ivmax, 1 ],
		[ '== IV_MAX', col('x') == $ivmax, 0 ],
		[ '!= IV_MAX', col('x') != $ivmax, 1 ],
		[ '== itself', col('x') == $uv,    1 ],
		[ 'IV_MAX >= cell', $ivmax >= col('x'), 0 ],
		[ '>= -1',     col('x') >= -1,     1 ],
	);
	for my $c (@cases) {
		my ($name, $p, $keeps) = @$c;
		is(scalar @{ filter($f, $p)->{x} }, $keeps, "UV cell $name (compiled)");
		is(scalar @{ filter($f, noplan($p))->{x} }, $keeps, "UV cell $name (closure)");
	}
	my $g = { x => [ $ivmax, -1 ] };	# IV cells against a UV literal
	is_deeply(filter($g, col('x') < $uv)->{x}, [ $ivmax, -1 ], 'IV cells < a UV literal');
	is_deeply(filter($g, col('x') >= $uv)->{x}, [], 'IV cells >= a UV literal');
}

# --- a tied cell is FETCHed once by a string comparison -----------------------
{
	package CountFetch;
	our $n = 0;
	sub TIESCALAR { my ($c, $v) = @_; bless \$v, $c }
	sub FETCH { $n++; ${ $_[0] } }
	sub STORE { ${ $_[0] } = $_[1] }
	package main;
	my @col = (undef, undef, undef);
	tie $col[$_], 'CountFetch', (qw(a b c))[$_] for 0 .. 2;
	my $f = { s => \@col };
	for my $op (qw(eq lt)) {
		$CountFetch::n = 0;
		my $p = $op eq 'eq' ? col('s') eq 'b' : col('s') lt 'b';
		filter($f, $p, 'output_type' => 'aoh');
		my $per_cell = $] >= 5.013006 ? 1 : 2;	# no sv_eq_flags()/sv_cmp_flags() before 5.13.6
		is($CountFetch::n - 1, 3 * $per_cell, "string $op: each tied cell FETCHed $per_cell time(s) to be tested")
			or diag("FETCH count $CountFetch::n");
	}
}

# --- cells that are objects with overloaded operators ------------------------
{
	# Rev compares in reverse: its <=> and cmp disagree with its own 0+ and "",
	# so a test that numified or stringified it would get the opposite answer.
	package Rev;
	use overload
		'<=>' => sub { my ($s, $o, $sw) = @_; my $r = (ref $o ? $$o : $o) <=> $$s; $sw ? -$r : $r },
		'cmp' => sub { my ($s, $o, $sw) = @_; my $r = (ref $o ? $$o : $o) cmp $$s; $sw ? -$r : $r },
		'0+'  => sub { ${ $_[0] } },
		'""'  => sub { '' . ${ $_[0] } },
		fallback => 1;
	sub new { my ($c, $v) = @_; bless \$v, $c }
	package main;

	# by hand: Rev(5) > 2 is 2 <=> 5, false; Rev(1) > 2 is 2 <=> 1, true.
	# Rev('b') lt 'c' is 'c' cmp 'b', false; Rev('d') lt 'c' is true.
	my %c = (
		x => [ Rev->new(5), Rev->new(1), 7, undef, 0 ],
		s => [ Rev->new('b'), Rev->new('d'), 'a', 'z', 'b' ],
		n => [ 1 .. 5 ],
	);
	my $hoa = { map { ($_ => [ @{ $c{$_} } ]) } keys %c };
	my $aoh = [ map { my $i = $_; +{ map { ($_ => $c{$_}[$i]) } keys %c } } 0 .. 4 ];
	my $hoh = { map { ("r$_" => $aoh->[$_]) } 0 .. 4 };
	my @cases = (	# [ name, predicate, the n of the rows it keeps ]
		[ 'num >',         col('x') > 2,                          [ 2, 3 ] ],
		[ 'num swapped',   2 < col('x'),                          [ 2, 3 ] ],
		[ 'num ==',        col('x') == 5,                         [ 1 ] ],
		[ 'not',           !(col('x') > 2),                       [ 1, 4, 5 ] ],
		[ 'str lt',        col('s') lt 'c',                       [ 2, 3, 5 ] ],
		[ 'str eq',        col('s') eq 'b',                       [ 1, 5 ] ],
		[ 'and, plain col', (col('x') > 2) & (col('n') > 2),      [ 3 ] ],
		[ 'or, two objects', (col('x') > 2) | (col('s') lt 'c'),  [ 2, 3, 5 ] ],
	);
	for my $cs (@cases) {
		my ($name, $p, $want) = @$cs;
		is_deeply(filter($hoa, $p)->{n}, $want, "object cells, $name: HoA");
		is_deeply([ map { $_->{n} } @{ filter($hoa, $p, 'output_type' => 'aoh') } ], $want, "object cells, $name: HoA -> aoh");
		is_deeply([ map { $_->{n} } @{ filter($aoh, $p) } ], $want, "object cells, $name: AoH");
		is_deeply(filter($aoh, $p, 'output_type' => 'hoa')->{n}, $want, "object cells, $name: AoH -> hoa");
		is_deeply([ sort { $a <=> $b } map { $_->{n} } values %{ filter($hoh, $p) } ], $want, "object cells, $name: HoH");
		is_deeply([ sort { $a <=> $b } @{ filter($hoh, $p, 'output_type' => 'hoa')->{n} } ], $want, "object cells, $name: HoH -> hoa");
		is_deeply(filter($hoa, noplan($p))->{n}, $want, "object cells, $name: the closure agrees");
	}
	# only the rows holding an object go to the closure
	my $calls = 0;
	my $p = col('x') > 2;
	my $orig = $p->{code};
	my $spy = bless { code => sub { $calls++; $orig->(@_) }, plan => $p->{plan}, cols => $p->{cols} }, 'Stats::LikeR::col';
	filter($hoa, $spy);
	is($calls, 2, 'the closure is asked about the two object rows only');
	$calls = 0;
	filter({ x => [ 1 .. 1000 ] }, $spy);
	is($calls, 0, 'and never about a frame of plain numbers');
	# Math::BigInt, the case that found this
	require Math::BigInt;
	my $big = { x => [ Math::BigInt->new(5), Math::BigInt->new(1) ], n => [ 1, 2 ] };
	is_deeply(filter($big, col('x') > 2)->{n}, [ 1 ], 'Math::BigInt 5 > 2 is kept');
	is_deeply(filter($big, col('x') == 1)->{n}, [ 2 ], 'Math::BigInt 1 == 1 is kept');
}

# --- memory -------------------------------------------------------------------
unless ($INC{'Devel/Cover.pm'}) {
	my $LA	= [ { x => 1, y => 'p' }, { x => 2, y => 'q' } ];
	my $LHA = { x => [ 1, 2, 3 ], y => [ qw(p q r) ] };
	my $LH	= { a => { x => 1 }, b => { x => 2 } };
	my $bad = col('nope') > 0;
	no_leaks_ok { eval { filter($LA,  $bad) } }			'no leak: unknown column, AoH';
	no_leaks_ok { eval { filter($LHA, $bad) } }			'no leak: unknown column, HoA';
	no_leaks_ok { eval { filter($LH,  $bad, 'output_type' => 'hoa') } }	'no leak: unknown column, HoH';
	no_leaks_ok { filter($LA,  sub { $_ = undef; 1 }) }		'no leak: $_ cleared, AoH';
	no_leaks_ok { filter($LHA, sub { $_ = undef; 1 }) }		'no leak: $_ cleared, HoA';
	no_leaks_ok { filter($LHA, sub { $_ = undef; 1 }, 'output_type' => 'aoh') }	'no leak: $_ cleared, HoA -> aoh';
	no_leaks_ok { my @k; filter($LHA, sub { push @k, \(delete $_->{x}); $_->{x} = 0; 1 }) }	'no leak: cell re-stored';
	no_leaks_ok { my @k; filter($LHA, sub { push @k, \(delete $_->{x}); $_->{x} = 0; 1 }, 'output_type' => 'aoh') }	'no leak: cell re-stored, -> aoh';
	no_leaks_ok { filter($LH,  sub { 1 }) }				'no leak: HoH kept rows';
	no_leaks_ok { filter($LH,  sub { 1 }, 'output_type' => 'hoa') }	'no leak: HoH -> hoa kept rows';
	no_leaks_ok { my $h = { a => { x => 1 }, b => { x => 2 } }; filter($h, sub { delete $h->{ $_[1] }; 1 }) }	'no leak: HoH row deleted by the predicate';
	no_leaks_ok { eval { filter($LH, sub { die "x\n" }) } }	'no leak: HoH, dying predicate';
	my $LO	= { x => [ Rev->new(5), 3, Rev->new(1) ], s => [ 'a', Rev->new('b'), 'c' ] };
	my $LOA = [ map { +{ x => $LO->{x}[$_], s => $LO->{s}[$_] } } 0 .. 2 ];
	no_leaks_ok { filter($LO,  (col('x') > 2) | (col('s') lt 'c')) }	'no leak: object cells, HoA';
	no_leaks_ok { filter($LO,  col('x') > 2, 'output_type' => 'aoh') }	'no leak: object cells, HoA -> aoh';
	no_leaks_ok { filter($LOA, col('x') > 2) }							'no leak: object cells, AoH';
	no_leaks_ok { filter({ map { ("r$_" => $LOA->[$_]) } 0 .. 2 }, col('x') > 2, 'output_type' => 'hoa') }	'no leak: object cells, HoH -> hoa';
	my $die = bless { code => sub { die "x\n" }, plan => (col('x') > 2)->{plan}, cols => ['x'] }, 'Stats::LikeR::col';
	no_leaks_ok { eval { filter($LO, $die) } }							'no leak: object cells, dying closure';
}

done_testing;
