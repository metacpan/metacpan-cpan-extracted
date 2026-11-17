#!/usr/bin/env perl
# view() in XS: what the port had to keep, and the few things it changed.
#
# view() and the renderer it shares with summary() were Perl up to 0.3421.
# The layout of a table is covered by t/view.t, t/view2.t, t/view.aoa.t and
# t/view_aoa.t, which the XS passes as the Perl did, and its size by
# t/view.size.t. This file has what those do not reach: the order of a HoH's
# rows, which the XS finds without sorting every key; how a hash of mixed
# values is classified; the argument errors that used to be perl's own; what
# is and is not left behind on the caller's frame; and where the table is
# printed.
#
# There is no reference implementation to take cases from: the table's format
# is this module's own. The expected values are either written out here or
# computed by perl itself -- a HoH's row order is checked against perl's
# sort, which is the order the Perl view() used.
require 5.010;
use strict;
use warnings FATAL => 'all';
use utf8;
use Test::More;
use Test::Exception;
use Test::LeakTrace 'no_leaks_ok';
use B ();
use Stats::LikeR;

$ENV{COLUMNS} = 1000;	# one block of columns, whatever the terminal

sub lines { split /\n/, $_[0] }
sub plain { view($_[0], return_only => 1, color => 0, size => 0, @_[1 .. $#_]) }
# a row's label: everything before the first gap, on the lines between the
# header and the "# ..." footer, if any, and the first line repeated below them
sub labels { my @l = lines($_[0]); shift @l; shift @l; pop @l; pop @l if @l && $l[-1] =~ /^# \.\.\. /; map { /^(.*?)  / ? $1 : $_ } @l }

# A HoH's rows are its keys in perl's sort order, whatever n is. The keys mix
# ASCII, Latin-1 bytes and characters past U+00FF, so that a key held as bytes
# is compared with one held as UTF-8: sort compares them as characters.
{
	my @keys = ('b', 'a', 'B', 'aa', '', 'a b', "\xE9", "\xE9a", "z\xFF", "\x{394}", "\x{e9}\x{394}",
	            "\x{20AC}", "zz", "\x7F", "\xC3\xA9", '10', '9', "\x{1F600}", "a\x{301}", "\xE0");
	my %hoh = map { ($_ => { v => 1 }) } @keys;
	my @sorted = sort keys %hoh;
	is(scalar @sorted, scalar @keys, 'the test keys are distinct');
	for my $n (0, 1, 2, 3, 7, scalar(@keys) - 1, scalar @keys, 1000) {
		my $show = $n < @sorted ? $n : scalar @sorted;
		# a label is the key's own bytes: UTF-8 for a key perl holds as characters
		my @want = map { my $k = $_; utf8::encode($k) if utf8::is_utf8($k); $k } @sorted[0 .. $show - 1];
		my @got = labels(plain(\%hoh, n => $n, max_width => 0));
		is_deeply(\@got, \@want, "HoH, n => $n: the first rows of the sorted keys, in order");
	}
	# many keys, few shown: the rows are still the head of the sorted list
	my %many = map { (sprintf('k%05d', ($_ * 7919) % 20011) => { v => $_ }) } 1 .. 5000;
	my @first = (sort keys %many)[0 .. 5];
	is_deeply([ labels(plain(\%many)) ], \@first, 'HoH of 5000 rows: the six smallest keys, in order');
	like((lines(plain(\%many)))[-2], qr/\A# \.\.\. 4994 more rows\z/, 'and the rest are counted');
}

# A hash is a HoA when any value is an array, whichever value comes first.
# The Perl took the first defined value keys() returned, so a HoA with a
# scalar in it was a HoA on one run and a one-row hash on another. Twenty key
# names put the scalar in twenty places in the hash's order.
{
	for my $name ('a' .. 't') {
		my $hoa = { x => [ 1, 2, 3 ], y => [ 'p', 'q', 'r' ], "note_$name" => 'scalar', "u_$name" => undef };
		my @l = lines(plain($hoa));
		is($l[0], "# HoA: 3 rows x 4 cols\t(showing 3 rows)", "a HoA with a scalar under note_$name is a HoA");
	}
	my @l = lines(plain({ a => [ 1, 2 ], b => { c => 1 } }));
	like($l[0], qr/\A# HoA: 2 rows x 2 cols/, 'arrays and hashes together: a HoA');
	@l = lines(plain({ a => 'x', b => { c => 1 }, d => undef }));
	like($l[0], qr/\A# HoH: 3 rows x 1 col/, 'hashes and scalars together: a HoH');
	@l = lines(plain({ a => 'x', d => undef }));
	like($l[0], qr/\A# Hash: 1 row x 2 cols/, 'neither: a flat hash');
	@l = lines(plain({ a => undef }));
	like($l[0], qr/\A# Hash: 1 row x 1 col/, 'nothing defined: a flat hash');
	# ref() decides, as it always has: a blessed column or row is not one
	@l = lines(plain({ a => bless([ 1, 2 ], 'Obj') }));
	like($l[0], qr/\A# Hash: 1 row x 1 col/, 'a blessed array is a cell, not a column');
	throws_ok { view(bless({ a => [ 1 ] }, 'Obj'), return_only => 1) }
		qr/expected an ARRAY \(AoH\) or HASH \(HoA\/HoH\) reference, got Obj/, 'and a blessed frame is refused by its class';
}

# The call-form errors, each with view's help screen in front of it.
{
	my $aoh = [ { a => 1, b => 'x' } ];
	my @bad = (
		[ [ ],                              qr/undefined data in first position/,                'no arguments' ],
		[ [ undef ],                        qr/undefined data in first position/,                'undef data' ],
		[ [ $aoh, 'n' ],                    qr/arguments after the data must be name => value pairs/, 'an odd option list' ],
		[ [ $aoh, undef, 1 ],               qr/an option name is undefined/,                     'an undef option name' ],
		[ [ $aoh, zzz => 1, aaa => 2, zzz => 3 ], qr/unknown argument\(s\): aaa zzz$/m,          'unknown options, sorted and once each' ],
		[ [ $aoh, n => 1, rows => 1 ],      qr/pass either 'n' or 'rows', not both/,             'n and rows' ],
		[ [ $aoh, n => 2.5 ],               qr/'n'\/'rows' must be a non-negative integer/,      'a fractional n' ],
		[ [ $aoh, rows => '' ],             qr/'n'\/'rows' must be a non-negative integer/,      'an empty rows' ],
		# 1e300, not 1e30: a quadmath perl writes 1e30 out in full, as thirty-one digits, and takes it
		[ [ $aoh, n => 1e300 ],             qr/'n'\/'rows' must be a non-negative integer/,      'an n perl writes with an exponent' ],
		[ [ $aoh, width => undef ],         qr/'width' must be a positive integer/,              'width => undef' ],
		[ [ $aoh, width => '08' ],          qr/'width' must be a positive integer/,              'a width with a leading zero' ],
		[ [ $aoh, width => "80\n" ],        qr/'width' must be a positive integer/,              'a width with a newline' ],
		[ [ $aoh, max_width => -1 ],        qr/'max_width' must be a non-negative integer/,      'a negative max_width' ],
		[ [ $aoh, max_width => 'wide' ],    qr/'max_width' must be a non-negative integer/,      'a max_width that is not a number' ],
		[ [ $aoh, max_width => 2.5 ],       qr/'max_width' must be a non-negative integer/,      'a fractional max_width' ],
		[ [ $aoh, gap => -1 ],              qr/'gap' must be a non-negative integer/,            'a negative gap' ],
		[ [ $aoh, gap => 'x' ],             qr/'gap' must be a non-negative integer/,            'a gap that is not a number' ],
		[ [ $aoh, cols => 'a' ],            qr/'cols' must be an ARRAY reference/,               'cols as a string' ],
		[ [ $aoh, columns => { a => 1 } ],  qr/'cols' must be an ARRAY reference/,               'columns as a hash' ],
		[ [ $aoh, cols => [ 'a', undef ] ], qr/a name in 'cols' is undefined/,                   'an undef name in cols' ],
		[ [ $aoh, colors => 'red' ],        qr/'colors' must be a HASH reference/,               'colors as a string' ],
		[ [ $aoh, colors => [ ] ],          qr/'colors' must be a HASH reference/,               'colors as an array' ],
		[ [ [ [ 1, 2 ] ], cols => [ 'x' ] ], qr/'cols' must hold column indices for an AoA/,     'a column name for an AoA' ],
		[ [ \'s' ],                         qr/expected an ARRAY \(AoH\) or HASH \(HoA\/HoH\) reference, got SCALAR/, 'a scalar reference' ],
		[ [ sub { 1 } ],                    qr/reference, got CODE/,                             'a code reference' ],
		[ [ 'text' ],                       qr/reference, got a non-reference/,                  'a string' ],
	);
	for my $c (@bad) {
		my ($args, $rx, $what) = @$c;
		my @quiet = (@$args > 1 && @$args % 2) ? (return_only => 1) : ();
		my $err = do { local $@; eval { view(@$args, @quiet); 1 } ? '' : $@ };
		like($err, $rx, "$what: the message");
		like($err, qr/\Ausage: view\(/, "$what: under view's usage line");
		like($err, qr/\nview: error: [^\n]*\n\z/, "$what: with 'view: error:' as the last line");
	}
	# an object blessed into a package named HASH is not a hash
	throws_ok { view(bless([ ], 'HASH'), return_only => 1) } qr/\ANot a HASH reference/, 'an array blessed into HASH';
	# what is no longer an error, or never was
	lives_ok { plain($aoh, gap => undef) }       'gap => undef is the default gap';
	is(plain($aoh, gap => undef), plain($aoh, gap => 2), 'which is two spaces');
	is(plain($aoh, max_width => undef), plain($aoh, max_width => 80), 'max_width => undef is 80');
	is(plain($aoh, na => undef, ellipsis => undef), plain($aoh), 'na and ellipsis => undef are the defaults');
	is(plain($aoh, n => "1\n"), plain($aoh, n => 1), 'n may end in a newline, as a line read from a file does');
	is(plain($aoh, n => '007'), plain($aoh, n => 7), 'and may have leading zeros');
	is(plain($aoh, cols => 0), plain($aoh), 'a false cols is no cols');
	is(plain($aoh, cols => 0, columns => [ 'b' ]), plain($aoh, cols => [ 'b' ]), 'and gives way to columns');
	is(plain($aoh, colors => 0, color => 1), plain($aoh, color => 1), 'a false colors is no colors');
	is(plain($aoh, n => 1, n => 0), plain($aoh, n => 0), 'an option given twice: the last one');
	lives_ok { view($aoh, return_only => 1, to => 'NO_SUCH_HANDLE') } "return_only never looks at 'to'";
}

# summary() goes through the same renderer, and its display options are now
# checked in its own name.
{
	my $s = summary([ 1, 2, 3, 4, 5 ], return_only => 1, color => 0);
	my @l = lines($s);
	is($l[0], "# summary: 1 row x 7 cols\t(showing 1 row)", 'summary: the first line, without a size');
	is($l[1], '  # values  Min.  1st Qu.  Median  Mean  3rd Qu.  Max.', 'summary: the header');
	is($l[2], '         5     1        2       3     3        4     5', 'summary: the row');
	is(summary([ 1, 2, 3 ], return_only => 1, color => 0, gap => 0), join("\n",
		"# summary: 1 row x 7 cols\t(showing 1 row)", '# valuesMin.1st Qu.MedianMean3rd Qu.Max.',
		'       3   1    1.5     2   2    2.5   3', ''), 'summary: gap => 0');
	is(summary([ 1, 2, 3 ], return_only => 1, color => 0, width => undef, gap => undef, max_width => undef),
		summary([ 1, 2, 3 ], return_only => 1, color => 0), 'summary: an undef display option is the default');
	throws_ok { summary([ 1, 2, 3 ], return_only => 1, width => 'x') }
		qr/\Ausage: summary\(.*\nsummary: error: 'width' must be a positive integer\n\z/s, 'summary: a bad width';
	throws_ok { summary([ 1, 2, 3 ], return_only => 1, gap => -2) }
		qr/summary: error: 'gap' must be a non-negative integer/, 'summary: a bad gap';
	throws_ok { summary([ 1, 2, 3 ], return_only => 1, colors => 1) }
		qr/summary: error: 'colors' must be a HASH reference/, 'summary: a bad colors';
	my @chunk = lines(summary([ 1, 2, 3 ], return_only => 1, color => 0, width => 30));
	cmp_ok(scalar @chunk, '>', 3, 'summary: a narrow width splits the columns into blocks');
}

# Nothing is left on the frame. The Perl's keys() left an iterator on every
# row it read the columns off; and a cell is now read in place rather than
# copied first, so its number must not be given a string either.
{
	my $pok = sub { B::svref_2object($_[0])->FLAGS & B::SVf_POK };	# of the cell a reference points at
	# $_ + 0 is a new number each time. The HoH's "r$_" stringifies $_ itself,
	# and before perl 5.36 that left a string on it for `i => $_` to copy.
	my %d = (
		AoH => [ map { { i => $_ + 0, x => $_ / 8 } } 1 .. 5 ],
		AoA => [ map { [ $_ + 0, $_ / 8 ] } 1 .. 5 ],
		HoA => { i => [ map { $_ + 0 } 1 .. 5 ], x => [ map { $_ / 8 } 1 .. 5 ] },
		HoH => { map { ("r$_" => { i => $_ + 0, x => $_ / 8 }) } 1 .. 5 },
	);
	my %cell = (
		AoH => sub { (\$d{AoH}[2]{i}, \$d{AoH}[2]{x}) }, AoA => sub { (\$d{AoA}[2][0], \$d{AoA}[2][1]) },
		HoA => sub { (\$d{HoA}{i}[2], \$d{HoA}{x}[2]) }, HoH => sub { (\$d{HoH}{r3}{i}, \$d{HoH}{r3}{x}) },
	);
	for my $kind (sort keys %d) {
		my ($i, $x) = $cell{$kind}->();
		ok(!$pok->($i) && !$pok->($x), "$kind: the cells are numbers with no string to begin with");
		my $out = plain($d{$kind}, color => 1);
		like($out, qr/0\.375/, "$kind: the numbers are shown");
		ok(!$pok->($i), "$kind: an integer cell has no string after view()");
		ok(!$pok->($x), "$kind: nor has a decimal one");
	}
	# an each() in progress on a row, or on the frame, is where it was
	my $row = $d{AoH}[0];
	my %left = %$row;
	my ($k1) = each %$row;
	delete $left{$k1};
	plain($d{AoH});
	my ($k2) = each %$row;
	ok(defined $k2 && exists $left{$k2}, 'an each() on an AoH row goes on from where it was');
	keys %$row;	# reset
	my $hoa = $d{HoA};
	($k1) = each %$hoa;
	plain($hoa);
	($k2) = each %$hoa;
	ok(defined $k2 && $k2 ne $k1, 'and so does one on a HoA');
	keys %$hoa;
	# the caller's option values are not stringified either
	my ($n, $w) = (3, 60);
	plain($d{AoH}, n => $n, width => $w, gap => $n, max_width => $w);
	ok(!$pok->(\$n) && !$pok->(\$w), 'a number passed as an option keeps no string');
}

# An ellipsis given as UTF-8 bytes -- "…" in a file without `use utf8` -- is
# the character it spells. The Perl encoded it a second time, and counted its
# three bytes as three columns.
{
	my $bytes = "\xE2\x80\xA6";
	my $chars = "\x{2026}";
	my $d = { s => [ 'abcdefghij', 'k' ] };
	my $b = plain($d, max_width => 5, ellipsis => $bytes);
	my $c = plain($d, max_width => 5, ellipsis => $chars);
	is($b, $c, 'an ellipsis as UTF-8 bytes renders as the same ellipsis given as a character');
	my @l = lines($b);
	is($l[2], "0  abcd\xE2\x80\xA6", 'four characters are kept and the three bytes follow, once');
	is($l[3], '1  k    ', 'and it is one column wide: the short cell is padded to five');
	# bytes that are not UTF-8 are passed through, cut or not
	my $latin = { s => [ "caf\xE9 au lait", "\xE9" ] };
	@l = lines(plain($latin, max_width => 6));
	is($l[2], "0  caf...", 'a Latin-1 cell is cut by its bytes');
	is($l[3], "1  \xE9     ", 'and a Latin-1 byte is shown as it is, one column wide');
	@l = lines(plain($latin, max_width => 6, ellipsis => $chars));
	is($l[2], "0  caf\xC3\xA9 \xE2\x80\xA6", 'cut with a character ellipsis, the kept bytes become UTF-8 with it');
}

# Where the table goes.
{
	my $name = "J\x{f8}rgensen";
	utf8::upgrade($name);	# characters, as a string read through a :utf8 layer is
	my $d = [ { name => $name, n => 1 } ];
	my $want = plain($d);
	ok(!utf8::is_utf8($want), 'the table is a string of bytes');
	like($want, qr/J\xC3\xB8rgensen/, 'in UTF-8');
	# a plain handle
	{
		open my $fh, '>', \my $buf or die "open: $!";
		my $ret = view($d, to => $fh, color => 0, size => 0);
		close $fh;
		is($buf, $want, "'to': the handle gets the table");
		is($ret, $want, "'to': and it is returned as well");
	}
	# a handle with a :utf8 layer gets the same bytes, not those bytes encoded again
	{
		open my $fh, '>:utf8', \my $buf or die "open: $!";
		view($d, to => $fh, color => 0, size => 0);
		close $fh;
		is($buf, $want, "a ':utf8' handle is written the UTF-8 once");
	}
	# the selected handle, when there is no 'to'
	{
		open my $fh, '>', \my $buf or die "open: $!";
		my $old = select $fh;
		view($d, color => 0, size => 0);
		select $old;
		close $fh;
		is($buf, $want, 'with no to, the table goes to the selected handle');
	}
	# $\ follows it, as it follows any print
	{
		open my $fh, '>', \my $buf or die "open: $!";
		{ local $\ = "<END>"; view($d, to => $fh, color => 0, size => 0); }
		close $fh;
		is($buf, $want . '<END>', '$\\ is appended');
	}
	# a tied handle's PRINT
	{
		package Catch;
		sub TIEHANDLE { bless { got => [ ] }, $_[0] }
		sub PRINT     { my $s = shift; push @{ $s->{got} }, @_; 1 }
		package main;
		local *TH;
		my $obj = tie *TH, 'Catch';
		view($d, to => \*TH, color => 0, size => 0);
		is_deeply($obj->{got}, [ $want ], 'a tied handle is given the table through PRINT');
		my $auto = view($d, to => \*TH, size => 0);
		unlike($auto, qr/\e\[/, 'and is not a terminal, so color stays off');
		undef $obj;	# untie warns while a reference to the object is held
		untie *TH;
	}
	# a handle that is not one, and one that is closed
	throws_ok { view($d, to => 'NO_SUCH_HANDLE', color => 0) } qr/Bad filehandle: NO_SUCH_HANDLE/, 'a name that is no handle';
	{
		open my $fh, '>', \my $buf or die "open: $!";
		close $fh;
		throws_ok { view($d, to => $fh, color => 0) } qr/view: print\(\) on a closed filehandle/, 'a closed handle';
	}
	# color => 'auto' is off for anything that is not a terminal
	{
		open my $fh, '>', \my $buf or die "open: $!";
		view($d, to => $fh, color => 'auto', size => 0);
		close $fh;
		is($buf, $want, "color => 'auto' does not paint a file");
	}
	unlike(view($d, return_only => 1, size => 0), qr/\e\[/, 'nor a table that is only returned');
	like(view($d, return_only => 1, size => 0, color => 'yes'), qr/\e\[/, 'any other true color paints');
	unlike(view($d, return_only => 1, size => 0, color => ''), qr/\e\[/, 'and a false one does not');
}

# Cells that are not plain scalars.
{
	package Str; use overload '""' => sub { ${ $_[0] } }, fallback => 1;
	package Num; use overload '0+' => sub { ${ $_[0] } }, '""' => sub { "<${ $_[0] }>" }, fallback => 1;
	package main;
	my $word = bless \(my $w = 'word'), 'Str';
	my $digits = bless \(my $g = '42'), 'Str';
	my $num = bless \(my $v = 7), 'Num';
	my @l = lines(plain({ a => [ $word, 'x' ], b => [ $digits, 100 ], c => [ $num, 100 ] }));
	is($l[2], '0  word   42  <7>', 'an object is shown by its "" overload');
	is($l[3], '1  x     100  100', 'and aligned by what its numeric conversion looks like');
	# a tied cell is fetched once
	{
		package Once; our $n = 0;
		sub TIESCALAR { bless [ ], $_[0] } sub FETCH { $n++; 'tied!' }
		package main;
		tie my $t, 'Once';
		my $hoa = { x => [ 'a', 'b' ] };
		tie $hoa->{x}[1], 'Once';
		$Once::n = 0;
		my @t = lines(plain($hoa));
		is($t[3], '1  tied!', 'a tied cell is shown');
		is($Once::n, 1, 'and fetched once');
	}
	# tied rows and columns are read through the tie
	{
		require Tie::Array; require Tie::Hash;
		tie my @col, 'Tie::StdArray'; @col = (1, 2, 3);
		tie my %row, 'Tie::StdHash';  %row = (a => 1, b => 'x');
		tie my @rows, 'Tie::StdArray'; @rows = ({ a => 1, b => 'x' }, { a => 2, b => 'y' });
		tie my %frame, 'Tie::StdHash'; %frame = (p => [ 1, 2 ], q => [ 'x', 'y' ]);
		is(plain({ c => \@col }), plain({ c => [ 1, 2, 3 ] }), 'a tied column');
		is(plain([ \%row ]), plain([ { a => 1, b => 'x' } ]), 'a tied row');
		is(plain(\@rows), plain([ { a => 1, b => 'x' }, { a => 2, b => 'y' } ]), 'a tied AoH');
		is(plain(\%frame), plain({ p => [ 1, 2 ], q => [ 'x', 'y' ] }), 'a tied HoA');
		tie my %hoh, 'Tie::StdHash'; %hoh = (r2 => { v => 2 }, r1 => { v => 1 }, r3 => { v => 3 });
		is(plain(\%hoh, n => 2), plain({ r2 => { v => 2 }, r1 => { v => 1 }, r3 => { v => 3 } }, n => 2), 'a tied HoH');
	}
	# a megabyte in one cell is cut like any other
	my @big = lines(plain({ s => [ 'x' x 1_000_000 ] }, max_width => 10));
	is($big[2], '0  xxxxxxx...', 'a very long cell is cut to max_width');
	# a NUL has no width, and is still written
	my @nul = lines(plain({ s => [ "a\0b", 'cc' ] }));
	is($nul[2], "0  a\0b", 'a NUL is passed through and takes no column');
	# a cell that is cut after an escape is cut between its two characters
	my @esc = lines(plain({ s => [ "ab\tcd" ] }, max_width => 4, ellipsis => '~'));
	is($esc[2], '0  ab\\~', 'an escaped tab counts as the two characters it is written as');
}

# memory, on the paths that croak or run the caller's code part-way through
unless ($INC{'Devel/Cover.pm'}) {
	my $aoh = [ { a => 1, b => 'x' }, { a => 2, b => undef } ];
	my %hoh = map { ("k$_" => { v => $_, w => "s$_" }) } 1 .. 40;
	my $hoa = { x => [ 1, 2, 3 ], y => [ 'p', "\x{394}", undef ] };
	my $word = bless \(my $w = 'word'), 'Str';
	my $obj = { a => [ $word, 1 ] };
	plain($aoh); plain(\%hoh); plain($hoa); plain($obj);	# warm up
	no_leaks_ok { my $s = plain(\%hoh, n => 5) }                  'no leak: a HoH, few rows of many';
	no_leaks_ok { my $s = plain(\%hoh, n => 100, cols => ['w']) } 'no leak: a HoH, every row, cols';
	no_leaks_ok { my $s = plain($hoa, max_width => 1, ellipsis => "\x{2026}", color => 1,
	                            colors => { number => '#87afff', string => '1;31', undef => undef }) }
		'no leak: cut cells, a character ellipsis and custom colors';
	no_leaks_ok { my $s = plain($obj) }                           'no leak: an overloaded cell';
	no_leaks_ok { my $s = plain([ [ 1, 2 ], [ 3 ] ], cols => [ 1, 0 ], row_names => 0) } 'no leak: an AoA with cols';
	no_leaks_ok { eval { view($aoh, cols => 'x', return_only => 1) } }       'no leak: a bad cols';
	no_leaks_ok { eval { view($aoh, bogus => 1, return_only => 1) } }        'no leak: an unknown option';
	no_leaks_ok { eval { view($aoh, max_width => -1, return_only => 1) } }   'no leak: a bad max_width';
	no_leaks_ok { eval { view([ [ 1 ] ], cols => [ 'x' ], return_only => 1) } } 'no leak: a bad AoA column';
	no_leaks_ok { eval { view($aoh, to => 'NO_SUCH_HANDLE', color => 0) } }  'no leak: a bad handle';
	no_leaks_ok { my $s = summary([ 1, 2, 3 ], return_only => 1, color => 1) } 'no leak: summary';
	no_leaks_ok { eval { summary([ 1, 2, 3 ], return_only => 1, width => 'x') } } 'no leak: summary, a bad width';
	open my $fh, '>', \my $buf or die "open: $!";
	view($aoh, to => $fh, color => 0);
	no_leaks_ok { view($aoh, to => $fh, color => 0) } 'no leak: printing to a handle';
	close $fh;
}

# A key perl stores downgraded (a UTF-8 "é" held as the byte E9, flagged
# HVhek_WASUTF8) is the UTF-8 string keys() gives back.  Up to 0.3422 the
# HoH row labels and the AoH, HoA and HoH column names were read from the
# stored bytes and printed a lone E9, while a flat hash printed C3 A9.
{
	my $k = "\x{e9}";
	utf8::upgrade($k);
	my $lone = qr/(?<!\xC3)\xE9/;	# an E9 byte that is not the end of a UTF-8 é
	for my $case (
		[ 'AoH column', [ { $k => 5 } ] ],
		[ 'HoA column', { $k => [5] } ],
		[ 'HoH column', { r => { $k => 1 } } ],
		[ 'HoH row label', { $k => { a => 1 }, b => { a => 2 } } ],
		[ 'HoH row label, among n of many', { $k => { a => 1 }, map { ($_ => { a => 2 }) } 'a' .. 'z' }, n => 30 ],
		# every key past ASCII, so a downgraded one can displace a kept one in the heap
		[ 'HoH row label, kept by the heap', { map { my $x = "\x{e9}$_"; utf8::upgrade($x); ($x => { a => 1 }) } 'a' .. 'z' }, n => 3 ],
		[ 'flat hash', { $k => 5 } ],
	) {
		my ($name, $df, @o) = @$case;
		my $out = plain($df, @o);
		like($out, qr/\xC3\xA9/, "a downgraded UTF-8 key prints as UTF-8: $name");
		unlike($out, $lone, "and not as its Latin-1 byte: $name");
	}
	my $heap = { map { my $x = "\x{e9}$_"; utf8::upgrade($x); ($x => { a => 1 }) } 'a' .. 'z' };
	is_deeply([ labels(plain($heap, n => 3)) ], [ map { "\xC3\xA9$_" } qw(a b c) ],
		'the heap keeps the first three downgraded keys, in order');
	no_leaks_ok {
		plain([ { $k => 5 }, { $k => 6, b => 1 } ]);
		plain($heap, n => 3);
	} 'a downgraded UTF-8 key: no memory leaks';
}

# A gap no buffer can hold is a croak, not perl's "Out of memory" exit.
# 2**48 bytes is more than a 64-bit address space maps, so no machine grants
# it (see "Whether an allocation fails" in CLAUDE.md); where size_t is 32 bits
# the gap saturates and the size check before the probe refuses it.
throws_ok { plain([ [ 1, 2 ] ], gap => 2**48) } qr/view: the table is too large to render/,
	'a gap of 2**48 spaces is refused with a croak';

done_testing;
