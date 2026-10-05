#!/usr/bin/env perl
#
# Strings that are equal to `eq` must be one key, and strings that are not must
# be two, whatever bytes perl happens to store them in.
#
# Every function below used a string as a hash key, or compared two strings,
# by the bytes SvPV() handed back and nothing else.  Those bytes are the
# string's characters only when its UTF-8 flag is off; when it is on they are
# the characters' UTF-8 encoding, and the flag is the only thing that says
# which.  Dropping it went wrong both ways:
#
#   "caf\xe9" and its utf8::upgrade()d copy are the SAME string (`eq` is true),
#   stored as 63 61 66 e9 and as 63 61 66 c3 a9.  By bytes they were two keys.
#
#   "caf\xc3\xa9" (five characters) and that upgraded "caf\xe9" (four) are
#   DIFFERENT strings with the SAME five bytes.  By bytes they were one key.
#
# and a name outside Latin-1, such as "\x{436}", was looked up by its two bytes
# and found nothing, or came back out as those two bytes.  Up to 0.3212:
#
#  1. csort() reported "column not found" for a non-ASCII column name, in an
#     AoH and in a HoA, and stored a HoH's row-name column under its bytes.
#  2. value_counts() counted nothing for a non-ASCII column name.
#  3. mode() counted the two spellings of one string apart and the two strings
#     with one spelling together.
#  4. merge() would not join the two spellings of one key, and did join two
#     different keys with the same bytes; drop_duplicates() kept the first
#     pair as two rows and dropped one of the second.  group_by()/agg() and
#     uniq() were already right, and now share the code that does it
#     (dd_put_str() in LikeR.xs).
#  5. filter() named every HoA column it built after its name's bytes, and --
#     since the cells were then looked up by those bytes too -- filled the
#     column with undef: AoH -> HoA, HoH -> HoA, HoA -> HoA and HoA -> AoH, for
#     a code block and a col() expression alike.  HoH -> HoH lost the row keys'
#     flag the same way.
#  6. survfit() and logrank_test() split one group label into two by
#     spelling, and returned a label outside Latin-1 -- as a stratum name and
#     in 'groups' -- as its bytes.
#  7. coxph() split one strata => \@labels level into two by spelling.
#  8. csort() rethrew a comparator's die with croak("%s", ...), so a UTF-8
#     message came back as its bytes -- and an exception object as the string
#     "HASH(0x...) at ...", which is not a Unicode matter but the same line.
#  9. col2col() stored a callback's error line as its bytes.
#
# There is no R or SciPy reference for any of this: it is a question about
# Perl string identity, and the specification is what `eq` and a Perl hash do
# with the same values, which every expected value here is.  The strings are
# built from escapes rather than literal characters so that the file needs no
# `use utf8` and means the same in any encoding it is saved in.
# t/value_counts.utf8.t covers value_counts() on the values themselves.

require 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Stats::LikeR;

my $zhe   = "\x{436}"; # a name outside Latin-1
my $bytes = "caf\xe9"; # Latin-1, stored as one byte per char
my $upgr  = "caf\xe9"; utf8::upgrade($upgr);	# the same string, stored as UTF-8
my $five  = "caf\xc3\xa9"; # a different string: upgr's bytes, no flag
my $smile = "\x{263A}";
my $three = "\xe2\x98\xba"; # smile's bytes, as three characters

ok($bytes eq $upgr && $five ne $upgr && $smile ne $three
   && utf8::is_utf8($upgr) && !utf8::is_utf8($bytes),
   'the fixtures are what they say: two spellings of one string, and two strings with one spelling');

#  1. csort 
{
	my $r = csort([{ $zhe => 2 }, { $zhe => 1 }, { $zhe => 3 }], $zhe);
	is_deeply([ map { $_->{$zhe} } @$r ], [1, 2, 3], 'csort: AoH by a column named outside Latin-1');
	$r = csort({ $zhe => [3, 1, 2], b => [6, 4, 5] }, $zhe);
	is_deeply($r, { $zhe => [1, 2, 3], b => [4, 5, 6] }, 'csort: HoA by a column named outside Latin-1');
	$r = csort({ r2 => { x => 2 }, r1 => { x => 1 } }, 'x', 'aoh', $zhe);
	is_deeply([ map { $_->{$zhe} } @$r ], ['r1', 'r2'], 'csort: a HoH row-name column named outside Latin-1');
	$r = csort([{ $bytes => 2 }, { $bytes => 1 }], $upgr);
	is_deeply([ map { $_->{$bytes} } @$r ], [1, 2], 'csort: a column found by the other spelling of its name');
}

#  2. value_counts by column 
{
	is_deeply(value_counts([{ $zhe => 'a' }, { $zhe => 'a' }, { $zhe => 'b' }], $zhe),
	          { a => 2, b => 1 }, 'value_counts: AoH column named outside Latin-1');
	is_deeply(value_counts({ $zhe => ['a', 'a', 'b'] }, $zhe),
	          { a => 2, b => 1 }, 'value_counts: HoA column named outside Latin-1');
	is_deeply(value_counts({ r1 => { $zhe => 'a' }, r2 => { $zhe => 'b' } }, $zhe),
	          { a => 1, b => 1 }, 'value_counts: HoH column named outside Latin-1');
}

#  3. mode 
{
	my @m = mode($bytes, $upgr, 'a');
	is(scalar @m, 1, 'mode: two spellings of one string are one value');
	ok($m[0] eq $bytes, 'mode: ... which is the mode');
	@m = mode($five, $upgr, 'a', 'a');
	is_deeply(\@m, ['a'], 'mode: two strings with one spelling are two values');
	@m = mode($smile, $three, $three);
	is_deeply(\@m, [$three], 'mode: a wide character is not its own bytes');
	@m = mode($zhe, $zhe, 'a');
	ok(@m == 1 && $m[0] eq $zhe, 'mode: a value outside Latin-1 comes back as itself');
}

#  4. merge and drop_duplicates 
{
	my $join = sub {
		my ($l, $r, @on) = @_;
		my $m = merge([ map { { k => $_->[0], j => 1, a => 1 } } [$l] ],
		              [ map { { k => $_->[0], j => 1, b => 2 } } [$r] ],
		              on => @on == 1 ? $on[0] : \@on);
		return scalar @$m;
	};
	for my $on (['k'], ['k', 'j']) {
		my $how = @$on == 1 ? 'one key' : 'two keys';
		is($join->($bytes, $upgr, @$on), 1, "merge ($how): two spellings of one key join");
		is($join->($upgr, $bytes, @$on), 1, "merge ($how): ... from either side");
		is($join->($five, $upgr, @$on),  0, "merge ($how): two keys with one spelling do not");
		is($join->($smile, $three, @$on), 0, "merge ($how): a wide character is not its own bytes");
		is($join->($zhe, $zhe, @$on),    1, "merge ($how): a key outside Latin-1 joins itself");
	}
	is(scalar @{ drop_duplicates([{ k => $bytes }, { k => $upgr }]) }, 1,
	   'drop_duplicates: two spellings of one value are one row');
	is(scalar @{ drop_duplicates([{ k => $five }, { k => $upgr }]) }, 2,
	   'drop_duplicates: two values with one spelling are two rows');
	is(scalar @{ drop_duplicates([[$smile], [$three]]) }, 2,
	   'drop_duplicates: a wide character is not its own bytes (AoA)');
	is(scalar @{ drop_duplicates({ k => [$bytes, $upgr, $five] })->{k} }, 2,
	   'drop_duplicates: HoA, both rules at once');
}

#  5. filter, every shape conversion through a HoA 
{
	my %in = (
		aoh => sub { [{ $zhe => 1, e => 2 }, { $zhe => 3, e => 4 }] },
		hoh => sub { +{ r1 => { $zhe => 1, e => 2 }, r2 => { $zhe => 3, e => 4 } } },
		hoa => sub { +{ $zhe => [1, 3], e => [2, 4] } },
	);
	for my $shape (qw(aoh hoh hoa)) {
		for my $out (qw(aoh hoa)) {
			for my $p ([block => sub { 1 }], [compiled => col($zhe) > 0]) {
				my $r = filter($in{$shape}->(), $p->[1], 'output_type' => $out);
				my $name = "filter: $shape -> $out, $p->[0], a column named outside Latin-1";
				if ($out eq 'hoa') {
					is_deeply({ map { $_ => [ sort @{ $r->{$_} } ] } keys %$r },
					          { $zhe => [1, 3], e => [2, 4] }, $name);
				} else {
					is_deeply([ sort map { $_->{$zhe} } @$r ], [1, 3], $name);
				}
			}
		}
	}
	my $r = filter({ $zhe => { x => 1 }, b => { x => 0 } }, sub { $_[0]{x} });
	is_deeply([ keys %$r ], [$zhe], 'filter: HoH -> HoH keeps a row key outside Latin-1');
}

#  6. survfit and logrank_test group labels 
{
	my @time = (1, 2, 3, 4, 5, 6);
	my @status = (1, 1, 0, 1, 1, 0);
	my $s = survfit(\@time, \@status, group => [($zhe) x 3, ('b') x 3]);
	is_deeply([ sort keys %{ $s->{strata} } ], [ sort ('b', $zhe) ], 'survfit: a stratum named outside Latin-1');
	is_deeply($s->{groups}, [$zhe, 'b'], 'survfit: ... and in groups');
	$s = survfit(\@time, \@status, group => [($bytes) x 3, ($upgr) x 3]);
	is(scalar @{ $s->{groups} }, 1, 'survfit: two spellings of one label are one group');
	$s = survfit(\@time, \@status, group => [($five) x 3, ($upgr) x 3]);
	is(scalar @{ $s->{groups} }, 2, 'survfit: two labels with one spelling are two groups');
	my $lr = logrank_test(\@time, \@status, [($zhe) x 3, ('b') x 3]);
	is_deeply($lr->{groups}, [$zhe, 'b'], 'logrank_test: a group named outside Latin-1');
}

#  7. coxph strata 
{
	my @time   = (5, 8, 3, 9, 12, 4, 7, 10);
	my @status = (1, 1, 0, 1, 1, 1, 0, 1);
	my @x      = (0.5, 1.2, -0.3, 0.8, -1.1, 0.1, 0.9, -0.6);
	my $one = coxph(\@time, \@status, \@x);
	my $mixed = coxph(\@time, \@status, \@x, strata => [ ($bytes, $upgr) x 4 ]);
	# one stratum either way: the same partial likelihood, so the same fit to
	# the last bit, which is why this compares with is() and not a tolerance
	is($mixed->{coef}[0], $one->{coef}[0],
	   'coxph: two spellings of one strata label are one stratum');
}

#  8. csort rethrows the comparator's own $@ 
{
	my @rows = ({ a => 1 }, { a => 2 }, { a => 3 });
	eval { csort(\@rows, sub { die "$zhe bad\n" }) };
	is($@, "$zhe bad\n", 'csort: a comparator\'s UTF-8 die message comes back as itself');
	eval { csort(\@rows, sub { die { code => 7 } }) };
	is_deeply($@, { code => 7 }, 'csort: a comparator\'s exception object comes back as itself');
}

#  9. col2col error cells 
{
	my $r = col2col({ x => [1, 2, 3], y => [2, 3, 4] }, sub { die "$zhe no\nsecond line\n" });
	is($r->{x}{y}, "$zhe no", 'col2col: an error cell keeps a UTF-8 message\'s characters');
}

done_testing();
