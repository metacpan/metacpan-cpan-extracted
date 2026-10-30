#!/usr/bin/env perl
#
# aoh2h(): the bugs fixed in 0.3218, and what its move to XS had to keep.
#
# Up to 0.3217 aoh2h() was a Perl loop. 0.3218 moves the loop into LikeR.xs
# (aoh2h_fold) and fixes four bugs found while reviewing it. The first half
# tests each fix, and those tests fail on 0.3217; beside them are tests of what
# each fix must leave alone, which pass on both:
#
#  1. A key cell holding a reference was turned into its address: a row
#     { variable => [1, 2], value => 1 } came back as
#     { 'ARRAY(0x611ec9f965f8)' => 1 }. h2aoh() already refused reference
#     values for this reason. A reference key now dies, unless it is an object
#     that overloads its operators, whose string form is a fair key.
#  2. An undef option name -- aoh2h($aoh, undef, 1), and the same for h2aoh() --
#     died with perl's "Use of uninitialized value within @_ in list
#     assignment at .../LikeR.pm line 1169", which the module's FATAL warnings
#     made fatal, and which named a line of LikeR.pm rather than the option.
#  3. A blessed row, or a blessed array of rows, was refused as "not a
#     hashref" (ref() eq 'HASH'), although it is one and aoh2hoa() takes it.
#  4. The duplicate-key message named the key but not the row, although every
#     other message names the row and the documentation says all of them do.
#
# The second half holds the XS version to what the Perl one did: a key is the
# string perl itself makes of the cell; the caller's cells are left as they
# were; a tied frame sees the same EXISTS and FETCH calls in the same order; and
# nothing leaks, whether the call returns or croaks. All of it passes on 0.3217
# but one thing the XS version does better: an overloaded key is stringified
# once per row, where 0.3217 did it twice (for exists() and again for the
# store), so those three tests fail there.
#
# The expected tie sequences in "tied rows" were recorded from 0.3217's Perl
# loop on perl-5.44.0, with the tie classes below. They follow from that loop's
# order -- exists() on both columns, then fetch the key, then fetch the value
# only for a row that is kept -- so they can be re-derived by reading aoh2h() in
# Stats-LikeR-0.3217.tar.gz's lib/Stats/LikeR.pm, or by running this file
# against an installed 0.3217, where every "tied rows" test passes.
#
# 0.33 generalised aoh2h() into df2h(), which takes an AoA, HoA or HoH as well
# as an AoH, and made aoh2h a second name for it. Its messages therefore begin
# "df2h:" where 0.3218's began "aoh2h:", and two tests below changed meaning on
# purpose: a blessed hash is now a frame (a HoA or HoH), and a blessed array in
# an array makes an AoA. The other shapes are tested in t/df2h.t.
#
# Values invented for the test. aoh2h() is tibble::deframe() in R and
# Series.to_dict() in pandas, but nothing tested here -- references, blessing,
# ties, option parsing, SV flags -- has a counterpart in either.

require 5.010;
use strict;
use warnings FATAL => 'all';
use B ();
use Hash::Util qw(lock_keys);
use Scalar::Util qw(dualvar refaddr);
use Stats::LikeR;
use Test::More;
use Tie::Hash ();	# Tie::StdHash, for the rows tied below

# Imported at compile time for no_leaks_ok's (&;$) prototype, as
# t/tied.frames.t does. Without the module only the leak checks are skipped.
my $HAVE_LEAKTRACE;
BEGIN {
	$HAVE_LEAKTRACE = eval {
		require Test::LeakTrace;
		Test::LeakTrace->import('no_leaks_ok');
		1;
	};
}

sub err (&) { my $code = shift; eval { $code->(); 1 } ? '' : "$@" }
sub kv { my $h = shift; join ',', map { "$_=" . (defined $h->{$_} ? $h->{$_} : 'undef') } sort keys %$h }

{	package Str;	# an object whose class says what its string is
	use overload '""' => sub { 'S:' . $_[0][0] }, fallback => 1;
}
{	package Smile;	# ... and one whose string is not Latin-1
	use overload '""' => sub { "\x{263A}" }, fallback => 1;
}
{	package Counted;	# counts its stringifications
	our $N = 0;
	use overload '""' => sub { $N++; 'counted' }, fallback => 1;
}
{	package Dies;	# a stringification that croaks
	use overload '""' => sub { die "no string for you\n" }, fallback => 1;
}

#----------------------------------------------------------------------------
# 1. A reference key dies, unless it overloads its operators.
{
	my $e = err { aoh2h([ { variable => 'a', value => 1 }, { variable => [ 1, 2 ], value => 2 } ]) };
	like($e, qr/^df2h: index 1 has a reference in 'variable' \(ARRAY\); a hash key would be its address/,
		'an arrayref key dies, naming the row, the column and the kind');
	like(err { aoh2h([ { variable => { a => 1 }, value => 1 } ]) }, qr/\(HASH\)/,
		'a hashref key dies');
	like(err { aoh2h([ { variable => \'x', value => 1 } ]) }, qr/\(SCALAR\)/,
		'a scalar ref key dies');
	like(err { aoh2h([ { variable => sub { 1 }, value => 1 } ]) }, qr/\(CODE\)/,
		'a code ref key dies');
	like(err { aoh2h([ { gene => bless({}, 'Plain'), n => 1 } ], var_name => 'gene', value_name => 'n') },
		qr/index 0 has a reference in 'gene' \(Plain\)/,
		'a blessed key that overloads nothing dies, naming its class');

	is_deeply(aoh2h([ { variable => bless([7], 'Str'), value => 1 } ]), { 'S:7' => 1 },
		'an object that overloads "" is keyed by its string');
	my $rx = qr/ab+c/i;
	is_deeply(aoh2h([ { variable => $rx, value => 1 } ]), { "$rx" => 1 },
		'a qr// is keyed by its pattern');
	like(err { aoh2h([ { variable => \*STDOUT, value => 1 } ]) }, qr/\(GLOB\)/,
		'a reference to a glob dies; a glob itself is a key (see below)');
	my $h = aoh2h([ { variable => bless([], 'Smile'), value => 1 } ]);
	is_deeply([ keys %$h ], [ "\x{263A}" ], 'an overloaded string outside Latin-1 keeps its characters');

	# the value column was never restricted, and still is not
	my $ref = [ 1, 2 ];
	my $v = aoh2h([ { variable => 'a', value => $ref } ]);
	is(refaddr($v->{a}), refaddr($ref), 'a reference value is still shared with the input');
}

#----------------------------------------------------------------------------
# 2. An undef option name dies in the function's own words.
{
	my $e = err { aoh2h([], undef, 1) };
	like($e, qr/\ndf2h: error: an option name is undefined\n\z/, 'aoh2h: an undef option name gets its own message');
	unlike($e, qr/uninitialized|LikeR\.pm line/, "aoh2h: and not perl's warning about LikeR.pm");
	like(err { aoh2h([], var_name => 'k', undef, 'v') }, qr/\ndf2h: error: an option name is undefined\n\z/,
		'aoh2h: in any position');

	$e = err { h2aoh({}, undef, 1) };
	like($e, qr/\nh2aoh: error: an option name is undefined\n\z/, 'h2aoh: an undef option name gets its own message');
	unlike($e, qr/uninitialized|LikeR\.pm line/, "h2aoh: and not perl's warning about LikeR.pm");

	# an undef option *value* was always fine: it means the default
	is_deeply(aoh2h([ { variable => 'a', value => 1 } ], var_name => undef), { a => 1 },
		'an undef option value still means the default');
}

#----------------------------------------------------------------------------
# 3. Blessed rows and frames are arrays of hashes too.
{
	# eval: 0.3217 died on both, which would end the file here
	is_deeply(scalar eval { aoh2h([ bless({ variable => 'a', value => 1 }, 'Row') ]) }, { a => 1 },
		'a blessed row is read');
	is_deeply(scalar eval { aoh2h(bless([ { variable => 'a', value => 1 } ], 'Frame')) }, { a => 1 },
		'a blessed frame is read');
	# 0.33: both are frames now, and fail only for lacking the two columns
	like(err { aoh2h(bless({ k => [] }, 'Frame')) }, qr/^df2h: no 'variable' column/,
		'a blessed hash is a frame, a HoA here');
	like(err { aoh2h([ bless([], 'Row') ]) }, qr/^df2h: index 0 has no column 0/,
		'a blessed array is a row of an AoA');
}

#----------------------------------------------------------------------------
# 4. The duplicate-key message names the row.
{
	my @rows = ({ variable => 'a', value => 1 }, { variable => 'b', value => 2 },
	            { variable => 'a', value => 3 });
	is(err { aoh2h(\@rows) },
		"df2h: duplicate key 'a' has >= 2 occurrences, the first repeat at index 2\n",
		'the duplicate message names the index of the first repeat');
	my @tied = map { my %t; tie %t, 'Tie::StdHash'; %t = %$_; \%t } @rows;
	is(err { aoh2h(\@tied) },
		"df2h: duplicate key 'a' has >= 2 occurrences, the first repeat at index 2\n",
		'and the same for tied rows, which find it a different way');
}

#----------------------------------------------------------------------------
# Keys are the strings perl makes of the cells.
{
	my $printed = 42; my $s = "$printed";	# a number carrying a cached string
	my $up = "caf\xe9"; utf8::upgrade($up);
	my @keys = (1, -1, 0, -0.0, 0.1 + 0.2, 1e21, 1e-7, 18446744073709551615, -9223372036854775807 - 1,
		9**9**9, -9**9**9, '1.0', '01', ' 1', "a\0b", "caf\xc3\xa9", $up, "\x{263A}",
		dualvar(5, 'five'), 3.0, 2**53 + 1, 1 / 3, $printed, *STDOUT, qr/ab+c/i, v1.2.3);
	my @rows = map { { variable => $keys[$_], value => $_ } } 0 .. $#keys;
	my %want;
	$want{ "$keys[$_]" } = $_ for 0 .. $#keys;	# perl's own stringification, last one wins
	is_deeply(aoh2h(\@rows, duplicates => 'last'), \%want,
		'every kind of key cell becomes the string perl makes of it');

	my $nan = 9**9**9 / 9**9**9;
	is_deeply([ keys %{ aoh2h([ { variable => $nan, value => 1 } ]) } ], [ "$nan" ], 'a NaN key');

	# "caf\xe9" and its upgraded copy are one string; "caf\xc3\xa9" is another
	like(err { aoh2h([ { variable => "caf\xe9", value => 1 }, { variable => $up, value => 2 } ]) },
		qr/duplicate key/, 'a string and its UTF-8-upgraded copy are one key');
	is(scalar keys %{ aoh2h([ { variable => "caf\xc3\xa9", value => 1 }, { variable => $up, value => 2 } ]) },
		2, 'different strings with the same bytes are two keys');

	my $cols = aoh2h([ { "\x{e9}t\x{e9}" => 'k', "\x{436}" => 'v' } ],
		var_name => "\x{e9}t\x{e9}", value_name => "\x{436}");
	is_deeply($cols, { k => 'v' }, 'column names outside ASCII are found');
}

#----------------------------------------------------------------------------
# The caller's cells are left as they were.
{
	my @rows = map { { variable => $_ * 1, value => $_ * 1.5 } } 1 .. 3;
	my @before = map { B::svref_2object(\$_->{variable})->FLAGS } @rows;
	ok(!grep({ $_ & (B::SVf_POK | B::SVp_POK) } @before), 'precondition: the numeric key cells hold no string');
	aoh2h(\@rows);
	my @after = map { B::svref_2object(\$_->{variable})->FLAGS } @rows;
	ok(!grep({ $_ & (B::SVf_POK | B::SVp_POK) } @after),
		'an integer key cell is not given a cached string');
	my @nv = ({ variable => 0.25, value => 1 });
	aoh2h(\@nv);
	ok(!(B::svref_2object(\$nv[0]{variable})->FLAGS & (B::SVf_POK | B::SVp_POK)),
		'nor is a floating-point one');

	my $src = [ { variable => 'a', value => 1 } ];
	my $h = aoh2h($src);
	$h->{a} = 99;
	is($src->[0]{value}, 1, 'editing the result does not touch the input');

	my $printed = 7; my $s = "$printed";
	my $p = aoh2h([ { variable => 'n', value => $printed } ]);
	ok($p->{n} == 7 && $p->{n} eq '7', 'a printed number comes back as the same number');
}

#----------------------------------------------------------------------------
# Tied rows see the calls 0.3217 made, in its order.
our @LOG;
{	package LogHash;
	require Tie::Hash;
	our @ISA = ('Tie::StdHash');
	sub FETCH  { push @main::LOG, "FETCH($_[0]{__id}:$_[1])";  $_[0]->SUPER::FETCH($_[1]) }
	sub EXISTS { push @main::LOG, "EXISTS($_[0]{__id}:$_[1])"; $_[0]->SUPER::EXISTS($_[1]) }
}
{	package LogArray;
	require Tie::Array;
	our @ISA = ('Tie::StdArray');
	sub FETCH { push @main::LOG, "AFETCH($_[1])"; $_[0]->SUPER::FETCH($_[1]) }
}
{	package CountScalar;
	require Tie::Scalar;
	our @ISA = ('Tie::StdScalar');
	our %N;
	sub FETCH { $N{ Scalar::Util::refaddr($_[0]) }++; ${ $_[0] } }
}
sub logged_row { my ($id, %h) = @_; my %t; tie %t, 'LogHash'; %t = %h; (tied %t)->{__id} = $id; \%t }
{
	my $head = 'EXISTS(0:variable) EXISTS(0:value) FETCH(0:variable) FETCH(0:value) '
	         . 'EXISTS(1:variable) EXISTS(1:value) FETCH(1:variable) FETCH(1:value) '
	         . 'EXISTS(2:variable) EXISTS(2:value) FETCH(2:variable)';
	my %want = (
		die   => [ $head, qr/^df2h: duplicate key 'a'/ ],
		first => [ "$head EXISTS(3:variable) EXISTS(3:value)", qr/^df2h: index 3 has no 'value' column/ ],
		last  => [ "$head FETCH(2:value) EXISTS(3:variable) EXISTS(3:value)", qr/^df2h: index 3 has no 'value' column/ ],
	);
	for my $mode (qw(die first last)) {
		for my $outer (qw(plain tied)) {
			my @rows = (logged_row(0, variable => 'a', value => 1), logged_row(1, variable => 'b', value => 2),
			            logged_row(2, variable => 'a', value => 3), logged_row(3, variable => 'c'));
			my $aoh = \@rows;
			if ($outer eq 'tied') { my @t; tie @t, 'LogArray'; @t = @rows; $aoh = \@t }
			@LOG = ();
			my $e = err { aoh2h($aoh, duplicates => $mode) };
			is(join(' ', grep { !/^AFETCH/ } @LOG), $want{$mode}[0],
				"tied rows, $mode, $outer frame: EXISTS and FETCH as 0.3217 called them");
			like($e, $want{$mode}[1], "tied rows, $mode, $outer frame: the same error");
			if ($outer eq 'tied') {
				my %n; $n{$_}++ for grep { /^AFETCH/ } @LOG;
				ok(!grep({ $_ != 1 } values %n), "tied frame, $mode: each row FETCHed once");
			}
		}
	}

	# a successful fold of tied rows
	my @ok = (logged_row(0, variable => 'a', value => 1), logged_row(1, variable => 'b', value => 2));
	is(kv(aoh2h(\@ok)), 'a=1,b=2', 'tied rows fold');

	# a tied cell in a plain row is FETCHed once, key and value alike
	my %row;
	tie $row{variable}, 'CountScalar', 'k';
	tie $row{value},    'CountScalar', 'v';
	%CountScalar::N = ();
	is(kv(aoh2h([ \%row ])), 'k=v', 'tied cells fold');
	is_deeply([ sort values %CountScalar::N ], [ 1, 1 ], 'each tied cell is FETCHed once');

	# an overloaded key is stringified once, under every mode (0.3217: twice)
	for my $mode (qw(die first last)) {
		$Counted::N = 0;
		aoh2h([ { variable => bless([], 'Counted'), value => 1 } ], duplicates => $mode);
		is($Counted::N, 1, "an overloaded key is stringified once under '$mode'");
	}
}

#----------------------------------------------------------------------------
# Restricted rows, holes, and the sizes at the edges.
{
	my %locked = (variable => 'a', value => 1);
	lock_keys(%locked);
	is(err { aoh2h([ \%locked ], var_name => 'gene') }, "df2h: index 0 has no 'gene' column\n",
		"a restricted row's missing column gets df2h's message, not perl's");
	is(kv(aoh2h([ \%locked ])), 'a=1', 'a restricted row folds');

	my @holes;
	$holes[1] = { variable => 'a', value => 1 };
	is(err { aoh2h(\@holes) }, "df2h: index 0 is not a hashref\n", 'a hole is not a row');

	is_deeply(aoh2h([]), {}, 'no rows');
	is_deeply(aoh2h([ { variable => 'a', value => undef } ]), { a => undef }, 'one row, undef value');

	my $n = 100_000;
	my @big = map { { variable => "k$_", value => $_ } } 1 .. $n;
	my $h = aoh2h(\@big);
	is(scalar keys %$h, $n, "$n distinct keys under 'die'");
	ok(!grep({ $h->{"k$_"} != $_ } 1 .. $n), 'every value is in place');
	my @rep = map { { variable => 'k' . ($_ % 100), value => $_ } } 1 .. $n;
	is(aoh2h(\@rep, duplicates => 'first')->{k7}, 7, "'first' keeps the first of $n rows with 100 keys");
	is(aoh2h(\@rep, duplicates => 'last')->{k7}, $n - 93, "'last' keeps the last");
	my $after = aoh2h(\@big, duplicates => 'last');
	$after->{extra} = 1;
	is($after->{extra}, 1, 'the result takes new keys like any other hash');
	ok(exists $after->{k1} && delete($after->{k1}) == 1 && !exists $after->{k1}, 'and deletes them');
}

#----------------------------------------------------------------------------
# Nothing leaks, on the way out or on a croak.
SKIP: {
	skip 'Test::LeakTrace not installed', 9 unless $HAVE_LEAKTRACE;
	my @rows = map { { variable => "k$_", value => "v$_" } } 1 .. 50;
	my @dups = (@rows, { variable => 'k1', value => 'again' });
	my %t; tie %t, 'Tie::StdHash'; %t = (variable => 'k1', value => 1);
	no_leaks_ok { my $h = aoh2h(\@rows) } "no leak: 'die'";
	no_leaks_ok { my $h = aoh2h(\@dups, duplicates => 'first') } "no leak: 'first'";
	no_leaks_ok { my $h = aoh2h(\@dups, duplicates => 'last') } "no leak: 'last'";
	no_leaks_ok { my $h = aoh2h([ @rows, \%t ], duplicates => 'last') } 'no leak: a tied row';
	no_leaks_ok { eval { aoh2h(\@dups) } } 'no leak: a croak on a repeat, with the hash half built';
	no_leaks_ok { eval { aoh2h([ @rows, { variable => 'x' } ]) } } 'no leak: a croak on a missing column';
	no_leaks_ok { eval { aoh2h([ @rows, { variable => [], value => 1 } ]) } } 'no leak: a croak on a reference key';
	no_leaks_ok { eval { aoh2h([ @rows, { variable => bless([], 'Dies'), value => 1 } ]) } }
		'no leak: a key whose overloading dies';
	no_leaks_ok { eval { aoh2h([ @rows, 'row' ]) } } 'no leak: a croak on a row that is not a hash';
}

done_testing();
