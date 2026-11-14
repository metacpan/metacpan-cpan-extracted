#!/usr/bin/env perl
# read_table: a cell whose text is an integer is stored as that integer.
#
# In a column given no class by colClasses, a cell whose text is an integer
# written exactly as perl would print it is stored as an IV rather than as its
# text (S_text_is_iv() in LikeR.xs): 24 bytes where the text took 72. The rule
# is chosen so that the cell reads the same either way -- the IV stringifies
# to the bytes the file held -- so what this file pins is, first, that every
# value still compares equal to the file's text, and then which cells are IVs
# and which are left as text.
#
# Provenance. The rule is this module's own, and deliberately narrower than
# either reference's: R 4.6.1's type.convert() (src/library/utils/R/readtable.R
# calls it on every column) and pandas 3.0.4's read_csv() both convert a whole
# column, and both read "007", "+5" and " 5" as the integers 7, 5 and 5. Here
# those stay text, because an IV would not print back as them. So the expected
# kinds are stated here from the rule, and the expected values are the text
# each file was written from. The integer limits are perl's own for the build:
# $Config{ivsize} decides which of the long numbers below are IVs.
#
# What a cell is is read from its SV's flags with B, as
# t/read_table.colClasses.t does.
require 5.010001;
use strict;
use warnings FATAL => 'all';
use Test::More;
use File::Temp ();
use File::Spec ();
use Config;
use B ();
use Stats::LikeR qw(read_table write_table);

our $HAVE_LEAKTRACE;
BEGIN {
	$HAVE_LEAKTRACE = eval {
		require Test::LeakTrace;
		Test::LeakTrace->import('no_leaks_ok');
		1;
	} ? 1 : 0;
}

my $dir = File::Temp::tempdir(CLEANUP => 1);
my $n_file = 0;
sub fixture {
	my ($text, $suffix) = @_;
	my $path = File::Spec->catfile($dir, 'f' . ++$n_file . ($suffix // '.csv'));
	open my $fh, '>', $path or die "cannot write \"$path\": $!\n";
	binmode $fh;
	print {$fh} $text;
	close $fh or die "cannot close \"$path\": $!\n";
	return $path;
}
sub kind {
	my $f = B::svref_2object(\$_[0])->FLAGS;
	return $f & B::SVf_POK ? 'PV' : $f & B::SVf_NOK ? 'NV' : $f & B::SVf_IOK ? 'IV' : 'undef';
}

# ---- the rule, text by text ------------------------------------------------
# Each text is the only data cell of a column "v", beside a column of text so
# that no line is blank.
my $iv64 = $Config{ivsize} >= 8;
my @case = (
	# text                      IV?   why
	[ '0',                      1, 'zero' ],
	[ '7',                      1, 'one digit' ],
	[ '42',                     1, 'digits' ],
	[ '-7',                     1, 'a minus sign' ],
	[ '2147483647',             1, '2**31 - 1, the 32-bit IV_MAX' ],
	[ '-2147483648',            1, '-2**31, the 32-bit IV_MIN' ],
	[ '2147483648',             $iv64, '2**31: an IV only where one is 64 bits' ],
	[ '-2147483649',            $iv64, '-2**31 - 1: likewise' ],
	[ '999999999',              1, 'nine digits, the most added up unchecked at 32 bits' ],
	[ '1000000000',             1, 'ten digits' ],
	[ '4294967296',             $iv64, '2**32' ],
	[ '999999999999999999',     $iv64, '18 digits, the most added up unchecked at 64 bits' ],
	[ '1000000000000000000',    $iv64, '19 digits' ],
	[ '9223372036854775807',    $iv64, '2**63 - 1, the 64-bit IV_MAX' ],
	[ '-9223372036854775808',   $iv64, '-2**63, the 64-bit IV_MIN' ],
	[ '9223372036854775808',    0, '2**63: past every IV, so text and not an NV' ],
	[ '-9223372036854775809',   0, '-2**63 - 1: likewise' ],
	[ '18446744073709551615',   0, '2**64 - 1: a UV is not taken either' ],
	[ '99999999999999999999',   0, '20 digits' ],
	[ '123456789012345678901',  0, '21 bytes, longer than any IV' ],
	[ '-0',                     0, 'an IV prints 0, not -0' ],
	[ '00',                     0, 'a leading zero' ],
	[ '007',                    0, 'a leading zero' ],
	[ '-07',                    0, 'a leading zero after the sign' ],
	[ '+5',                     0, 'a plus sign' ],
	[ '-',                      0, 'a sign alone' ],
	[ '--5',                    0, 'two signs' ],
	[ '5-',                     0, 'a sign after the digits' ],
	[ ' 5',                     0, 'a leading blank' ],
	[ '5 ',                     0, 'a trailing blank' ],
	[ '5.0',                    0, 'a decimal' ],
	[ '5.',                     0, 'a trailing point' ],
	[ '.5',                     0, 'a leading point' ],
	[ '1e3',                    0, 'an exponent' ],
	[ '0x1A',                   0, 'hexadecimal' ],
	[ '1,000',                  0, 'a thousands separator (quoted in the file)' ],
	[ '1_000',                  0, 'perl\'s own digit separator' ],
	[ '12a',                    0, 'a letter after digits' ],
	[ 'a12',                    0, 'a letter before digits' ],
	[ "1\x{0}2",                0, 'a NUL between digits' ],
	[ "\xD9\xA5",               0, 'a non-ASCII digit, ARABIC-INDIC DIGIT FIVE in UTF-8' ],
	[ 'Inf',                    0, 'Inf' ],
	[ 'NaN',                    0, 'NaN' ],
	[ 'TRUE',                   0, 'text' ],
);
for my $c (@case) {
	my ($text, $is_iv, $why) = @$c;
	(my $show = $text) =~ s/([^\x20-\x7E])/sprintf '\\x%02X', ord $1/ge;
	my $cell = $text =~ /[,"]/ ? '"' . $text . '"' : $text;
	my $f = fixture("k,v\nrow,$cell\n");
	my $got = read_table($f)->[0]{v};
	is($got, $text, "'$show' reads back equal to its text");
	is(kind($got), $is_iv ? 'IV' : 'PV', "'$show' is " . ($is_iv ? 'an IV' : 'text') . ": $why");
	is("$got", $text, "'$show' stringifies to the file's bytes") if $is_iv;
	# and the perl row closure, which stores the rows before the parser's
	# plan is installed and every row under _closure, agrees
	is(kind(read_table($f, _closure => 1)->[0]{v}), $is_iv ? 'IV' : 'PV', "'$show': the perl closure agrees");
}
# a value, not only a kind: the IV is the number
is(read_table(fixture("k,v\nrow,-2147483648\n"))->[0]{v} + 1, -2147483647, 'an IV cell is its number');

# ---- every shape, and what sits beside an integer --------------------------
my $csv = fixture("id,name,n,x\n1,ann,10,1.5\n2,bob,,2\n3,cy,-3,007\n");
my %want = (	# per column: [value, kind] per row
	id   => [ [1, 'IV'], [2, 'IV'], [3, 'IV'] ],
	name => [ ['ann', 'PV'], ['bob', 'PV'], ['cy', 'PV'] ],
	n    => [ [10, 'IV'], [undef, 'undef'], [-3, 'IV'] ],
	x    => [ ['1.5', 'PV'], [2, 'IV'], ['007', 'PV'] ],
);
sub typed { [ map { [ $_, kind($_) ] } @_ ] }
{
	my $aoh = read_table($csv);
	for my $c (sort keys %want) {
		is_deeply(typed(map { $_->{$c} } @$aoh), $want{$c}, "aoh: column $c");
		is_deeply(typed(@{ read_table($csv, output_type => 'hoa')->{$c} }), $want{$c}, "hoa: column $c");
	}
	my $aoa = read_table($csv, output_type => 'aoa');
	is_deeply(typed(@{ $aoa->[0] }), [ map { [ $_, 'PV' ] } qw(id name n x) ], 'aoa: the header row is text');
	is_deeply(typed(map { $_->[0] } @{$aoa}[1 .. 3]), $want{id}, 'aoa: column id');
	is_deeply(typed(map { $_->[3] } @{$aoa}[1 .. 3]), $want{x},  'aoa: column x');
	my $hoh = read_table($csv, output_type => 'hoh');
	is_deeply([ sort keys %$hoh ], [1, 2, 3], 'hoh: integer row names key the rows as their text');
	is_deeply(typed(map { $hoh->{$_}{n} } 1 .. 3), $want{n}, 'hoh: column n');
	# a row name that is not an integer's text keys its row as that text
	my $h2 = read_table(fixture("id,v\n007,1\n8,2\n"), output_type => 'hoh');
	is_deeply([ sort keys %$h2 ], ['007', '8'], 'hoh: "007" stays the row named 007');
}

# ---- colClasses: 'character' keeps text ------------------------------------
{
	my $all = read_table($csv, colClasses => 'character', output_type => 'hoa');
	is_deeply(typed(@{ $all->{id} }), [ ['1', 'PV'], ['2', 'PV'], ['3', 'PV'] ],
		"colClasses => 'character' keeps every column as text");
	is_deeply(typed(@{ $all->{n} }), [ ['10', 'PV'], [undef, 'undef'], ['-3', 'PV'] ], '... an empty cell still undef');
	my $one = read_table($csv, colClasses => { id => 'character' }, output_type => 'hoa');
	is_deeply(typed(@{ $one->{id} }), [ ['1', 'PV'], ['2', 'PV'], ['3', 'PV'] ], 'a hash keeps the column it names as text');
	is_deeply(typed(@{ $one->{n} }), $want{n}, '... and leaves the others to the rule');
	my $lst = read_table($csv, colClasses => [ 'character', undef ], output_type => 'hoa');
	is_deeply(typed(@{ $lst->{id} }), [ ['1', 'PV'], ['2', 'PV'], ['3', 'PV'] ], 'a list: character by position');
	is_deeply(typed(@{ $lst->{name} }), $want{name}, '... undef is no class');
	is_deeply(typed(@{ $lst->{n} }), [ ['10', 'PV'], [undef, 'undef'], ['-3', 'PV'] ], '... recycled: character again');
	is_deeply(typed(@{ $lst->{x} }), $want{x}, '... and no class again');
	my $und = read_table($csv, colClasses => { id => undef }, output_type => 'hoa');
	is_deeply(typed(@{ $und->{id} }), $want{id}, 'a hash naming a column undef gives it no class');
	# a declared class is still what it was
	my $num = read_table($csv, colClasses => { id => 'numeric', x => 'numeric' }, output_type => 'hoa');
	is_deeply(typed(@{ $num->{id} }), [ [1, 'NV'], [2, 'NV'], [3, 'NV'] ], 'numeric is still an NV');
	is_deeply(typed(@{ $num->{x} }), [ [1.5, 'NV'], [2, 'NV'], [7, 'NV'] ], '... and still reads "007" as 7');
	# under _closure too
	is_deeply(typed(map { $_->{id} } @{ read_table($csv, colClasses => 'character', _closure => 1) }),
		[ ['1', 'PV'], ['2', 'PV'], ['3', 'PV'] ], "the perl closure keeps text under 'character'");
}

# ---- na_strings, quoting, header => 0 ---------------------------------------
{
	my $na = read_table(fixture("a,b\n-999,5\n4,NA\n"), na_strings => [ '-999', 'NA' ], output_type => 'hoa');
	is_deeply(typed(@{ $na->{a} }), [ [undef, 'undef'], [4, 'IV'] ], 'an na_strings token that is an integer is undef, not an IV');
	is_deeply(typed(@{ $na->{b} }), [ [5, 'IV'], [undef, 'undef'] ], '... and the integers beside it are IVs');
	# a quoted integer is an integer, as R's and pandas' readers have it
	my $q = read_table(fixture(qq(a,b\n"5",x\n"6""",y\n)), output_type => 'hoa');
	is_deeply(typed(@{ $q->{a} }), [ [5, 'IV'], ['6"', 'PV'] ], 'a quoted integer is an IV; one with a quote in it is text');
	# header => 0: the first line is data and goes through the closure
	my $h0 = read_table(fixture("1,a\n2,b\n"), header => 0, output_type => 'hoa');
	is_deeply(typed(@{ $h0->{V1} }), [ [1, 'IV'], [2, 'IV'] ], 'header => 0: the first row and the rest agree');
	# a header that is all integers stays the names it is
	my $hn = read_table(fixture("2020,2021\n5,6\n"));
	is_deeply($hn, [ { 2020 => 5, 2021 => 6 } ], 'an integer header names its columns');
	# CRLF, and a last line with no line end
	my $crlf = read_table(fixture("a,b\r\n1,2\r\n3,4"), output_type => 'hoa');
	is_deeply(typed(@{ $crlf->{b} }), [ [2, 'IV'], [4, 'IV'] ], 'CRLF line ends and an unterminated last line');
	# a tab-separated and a whitespace-separated read
	is_deeply(typed(@{ read_table(fixture("a\tb\n1\t2\n", '.tsv'), output_type => 'hoa')->{b} }), [ [2, 'IV'] ], 'a .tsv');
	is_deeply(typed(@{ read_table(fixture("a b\n1   22\n", '.txt'), sep => qr/\s+/, output_type => 'hoa')->{b} }),
		[ [22, 'IV'] ], 'a qr/\s+/ separator');
}

# ---- a filter sees the text, and what it keeps is stored by the rule -------
{
	my @seen;
	my $f = fixture("id,v\n1,10\n2,x\n3,30\n");
	my $r = read_table($f, output_type => 'hoa', filter => { v => sub { push @seen, [ $_, kind($_) ]; $_ ne 'x' } });
	is_deeply(\@seen, [ ['10', 'PV'], ['x', 'PV'], ['30', 'PV'] ], 'a filter is handed each field as text');
	is_deeply(typed(@{ $r->{v} }), [ [10, 'IV'], [30, 'IV'] ], 'the rows it keeps are stored by the rule');
	is_deeply(typed(@{ $r->{id} }), [ [1, 'IV'], [3, 'IV'] ], '... in the columns it did not look at too');
	# what a filter writes back: text that is an integer's is stored as one,
	# a number stays the number it is, other text stays text
	my $w = read_table($f, output_type => 'hoa', filter => { v => sub {
		$_ = $_ eq '10' ? '11' : $_ eq 'x' ? 2.5 : 'thirty'; 1 } });
	is_deeply(typed(@{ $w->{v} }[0, 2]), [ [11, 'IV'], ['thirty', 'PV'] ], 'text a filter writes back is stored by the rule');
	# Only that it is still the number: on older perls the filter path's own
	# look at the value leaves a cached string on it, so kind() says 'PV' on
	# perl 5.10.1, 5.12.5, 5.16.3 and 5.18.4, and 'NV' on 5.32.1 and later.
	is($w->{v}[1], 2.5, 'a number a filter writes back stays that number');
	ok(B::svref_2object(\$w->{v}[1])->FLAGS & B::SVf_NOK, '... and is still an NV');
	my $k = read_table($f, colClasses => 'character', output_type => 'hoa', filter => { id => sub { 1 } });
	is_deeply(typed(@{ $k->{v} }), [ ['10', 'PV'], ['x', 'PV'], ['30', 'PV'] ], "a filtered read keeps text under 'character'");
	# the closure is the reference the parser's filter path is held to
	my $c = read_table($f, output_type => 'hoa', _closure => 1, filter => { v => sub { $_ ne 'x' } });
	is_deeply(typed(@{ $c->{v} }), [ [10, 'IV'], [30, 'IV'] ], 'the perl closure stores a filtered read the same way');
}

# ---- an .xlsx ---------------------------------------------------------------
{
	my $x = File::Spec->catfile($dir, 't.xlsx');
	write_table([ { id => 1, name => 'ann', x => '1.5', z => '007' }, { id => -2, name => '12', x => 3, z => 'b' } ],
		$x, quiet => 1, row_names => 0, col_names => [qw(id name x z)]);
	my $r = read_table($x, output_type => 'hoa');
	is_deeply(typed(@{ $r->{id} }),   [ [1, 'IV'], [-2, 'IV'] ],      'xlsx: integer cells are IVs');
	is_deeply(typed(@{ $r->{name} }), [ ['ann', 'PV'], [12, 'IV'] ],   'xlsx: text that is an integer\'s is one too');
	is_deeply(typed(@{ $r->{x} }),    [ ['1.5', 'PV'], [3, 'IV'] ],    'xlsx: a decimal is text');
	is_deeply(typed(@{ $r->{z} }),    [ ['007', 'PV'], ['b', 'PV'] ],  'xlsx: "007" is text');
	my $t = read_table($x, output_type => 'hoa', colClasses => 'character');
	is_deeply(typed(@{ $t->{id} }), [ ['1', 'PV'], ['-2', 'PV'] ], "xlsx: 'character' keeps text");
}

# ---- an exploded VCF ---------------------------------------------------------
{
	my $vcf = fixture(join('', "##fileformat=VCFv4.2\n",
		join("\t", '#CHROM', qw(POS ID REF ALT QUAL FILTER INFO FORMAT S1)), "\n",
		join("\t", qw(1 100 rs1 A G 50 PASS . GT:DP:GQ 0/1:12:99)), "\n",
		join("\t", qw(1 200 . C T . PASS . GT:DP:GQ 1/1:07:.)), "\n"), '.vcf');
	my $r = read_table($vcf, output_type => 'hoa');
	is_deeply(typed(@{ $r->{POS} }),     [ [100, 'IV'], [200, 'IV'] ],  'vcf: POS is an IV');
	is_deeply(typed(@{ $r->{CHROM} }),   [ [1, 'IV'], [1, 'IV'] ],      'vcf: a numeric CHROM is an IV');
	is_deeply(typed(@{ $r->{'S1.DP'} }), [ [12, 'IV'], ['07', 'PV'] ],  'vcf: a sample\'s integer value is an IV, "07" text');
	is_deeply(typed(@{ $r->{'S1.GT'} }), [ ['0/1', 'PV'], ['1/1', 'PV'] ], 'vcf: a genotype is text');
	is_deeply(typed(@{ $r->{'S1.GQ'} }), [ [99, 'IV'], ['.', 'PV'] ],   'vcf: "." is text unless na_strings names it');
	is_deeply([ sort keys %{ read_table($vcf) } ], [ '1:100:A:G', '1:200:C:T' ], 'vcf: the hoh is keyed as it was');
	my $t = read_table($vcf, output_type => 'hoa', colClasses => 'character');
	is_deeply(typed(@{ $t->{POS} }),     [ ['100', 'PV'], ['200', 'PV'] ], "vcf: 'character' keeps the file's columns text");
	is_deeply(typed(@{ $t->{'S1.DP'} }), [ ['12', 'PV'], ['07', 'PV'] ],   "vcf: ... and the samples' values");
	my $p = read_table($vcf, explode => 0);
	is(kind($p->[0]{S1}), 'PV', 'vcf, unexploded: a sample cell is its text');
	is(kind($p->[0]{POS}), 'IV', 'vcf, unexploded: POS is an IV');
}

# ---- a round trip writes the bytes it read ----------------------------------
{
	my $text = "id,n,x\n1,10,1.5\n2,-3,007\n";
	my $out = File::Spec->catfile($dir, 'round.csv');
	write_table(read_table(fixture($text)), $out, quiet => 1, row_names => 0, col_names => [qw(id n x)]);
	open my $fh, '<', $out or die "cannot read \"$out\": $!\n";
	binmode $fh;
	my $got = do { local $/; <$fh> };
	close $fh;
	$got =~ s/\r\n/\n/g;
	is($got, $text, 'write_table of what read_table read is the file');
}

# ---- leaks -------------------------------------------------------------------
SKIP: {
	skip 'Test::LeakTrace not installed', 4 unless $HAVE_LEAKTRACE;
	my $big = fixture("a,b\n" . join('', map { "$_,x$_\n" } 1 .. 400));
	no_leaks_ok { read_table($big) } 'no leaks: aoh';
	no_leaks_ok { read_table($big, output_type => 'hoh') } 'no leaks: hoh with integer row names';
	no_leaks_ok { read_table($big, colClasses => 'character') } "no leaks: 'character'";
	no_leaks_ok { read_table($big, filter => { a => sub { $_ % 2 } }) } 'no leaks: a filtered read';
}

done_testing;
