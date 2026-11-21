#!/usr/bin/env perl

# write_table() then read_table(): what comes back, for every format, frame
# shape and perl representation of a value.
#
# No reference suite can catch a mistake here.  R and pandas test their own
# readers and writers, whose strings are always decoded text and never also
# numbers; a perl scalar can hold bytes or characters, and a string, a number
# or both, and write_table() has to choose what to write for each.  Up to
# 0.3425 read_table() returned the UTF-8 bytes of an .xlsx where it now
# returns characters, so a workbook written from "αβ" did not read back as
# "αβ"; nothing in the suite wrote a non-ASCII workbook and read it again.
#
# This file's expectations are the module's documented behavior, not another
# program's; t/write_table.oracle.R.python.t checks the same files against
# what openpyxl, LibreOffice, Python's csv, pandas and R read from them, which
# is what a round trip cannot see (a writer and a reader can share a mistake).
#
# What comes back, by the POD:
#   - an empty string reads back as undef, in every format: an empty field is
#     missing, and an empty .xlsx cell is not written at all;
#   - every format is written as UTF-8: a string with the UTF-8 flag on as
#     the UTF-8 of its characters, and one without it as it stands when it is
#     valid UTF-8 (as read_table() returns a UTF-8 CSV's fields, which are so
#     written back unchanged) and as Latin-1 when it is not, so "caf\xe9" and
#     "café" are both written C3 A9 (since 0.3426 in a delimited file too;
#     up to 0.3425 that wrote "caf\xe9" as the byte E9);
#   - a delimited file is read as bytes and its fields come back as those
#     UTF-8 bytes, "αβ" as 4 bytes; an .xlsx comes back as characters, so
#     undecoded UTF-8 bytes ("caf\xc3\xa9") come back decoded there;
#   - a row whose cells are all empty or undef comes back as a row of undef
#     (an .xlsx one since 0.3426: up to 0.3425 read_table() dropped it);
#   - a number comes back as perl's own string of it: "$v" (15 significant
#     digits on a double, as R's write.table writes them, more on a long
#     double or __float128 perl, so 0.1 + 0.2 is "0.3" and not exact), Inf
#     and NaN included, whatever spelling this perl and libc give them.
# Anything else that comes back different is a bug.
#
# Each string is written in four representations (as the literal is, with
# the UTF-8 flag forced on, with it forced off where the string allows, and
# after being used as a number, which gives it a numeric value too) in a
# column of its own, between two others and at the end of a row, as a
# delimited file quotes a field by where it is.

require 5.010;
use strict;
use warnings FATAL => 'all';
use utf8;
use Scalar::Util 'dualvar';
use File::Temp 'tempdir';
use Test::More;
use Stats::LikeR qw(read_table write_table);

binmode Test::More->builder->$_, ':encoding(UTF-8)' for qw(output failure_output todo_output);

my $HAVE_LEAKTRACE;
BEGIN {
	$HAVE_LEAKTRACE = eval {
		require Test::LeakTrace;
		Test::LeakTrace->import('no_leaks_ok');
		1;
	} ? 1 : 0;
}

my $dir = tempdir(CLEANUP => 1);
my $seq = 0;

sub cp { no warnings; return chr $_[0] }	# a surrogate or noncharacter, without a literal

# [label, value, 1 when the value is longer than an .xlsx cell holds]
my @string = (
	['leading zeros', '007'], ['trailing zero', '6.10'], ['point, no digit after', '1.'],
	['point, no digit before', '.5'], ['exponent', '1e5'], ['minus zero', '-0'],
	['plus sign', '+5'], ['leading space', ' 5'], ['trailing space', '5 '], ['hex', '0x1A'],
	['Inf as text', 'Inf'], ['nan as text', 'nan'], ['NA as text', 'NA'],
	['17 digits', '9007199254740993'], ['20 digits', '18446744073709551616'],
	['formula text', '=1+1'],
	['empty', ''], ['one space', ' '], ['tab only', "\t"], ['two spaces', '  '],
	['comma', 'a,b'], ['tab inside', "a\tb"], ['semicolon', 'a;b'], ['pipe', 'a|b'],
	['double colon', 'a::b'], ['colon at end', 'a:'], ['colon at start', ':a'],
	['quote inside', 'a"b'], ['lone quote', '"'], ['two quotes', '""'],
	['quoted', '"a"'], ['LF inside', "a\nb"], ['CRLF inside', "a\r\nb"], ['CR inside', "a\rb"],
	['lone LF', "\n"], ['lone CR', "\r"], ['ends in LF', "a\n"],
	['leading hash', '#x'], ['space, hash', ' #x'],
	['XML specials', '<a href="x">&amp;</a>'], ['escape lookalike', '_x0041_'],
	['escaped underscore', '_x005F_'], ['two escape lookalikes', '_x005F_x0041_'],
	['Latin-1', 'café'], ['Latin-1 as bytes', "caf\xe9"], ['UTF-8 bytes undecoded', "caf\xc3\xa9"],
	['Greek', 'αβ'], ['astral', "\x{1F600}"], ['combining mark', "e\x{301}"],
	['BOM at start', "\x{FEFF}a"], ['line separator', "\x{2028}"], ['NEL', "\x{85}"],
	['section sign', 'a§b'],
	['NUL inside', "a\x00b"], ['control 0x01', "\x01"], ['vertical tab', "\x0B"], ['DEL', "\x7F"],
	['noncharacter U+FFFE', cp(0xFFFE)], ['lone surrogate', cp(0xD800)],
	['dualvar', dualvar(5, 'five')],
	['longest .xlsx cell', 'x' x 32767],
	# past the 64 KB the reader takes at a time to look for a CR line end
	['CRLF past 64 KB', ('x' x 70000) . "\r\ny", 1],
);

# Numbers perl holds as numbers.  Their text depends on the perl (-0.0 is
# "-0" on 5.12.5-ld, NaN "nan" or "-nan" on some libcs), so each is expected
# back as "$v" of a copy: interpolating the value itself would, before perl
# 5.36, give it a string that the .xlsx writer then takes for the value.
my @number = (
	['0', 0], ['42', 42], ['-7', -7], ['0.25', 0.25], ['0.1 + 0.2', 0.1 + 0.2],
	['2**53', 2**53], ['1e300', 1e300], ['1e-300', 1e-300], ['Inf', 9**9**9], ['-Inf', -9**9**9],
	['NaN', do { my $i = 9**9**9; $i - $i }], ['-0.0', -0.0],
	['IV_MAX', ~0 >> 1], ['IV_MIN', -(~0 >> 1) - 1], ['UV_MAX', ~0],
);

# [label, value, long] rows: each string in each representation, then the numbers
my @row;
for my $s (@string) {
	my ($label, $v, $long) = @$s;
	push @row, ["$label (as written)", $v, $long];
	my $up = $v;
	utf8::upgrade($up);
	push @row, ["$label (UTF-8 flag on)", $up, $long];
	my $down = $v;
	push @row, ["$label (UTF-8 flag off)", $down, $long] if utf8::downgrade($down, 1);
	my $num = $v;
	{
		no warnings;
		my $n = $num + 0;
	}
	push @row, ["$label (used as a number)", $num, $long];
}
push @row, map { ["number $_->[0]", $_->[1], 0] } @number;

# What read_table() gives back for $v from a delimited file and from an .xlsx.
sub want_delim {
	my ($v) = @_;
	return undef unless defined $v;
	my $s = "$v";	# a copy; see @number
	return undef if $s eq '';
	no warnings;	# a surrogate warns as it is encoded
	if (utf8::is_utf8($s)) {
		utf8::encode($s);
		return $s;
	}
	my $t = $s;
	return $s if utf8::decode($t);	# valid UTF-8, ASCII included: as it is
	utf8::upgrade($s);	# Latin-1
	utf8::encode($s);
	return $s;
}
sub want_xlsx {
	my ($v) = @_;
	return undef unless defined $v;
	my $s = "$v";
	return undef if $s eq '';
	if (!utf8::is_utf8($s) && $s =~ /[\x80-\xff]/) {
		my $t = $s;
		return $t if utf8::decode($t);
	}
	return $s;
}

my $have_bz2 = eval { require IO::Compress::Bzip2; require IO::Uncompress::Bunzip2; 1 };
# [name, file suffix, options for both calls, 1 for an .xlsx]
my @format = (
	['csv', 'csv', {}], ['tsv', 'tsv', {}], ['xlsx', 'xlsx', {}, 1], ['csv.gz', 'csv.gz', {}],
	($have_bz2 ? (['csv.bz2', 'csv.bz2', {}]) : ()),
	['sep ;', 'txt', { sep => ';' }], ['sep |', 'txt', { sep => '|' }],
	['sep ::', 'txt', { sep => '::' }], ['sep §', 'txt', { sep => '§' }],
);

sub same {
	my ($got, $want) = @_;
	return !defined $got && !defined $want
		|| defined $got && defined $want && $got eq $want;
}
# A value as ASCII for a diagnostic, each other character as \x{HEX}.  By ord
# and substr, not a regex: on perl 5.10.1 and 5.12.5 a match over a lone
# surrogate dies "Malformed UTF-8 character (fatal)".
sub show {
	my ($t) = @_;
	return 'undef' unless defined $t;
	my $s = '';
	for my $i (0 .. (length $t > 40 ? 36 : length($t) - 1)) {
		my $o = ord substr $t, $i, 1;
		$s .= $o >= 0x20 && $o < 0x7f ? chr $o : sprintf('\\x{%X}', $o);
	}
	$s .= '...' if length $t > 40;
	return "'$s'";
}
# Writes, reads and returns ($got, @warnings); the warnings of both calls.
sub write_read {
	my ($data, $fmt, $wopt, $ropt) = @_;
	my $file = "$dir/" . ++$seq . ".$fmt->[1]";
	my @warn;
	local $SIG{__WARN__} = sub { push @warn, $_[0] };
	write_table($data, $file, row_names => 0, quiet => 1, %{ $fmt->[2] }, %$wopt);
	my $got = read_table($file, %{ $fmt->[2] }, %$ropt);
	return ($got, @warn);
}

my @col = qw(first mid last);
for my $fmt (@format) {
	my ($name, $xlsx) = ($fmt->[0], $fmt->[3]);
	my @rows = grep { !($xlsx && $_->[2]) } @row;
	my $want = $xlsx ? \&want_xlsx : \&want_delim;
	my %shape = (
		aoh => [ [ map { my $v = $_->[1]; +{ first => $v, mid => $v, last => $v } } @rows ],
			{ col_names => \@col } ],
		hoa => [ { map { my $c = $_; $c => [ map { $_->[1] } @rows ] } @col },
			{ col_names => \@col } ],
		aoa => [ [ \@col, map { [ ($_->[1]) x 3 ] } @rows ], {} ],
		'aoh, one column' => [ [ map { +{ only => $_->[1] } } @rows ], { col_names => ['only'] } ],
	);
	for my $shape (sort keys %shape) {
		my ($data, $wopt) = @{ $shape{$shape} };
		my $type = $shape =~ /^(\w+)/ ? $1 : die;
		my ($got, @warn) = write_read($data, $fmt, $wopt, { output_type => $type });
		is(scalar @warn, 0, "$name, $shape: written and read without a warning") or diag(@warn);
		my @names = $shape =~ /one column/ ? ('only') : @col;
		my @bad;
		for my $i (0 .. $#rows) {
			my $w = $want->($rows[$i][1]);
			for my $j (0 .. $#names) {
				my $c = $type eq 'aoh' ? $got->[$i]{ $names[$j] }
					: $type eq 'hoa' ? $got->{ $names[$j] }[$i]
					: $got->[$i + 1][$j];
				push @bad, "$rows[$i][0], $names[$j]: got " . show($c) . ', want ' . show($w)
					unless same($c, $w);
			}
		}
		my $n = $type eq 'aoh' ? scalar @$got : $type eq 'hoa' ? scalar @{ $got->{first} } : $#$got;
		is($n, scalar @rows, "$name, $shape: every row read back");
		ok(!@bad, "$name, $shape: every cell reads back as written") or diag(join "\n", @bad[0 .. ($#bad < 19 ? $#bad : 19)]);
	}
}

# Column names: each string that a header can hold, as one column's name
# (empty is left out, which write_table warns of; so is the longest cell).
{
	my %seen;
	my @name = grep { length && !$seen{$_}++ } map { "$_->[1]" } grep { !$_->[2] } @string[0 .. $#string - 2];
	for my $fmt (@format) {
		my $want = $fmt->[3] ? \&want_xlsx : \&want_delim;
		my ($got, @warn) = write_read([ \@name, [ 1 .. @name ] ], $fmt, {}, { output_type => 'aoa' });
		is(scalar @warn, 0, "$fmt->[0], column names: no warning") or diag(@warn);
		my @bad = map { "$_: got " . show($got->[0][$_]) . ', want ' . show($want->($name[$_])) }
			grep { !same($got->[0][$_], $want->($name[$_])) } 0 .. $#name;
		ok(!@bad && @{ $got->[0] } == @name, "$fmt->[0]: every column name reads back")
			or diag(join "\n", @bad);
		is_deeply($got->[1], [ 1 .. @name ], "$fmt->[0]: ... over the right data");
	}
}

# Row names: a hash of hashes keyed by the same strings, read back as one.
# A key is whatever keys() returns for it, which may differ from the string
# it was stored under in its UTF-8 flag only.
{
	my %hoh;
	my $i = 0;
	$hoh{ $_->[1] } = { n => ++$i } for grep { length $_->[1] && !$_->[2] } @string[0 .. $#string - 2];
	for my $fmt (@format) {
		my $want = $fmt->[3] ? \&want_xlsx : \&want_delim;
		# Two keys can come back as one: an .xlsx decodes the bytes
		# "caf\xc3\xa9" to the "café" that is also a key.  The first of them
		# in sorted order is written.
		my (%w, %h);
		for my $k (sort keys %hoh) {
			my $wk = $want->($k);
			next if exists $w{$wk};
			$w{$wk} = $hoh{$k};
			$h{$k}  = $hoh{$k};
		}
		my ($got, @warn) = write_read(\%h, $fmt, { row_names => 'id' }, { output_type => 'hoh' });
		is(scalar @warn, 0, "$fmt->[0], row names: no warning") or diag(@warn);
		my @bad = map { 'missing ' . show($_) } grep { !exists $got->{$_} } sort keys %w;
		push @bad, map { 'unexpected ' . show($_) } grep { !exists $w{$_} } sort keys %$got;
		ok(!@bad, "$fmt->[0]: every row name reads back") or diag(join "\n", @bad);
		is_deeply($got, \%w, "$fmt->[0]: ... each with its row");
	}
}

# undef: written as undef_val and read back through na_strings, it is undef
# again, as is the default empty field.  ("NA" as text cannot be told from
# it, which is why undef_val is the caller's choice.)
for my $fmt (@format) {
	my @data = ({ a => 'x', b => undef, c => 'y' }, { a => undef, b => 'z', c => undef });
	for my $na (undef, 'NA', '.') {
		my $o = defined $na ? { undef_val => $na } : {};
		my $r = defined $na ? { na_strings => $na } : {};
		my ($got, @warn) = write_read(\@data, $fmt, { col_names => [qw(a b c)], %$o }, { output_type => 'aoh', %$r });
		is(scalar @warn, 0, "$fmt->[0], undef_val " . show($na) . ': no warning') or diag(@warn);
		is_deeply($got, \@data, "$fmt->[0]: undef written as " . show($na) . ' reads back as undef');
	}
}

# A row whose cells are all empty or undef is kept in every format.  A
# delimited file writes it as a record of empty fields (a lone "" when it has
# one column, since a blank line is skipped).  write_table() writes it to an
# .xlsx as <row r="3"></row>, which openpyxl 3.1.5 and pandas 3.0.4 read as a
# row of None/NaN (pandas: test_one_col_noskip_blank_line, GH 39808, in
# tests/io/excel/test_readers.py), and read_table() too since 0.3426.  A
# trailing one is not kept, by pandas' rule, which a delimited file shares
# only for a blank line.
for my $fmt (@format) {
	for my $empty ('', undef) {
		my @data = ({ a => 1, b => 2 }, { a => $empty, b => $empty }, { a => 3, b => 4 });
		my ($got) = write_read(\@data, $fmt, { col_names => [qw(a b)] }, { output_type => 'aoh' });
		my $want = [ $data[0], { a => undef, b => undef }, $data[2] ];
		my $what = defined $empty ? 'empty strings' : 'undef';
		is_deeply($got, $want, "$fmt->[0]: a row of $what reads back as a row of undef");
	}
}

# A last row of undef is kept by a delimited file and left out of an .xlsx,
# as pandas leaves a sheet's trailing empty rows out (get_sheet_data(), "Trim
# trailing empty rows", GH 39181, test_read_with_empty_trailing_rows in
# tests/io/excel/test_openpyxl.py): it cannot be told from the formatted empty
# rows Excel records below a table.
for my $fmt (@format) {
	my @data = ({ a => 1, b => 2 }, { a => undef, b => undef });
	my ($got) = write_read(\@data, $fmt, { col_names => [qw(a b)] }, { output_type => 'aoh' });
	is_deeply($got, $fmt->[3] ? [ $data[0] ] : \@data,
		"$fmt->[0]: a last row of undef is " . ($fmt->[3] ? 'left out, as pandas leaves it out' : 'kept'));
}

if ($HAVE_LEAKTRACE) {
	for my $fmt (grep { $_->[0] eq 'csv' || $_->[0] eq 'xlsx' } @format) {
		my @data = map { +{ v => $_->[1] } } grep { !$_->[2] } @row[0 .. 40];
		my $file = "$dir/leak.$fmt->[1]";
		my $go = sub {
			write_table(\@data, $file, col_names => ['v'], row_names => 0, quiet => 1);
			read_table($file, output_type => 'aoh');
		};
		$go->() for 1 .. 2;	# warm: the first read loads modules and caches patterns
		SKIP: {
			# as in t/read_table.xlsx.xml.t: IO::Uncompress::Unzip leaks on some
			# perls, and a leak check around read_table would measure it
			if ($fmt->[3]) {
				my $leaks = Test::LeakTrace::leaked_count(
					sub { Stats::LikeR::_unzip_member($file, 'xl/worksheets/sheet1.xml') });
				skip "IO::Uncompress::Unzip leaks $leaks SV(s) per member on this perl", 1 if $leaks;
			}
			no_leaks_ok { $go->() } "$fmt->[0]: a write and read back do not leak";
		}
	}
}

done_testing();
