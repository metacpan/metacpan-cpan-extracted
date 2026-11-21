#!/usr/bin/env perl

# What other programs read from write_table's output.
#
# A file that write_table() writes and read_table() reads back can still be
# wrong, because the writer and the reader can share a mistake.  Up to 0.3425
# write_table() wrote the string "6.10" as the number cell <v>6.10</v>, which
# read_table() returns as the text "6.10", so a round trip passed; openpyxl
# read 6.1 and LibreOffice showed 6.1.  So every case below is written with
# write_table() and read by programs that share no code with this module, and
# what they read is frozen here.
#
# Provenance of the frozen values: each case of @case was written by this
# module's 0.3426 write_table() as <i>.csv, <i>.tsv and <i>.xlsx, columns v and
# w, one row: the case in v and 'z' in w.  On 2026-11-20 those files were read
# by Python 3.14.2's csv.reader, by pandas 3.0.4's read_csv(dtype=str,
# keep_default_na=False), by R 4.6.2's read.csv and read.delim(colClasses =
# "character", na.strings = character(0), encoding = "UTF-8"), by openpyxl
# 3.1.5's load_workbook() (cell value and data_type) and by LibreOffice
# 24.2.7.2's csv export with every text cell quoted (soffice --headless
# --convert-to 'csv:Text - txt - csv (StarCalc):44,34,76,1,,0,true,false,true'),
# which shows each cell as displayed and tells a text cell from a number cell.
# The generator is t/write_table.oracle.R.python.py, which says how to re-run
# it; this test never calls it, and needs none of those programs.
#
# What is frozen, between BEGIN GENERATED and END GENERATED:
#   %golden  the bytes write_table wrote: each .csv and .tsv whole, and the
#            <c r="A2"> element of the workbook's sheet1.xml (undef when the
#            cell was left out).  What the readers saw holds for these bytes,
#            so the test writes each case again and requires the same bytes,
#            but for the row ends, which are CR LF on Windows (with_row_ends).
#            When an intended change to write_table changes them, re-run the
#            generator, and review what the readers now see.
#   %read    every reading that is not the value written: keyed
#            "<format>/<reader>/<label>", the text the reader returned, or for
#            a workbook [cell type ('s' text, 'n' number), value].  A reader
#            that saw the row's shape broken (not one row, or w not 'z')
#            returned SHAPE: and the rows it saw.  A case with no key here was
#            read back as written by every reader.
#
# Every key of %read must be explained in %why, as one of
#   'todo'        a defect of this module, or a question the maintainer has
#                 not decided; checked as a TODO test, so it is reported until
#                 it is fixed and then shows as unexpectedly passing;
#   'reader'      the reader's own limitation, with what shows it;
#   'documented'  write_table's documented behavior.
# so a new divergence fails this test until someone has looked at it.
#
# Not here: numbers whose text depends on the perl (Inf, NaN, -0.0, and any
# NV whose %g needs more than 15 digits); t/read_write_table.roundtrip.t
# covers those against perl's own string of them.
#
# Run as
#   perl -Iblib/lib -Iblib/arch t/write_table.oracle.R.python.t --write-corpus DIR
# it writes the files and DIR/manifest.tsv for the generator instead of
# testing; prove never passes arguments.

require 5.010;
use strict;
use warnings FATAL => 'all';
use utf8;
use Scalar::Util 'dualvar';
use Stats::LikeR qw(write_table);

# A string the caller has also used as a number: perl adds a numeric value to
# it (NOK/IOK) and keeps the string, which is what write_table must write.
sub used_as_number {
	my ($s) = @_;
	no warnings 'numeric';
	my $n = $s + 0;
	return $s;
}
sub upgraded { my ($s) = @_; utf8::upgrade($s); return $s }
# A code point that is a surrogate or a noncharacter, made without a literal,
# so that no perl warns while compiling it.
sub cp { no warnings; return chr $_[0] }

# [label, 's' (a string) or 'n' (a number), value]
my @case = (
	# strings a reader may take for a number, or for something else
	['leading zeros',            's', '007'],
	['trailing zero',            's', '6.10'],
	['point, no digit after',    's', '1.'],
	['point, no digit before',   's', '.5'],
	['exponent',                 's', '1e5'],
	['minus zero',               's', '-0'],
	['plus sign',                's', '+5'],
	['leading space',            's', ' 5'],
	['trailing space',           's', '5 '],
	['hex',                      's', '0x1A'],
	['underscored digits',       's', '1_000'],
	['Inf as text',              's', 'Inf'],
	['nan as text',              's', 'nan'],
	['NA as text',               's', 'NA'],
	['TRUE as text',             's', 'TRUE'],
	['17 digits',                's', '9007199254740993'],
	['20 digits',                's', '18446744073709551616'],
	['formula text',             's', '=1+1'],
	['at sign',                  's', '@SUM(A1)'],
	# empty and blank
	['empty',                    's', ''],
	['one space',                's', ' '],
	['tab only',                 's', "\t"],
	# separators, quotes, line breaks, comments
	['comma',                    's', 'a,b'],
	['tab inside',               's', "a\tb"],
	['semicolon',                's', 'a;b'],
	['quote inside',             's', 'a"b'],
	['lone quote',               's', '"'],
	['two quotes',               's', '""'],
	['LF inside',                's', "a\nb"],
	['CRLF inside',              's', "a\r\nb"],
	['CR inside',                's', "a\rb"],
	['lone LF',                  's', "\n"],
	['leading hash',             's', '#x'],
	['space, hash',              's', ' #x'],
	# XML
	['XML specials',             's', '<a href="x">&amp;</a>'],
	['escape lookalike',         's', '_x0041_'],
	['escaped underscore',       's', '_x005F_'],
	# non-ASCII
	['Latin-1 as characters',    's', 'café'],
	['Latin-1 as bytes',         's', "caf\xe9"],
	['Greek',                    's', 'αβ'],
	['astral',                   's', "\x{1F600}"],
	['combining mark',           's', "e\x{301}"],
	['BOM at start',             's', "\x{FEFF}a"],
	['line separator',           's', "\x{2028}"],
	['NEL',                      's', upgraded("\x{85}")],
	# characters XML 1.0 cannot hold
	['NUL inside',               's', "a\x00b"],
	['control 0x01',             's', "\x01"],
	['vertical tab',             's', "\x0B"],
	['DEL',                      's', "\x7F"],
	['noncharacter U+FFFE',      's', cp(0xFFFE)],
	['lone surrogate',           's', cp(0xD800)],
	# perl's dual values
	['6.10 used as a number',    's', used_as_number('6.10')],
	['007 used as a number',     's', used_as_number('007')],
	['1e5 used as a number',     's', used_as_number('1e5')],
	['dualvar',                  's', dualvar(5, 'five')],
	# numbers, whose text is the same on every perl
	['number 0',                 'n', 0],
	['number 42',                'n', 42],
	['number -7',                'n', -7],
	['number 0.25',              'n', 0.25],
	['number -0.5',              'n', -0.5],
);

# Write case $i into $dir as <i>.csv, <i>.tsv and <i>.xlsx; returns the
# warnings write_table gave.
sub write_case {
	my ($dir, $i) = @_;
	my @warn;
	local $SIG{__WARN__} = sub { push @warn, $_[0] };
	for my $ext (qw(csv tsv xlsx)) {
		write_table([{ v => $case[$i][2], w => 'z' }], "$dir/$i.$ext",
			col_names => [qw(v w)], row_names => 0, quiet => 1);
	}
	return @warn;
}

if (@ARGV == 2 and $ARGV[0] eq '--write-corpus') {
	my $dir = $ARGV[1];
	open my $m, '>:raw', "$dir/manifest.tsv" or die "cannot write $dir/manifest.tsv: $!";
	for my $i (0 .. $#case) {
		my ($label, $kind, $v) = @{ $case[$i] };
		write_case($dir, $i);
		my $text = "$v";
		{
			no warnings;	# a surrogate warns as it is encoded
			utf8::upgrade($text);
			utf8::encode($text);
		}
		print {$m} join("\t", $i, $label, $kind, unpack('H*', $text)), "\n";
	}
	close $m or die "cannot write $dir/manifest.tsv: $!";
	exit 0;
}

require Test::More;
Test::More->import;
require File::Temp;
my $have_unzip = eval { require IO::Uncompress::Unzip; 1 };
plan(skip_all => 'IO::Uncompress::Unzip (core) is needed') unless $have_unzip;

# BEGIN GENERATED by t/write_table.oracle.R.python.py
my %golden = (
	"leading zeros" => {
		csv => "v,w\x0A007,z\x0A",
		tsv => "v\x09w\x0A007\x09z\x0A",
		xlsx => "<c r=\"A2\" t=\"inlineStr\"><is><t xml:space=\"preserve\">007</t></is></c>",
	},
	"trailing zero" => {
		csv => "v,w\x0A6.10,z\x0A",
		tsv => "v\x09w\x0A6.10\x09z\x0A",
		xlsx => "<c r=\"A2\" t=\"inlineStr\"><is><t xml:space=\"preserve\">6.10</t></is></c>",
	},
	"point, no digit after" => {
		csv => "v,w\x0A1.,z\x0A",
		tsv => "v\x09w\x0A1.\x09z\x0A",
		xlsx => "<c r=\"A2\" t=\"inlineStr\"><is><t xml:space=\"preserve\">1.</t></is></c>",
	},
	"point, no digit before" => {
		csv => "v,w\x0A.5,z\x0A",
		tsv => "v\x09w\x0A.5\x09z\x0A",
		xlsx => "<c r=\"A2\" t=\"inlineStr\"><is><t xml:space=\"preserve\">.5</t></is></c>",
	},
	"exponent" => {
		csv => "v,w\x0A1e5,z\x0A",
		tsv => "v\x09w\x0A1e5\x09z\x0A",
		xlsx => "<c r=\"A2\" t=\"inlineStr\"><is><t xml:space=\"preserve\">1e5</t></is></c>",
	},
	"minus zero" => {
		csv => "v,w\x0A-0,z\x0A",
		tsv => "v\x09w\x0A-0\x09z\x0A",
		xlsx => "<c r=\"A2\" t=\"inlineStr\"><is><t xml:space=\"preserve\">-0</t></is></c>",
	},
	"plus sign" => {
		csv => "v,w\x0A+5,z\x0A",
		tsv => "v\x09w\x0A+5\x09z\x0A",
		xlsx => "<c r=\"A2\" t=\"inlineStr\"><is><t xml:space=\"preserve\">+5</t></is></c>",
	},
	"leading space" => {
		csv => "v,w\x0A 5,z\x0A",
		tsv => "v\x09w\x0A 5\x09z\x0A",
		xlsx => "<c r=\"A2\" t=\"inlineStr\"><is><t xml:space=\"preserve\"> 5</t></is></c>",
	},
	"trailing space" => {
		csv => "v,w\x0A5 ,z\x0A",
		tsv => "v\x09w\x0A5 \x09z\x0A",
		xlsx => "<c r=\"A2\" t=\"inlineStr\"><is><t xml:space=\"preserve\">5 </t></is></c>",
	},
	"hex" => {
		csv => "v,w\x0A0x1A,z\x0A",
		tsv => "v\x09w\x0A0x1A\x09z\x0A",
		xlsx => "<c r=\"A2\" t=\"inlineStr\"><is><t xml:space=\"preserve\">0x1A</t></is></c>",
	},
	"underscored digits" => {
		csv => "v,w\x0A1_000,z\x0A",
		tsv => "v\x09w\x0A1_000\x09z\x0A",
		xlsx => "<c r=\"A2\" t=\"inlineStr\"><is><t xml:space=\"preserve\">1_000</t></is></c>",
	},
	"Inf as text" => {
		csv => "v,w\x0AInf,z\x0A",
		tsv => "v\x09w\x0AInf\x09z\x0A",
		xlsx => "<c r=\"A2\" t=\"inlineStr\"><is><t xml:space=\"preserve\">Inf</t></is></c>",
	},
	"nan as text" => {
		csv => "v,w\x0Anan,z\x0A",
		tsv => "v\x09w\x0Anan\x09z\x0A",
		xlsx => "<c r=\"A2\" t=\"inlineStr\"><is><t xml:space=\"preserve\">nan</t></is></c>",
	},
	"NA as text" => {
		csv => "v,w\x0ANA,z\x0A",
		tsv => "v\x09w\x0ANA\x09z\x0A",
		xlsx => "<c r=\"A2\" t=\"inlineStr\"><is><t xml:space=\"preserve\">NA</t></is></c>",
	},
	"TRUE as text" => {
		csv => "v,w\x0ATRUE,z\x0A",
		tsv => "v\x09w\x0ATRUE\x09z\x0A",
		xlsx => "<c r=\"A2\" t=\"inlineStr\"><is><t xml:space=\"preserve\">TRUE</t></is></c>",
	},
	"17 digits" => {
		csv => "v,w\x0A9007199254740993,z\x0A",
		tsv => "v\x09w\x0A9007199254740993\x09z\x0A",
		xlsx => "<c r=\"A2\" t=\"inlineStr\"><is><t xml:space=\"preserve\">9007199254740993</t></is></c>",
	},
	"20 digits" => {
		csv => "v,w\x0A18446744073709551616,z\x0A",
		tsv => "v\x09w\x0A18446744073709551616\x09z\x0A",
		xlsx => "<c r=\"A2\" t=\"inlineStr\"><is><t xml:space=\"preserve\">18446744073709551616</t></is></c>",
	},
	"formula text" => {
		csv => "v,w\x0A=1+1,z\x0A",
		tsv => "v\x09w\x0A=1+1\x09z\x0A",
		xlsx => "<c r=\"A2\" t=\"inlineStr\"><is><t xml:space=\"preserve\">=1+1</t></is></c>",
	},
	"at sign" => {
		csv => "v,w\x0A\@SUM(A1),z\x0A",
		tsv => "v\x09w\x0A\@SUM(A1)\x09z\x0A",
		xlsx => "<c r=\"A2\" t=\"inlineStr\"><is><t xml:space=\"preserve\">\@SUM(A1)</t></is></c>",
	},
	"empty" => {
		csv => "v,w\x0A,z\x0A",
		tsv => "v\x09w\x0A\x09z\x0A",
		xlsx => undef,
	},
	"one space" => {
		csv => "v,w\x0A ,z\x0A",
		tsv => "v\x09w\x0A \x09z\x0A",
		xlsx => "<c r=\"A2\" t=\"inlineStr\"><is><t xml:space=\"preserve\"> </t></is></c>",
	},
	"tab only" => {
		csv => "v,w\x0A\x09,z\x0A",
		tsv => "v\x09w\x0A\"\x09\"\x09z\x0A",
		xlsx => "<c r=\"A2\" t=\"inlineStr\"><is><t xml:space=\"preserve\">\x09</t></is></c>",
	},
	"comma" => {
		csv => "v,w\x0A\"a,b\",z\x0A",
		tsv => "v\x09w\x0Aa,b\x09z\x0A",
		xlsx => "<c r=\"A2\" t=\"inlineStr\"><is><t xml:space=\"preserve\">a,b</t></is></c>",
	},
	"tab inside" => {
		csv => "v,w\x0Aa\x09b,z\x0A",
		tsv => "v\x09w\x0A\"a\x09b\"\x09z\x0A",
		xlsx => "<c r=\"A2\" t=\"inlineStr\"><is><t xml:space=\"preserve\">a\x09b</t></is></c>",
	},
	"semicolon" => {
		csv => "v,w\x0Aa;b,z\x0A",
		tsv => "v\x09w\x0Aa;b\x09z\x0A",
		xlsx => "<c r=\"A2\" t=\"inlineStr\"><is><t xml:space=\"preserve\">a;b</t></is></c>",
	},
	"quote inside" => {
		csv => "v,w\x0A\"a\"\"b\",z\x0A",
		tsv => "v\x09w\x0A\"a\"\"b\"\x09z\x0A",
		xlsx => "<c r=\"A2\" t=\"inlineStr\"><is><t xml:space=\"preserve\">a&quot;b</t></is></c>",
	},
	"lone quote" => {
		csv => "v,w\x0A\"\"\"\",z\x0A",
		tsv => "v\x09w\x0A\"\"\"\"\x09z\x0A",
		xlsx => "<c r=\"A2\" t=\"inlineStr\"><is><t xml:space=\"preserve\">&quot;</t></is></c>",
	},
	"two quotes" => {
		csv => "v,w\x0A\"\"\"\"\"\",z\x0A",
		tsv => "v\x09w\x0A\"\"\"\"\"\"\x09z\x0A",
		xlsx => "<c r=\"A2\" t=\"inlineStr\"><is><t xml:space=\"preserve\">&quot;&quot;</t></is></c>",
	},
	"LF inside" => {
		csv => "v,w\x0A\"a\x0Ab\",z\x0A",
		tsv => "v\x09w\x0A\"a\x0Ab\"\x09z\x0A",
		xlsx => "<c r=\"A2\" t=\"inlineStr\"><is><t xml:space=\"preserve\">a\x0Ab</t></is></c>",
	},
	"CRLF inside" => {
		csv => "v,w\x0A\"a\x0D\x0Ab\",z\x0A",
		tsv => "v\x09w\x0A\"a\x0D\x0Ab\"\x09z\x0A",
		xlsx => "<c r=\"A2\" t=\"inlineStr\"><is><t xml:space=\"preserve\">a_x000D_\x0Ab</t></is></c>",
	},
	"CR inside" => {
		csv => "v,w\x0A\"a\x0Db\",z\x0A",
		tsv => "v\x09w\x0A\"a\x0Db\"\x09z\x0A",
		xlsx => "<c r=\"A2\" t=\"inlineStr\"><is><t xml:space=\"preserve\">a_x000D_b</t></is></c>",
	},
	"lone LF" => {
		csv => "v,w\x0A\"\x0A\",z\x0A",
		tsv => "v\x09w\x0A\"\x0A\"\x09z\x0A",
		xlsx => "<c r=\"A2\" t=\"inlineStr\"><is><t xml:space=\"preserve\">\x0A</t></is></c>",
	},
	"leading hash" => {
		csv => "v,w\x0A\"#x\",z\x0A",
		tsv => "v\x09w\x0A\"#x\"\x09z\x0A",
		xlsx => "<c r=\"A2\" t=\"inlineStr\"><is><t xml:space=\"preserve\">#x</t></is></c>",
	},
	"space, hash" => {
		csv => "v,w\x0A #x,z\x0A",
		tsv => "v\x09w\x0A #x\x09z\x0A",
		xlsx => "<c r=\"A2\" t=\"inlineStr\"><is><t xml:space=\"preserve\"> #x</t></is></c>",
	},
	"XML specials" => {
		csv => "v,w\x0A\"<a href=\"\"x\"\">&amp;</a>\",z\x0A",
		tsv => "v\x09w\x0A\"<a href=\"\"x\"\">&amp;</a>\"\x09z\x0A",
		xlsx => "<c r=\"A2\" t=\"inlineStr\"><is><t xml:space=\"preserve\">&lt;a href=&quot;x&quot;&gt;&amp;amp;&lt;/a&gt;</t></is></c>",
	},
	"escape lookalike" => {
		csv => "v,w\x0A_x0041_,z\x0A",
		tsv => "v\x09w\x0A_x0041_\x09z\x0A",
		xlsx => "<c r=\"A2\" t=\"inlineStr\"><is><t xml:space=\"preserve\">_x005F_x0041_</t></is></c>",
	},
	"escaped underscore" => {
		csv => "v,w\x0A_x005F_,z\x0A",
		tsv => "v\x09w\x0A_x005F_\x09z\x0A",
		xlsx => "<c r=\"A2\" t=\"inlineStr\"><is><t xml:space=\"preserve\">_x005F_x005F_</t></is></c>",
	},
	"Latin-1 as characters" => {
		csv => "v,w\x0Acaf\xC3\xA9,z\x0A",
		tsv => "v\x09w\x0Acaf\xC3\xA9\x09z\x0A",
		xlsx => "<c r=\"A2\" t=\"inlineStr\"><is><t xml:space=\"preserve\">caf\xC3\xA9</t></is></c>",
	},
	"Latin-1 as bytes" => {
		csv => "v,w\x0Acaf\xC3\xA9,z\x0A",
		tsv => "v\x09w\x0Acaf\xC3\xA9\x09z\x0A",
		xlsx => "<c r=\"A2\" t=\"inlineStr\"><is><t xml:space=\"preserve\">caf\xC3\xA9</t></is></c>",
	},
	"Greek" => {
		csv => "v,w\x0A\xCE\xB1\xCE\xB2,z\x0A",
		tsv => "v\x09w\x0A\xCE\xB1\xCE\xB2\x09z\x0A",
		xlsx => "<c r=\"A2\" t=\"inlineStr\"><is><t xml:space=\"preserve\">\xCE\xB1\xCE\xB2</t></is></c>",
	},
	"astral" => {
		csv => "v,w\x0A\xF0\x9F\x98\x80,z\x0A",
		tsv => "v\x09w\x0A\xF0\x9F\x98\x80\x09z\x0A",
		xlsx => "<c r=\"A2\" t=\"inlineStr\"><is><t xml:space=\"preserve\">\xF0\x9F\x98\x80</t></is></c>",
	},
	"combining mark" => {
		csv => "v,w\x0Ae\xCC\x81,z\x0A",
		tsv => "v\x09w\x0Ae\xCC\x81\x09z\x0A",
		xlsx => "<c r=\"A2\" t=\"inlineStr\"><is><t xml:space=\"preserve\">e\xCC\x81</t></is></c>",
	},
	"BOM at start" => {
		csv => "v,w\x0A\xEF\xBB\xBFa,z\x0A",
		tsv => "v\x09w\x0A\xEF\xBB\xBFa\x09z\x0A",
		xlsx => "<c r=\"A2\" t=\"inlineStr\"><is><t xml:space=\"preserve\">\xEF\xBB\xBFa</t></is></c>",
	},
	"line separator" => {
		csv => "v,w\x0A\xE2\x80\xA8,z\x0A",
		tsv => "v\x09w\x0A\xE2\x80\xA8\x09z\x0A",
		xlsx => "<c r=\"A2\" t=\"inlineStr\"><is><t xml:space=\"preserve\">\xE2\x80\xA8</t></is></c>",
	},
	"NEL" => {
		csv => "v,w\x0A\xC2\x85,z\x0A",
		tsv => "v\x09w\x0A\xC2\x85\x09z\x0A",
		xlsx => "<c r=\"A2\" t=\"inlineStr\"><is><t xml:space=\"preserve\">\xC2\x85</t></is></c>",
	},
	"NUL inside" => {
		csv => "v,w\x0Aa\x00b,z\x0A",
		tsv => "v\x09w\x0Aa\x00b\x09z\x0A",
		xlsx => "<c r=\"A2\" t=\"inlineStr\"><is><t xml:space=\"preserve\">a_x0000_b</t></is></c>",
	},
	"control 0x01" => {
		csv => "v,w\x0A\x01,z\x0A",
		tsv => "v\x09w\x0A\x01\x09z\x0A",
		xlsx => "<c r=\"A2\" t=\"inlineStr\"><is><t xml:space=\"preserve\">_x0001_</t></is></c>",
	},
	"vertical tab" => {
		csv => "v,w\x0A\x0B,z\x0A",
		tsv => "v\x09w\x0A\x0B\x09z\x0A",
		xlsx => "<c r=\"A2\" t=\"inlineStr\"><is><t xml:space=\"preserve\">_x000B_</t></is></c>",
	},
	"DEL" => {
		csv => "v,w\x0A\x7F,z\x0A",
		tsv => "v\x09w\x0A\x7F\x09z\x0A",
		xlsx => "<c r=\"A2\" t=\"inlineStr\"><is><t xml:space=\"preserve\">\x7F</t></is></c>",
	},
	"noncharacter U+FFFE" => {
		csv => "v,w\x0A\xEF\xBF\xBE,z\x0A",
		tsv => "v\x09w\x0A\xEF\xBF\xBE\x09z\x0A",
		xlsx => "<c r=\"A2\" t=\"inlineStr\"><is><t xml:space=\"preserve\">_xFFFE_</t></is></c>",
	},
	"lone surrogate" => {
		csv => "v,w\x0A\xED\xA0\x80,z\x0A",
		tsv => "v\x09w\x0A\xED\xA0\x80\x09z\x0A",
		xlsx => "<c r=\"A2\" t=\"inlineStr\"><is><t xml:space=\"preserve\">_xD800_</t></is></c>",
	},
	"6.10 used as a number" => {
		csv => "v,w\x0A6.10,z\x0A",
		tsv => "v\x09w\x0A6.10\x09z\x0A",
		xlsx => "<c r=\"A2\" t=\"inlineStr\"><is><t xml:space=\"preserve\">6.10</t></is></c>",
	},
	"007 used as a number" => {
		csv => "v,w\x0A007,z\x0A",
		tsv => "v\x09w\x0A007\x09z\x0A",
		xlsx => "<c r=\"A2\" t=\"inlineStr\"><is><t xml:space=\"preserve\">007</t></is></c>",
	},
	"1e5 used as a number" => {
		csv => "v,w\x0A1e5,z\x0A",
		tsv => "v\x09w\x0A1e5\x09z\x0A",
		xlsx => "<c r=\"A2\" t=\"inlineStr\"><is><t xml:space=\"preserve\">1e5</t></is></c>",
	},
	"dualvar" => {
		csv => "v,w\x0Afive,z\x0A",
		tsv => "v\x09w\x0Afive\x09z\x0A",
		xlsx => "<c r=\"A2\" t=\"inlineStr\"><is><t xml:space=\"preserve\">five</t></is></c>",
	},
	"number 0" => {
		csv => "v,w\x0A0,z\x0A",
		tsv => "v\x09w\x0A0\x09z\x0A",
		xlsx => "<c r=\"A2\"><v>0</v></c>",
	},
	"number 42" => {
		csv => "v,w\x0A42,z\x0A",
		tsv => "v\x09w\x0A42\x09z\x0A",
		xlsx => "<c r=\"A2\"><v>42</v></c>",
	},
	"number -7" => {
		csv => "v,w\x0A-7,z\x0A",
		tsv => "v\x09w\x0A-7\x09z\x0A",
		xlsx => "<c r=\"A2\"><v>-7</v></c>",
	},
	"number 0.25" => {
		csv => "v,w\x0A0.25,z\x0A",
		tsv => "v\x09w\x0A0.25\x09z\x0A",
		xlsx => "<c r=\"A2\"><v>0.25</v></c>",
	},
	"number -0.5" => {
		csv => "v,w\x0A-0.5,z\x0A",
		tsv => "v\x09w\x0A-0.5\x09z\x0A",
		xlsx => "<c r=\"A2\"><v>-0.5</v></c>",
	},
);
my %read = (
	"csv/R/BOM at start" => "a",
	"csv/R/CR inside" => "a\x{A}b",
	"csv/R/CRLF inside" => "a\x{A}b",
	"csv/R/NUL inside" => "SHAPE:[['a', '']]",
	"csv/R/lone surrogate" => "\x{FFFD}\x{FFFD}\x{FFFD}",
	"csv/csv/lone surrogate" => "\x{FFFD}\x{FFFD}\x{FFFD}",
	"csv/pandas/NUL inside" => "a",
	"csv/pandas/lone surrogate" => "\x{FFFD}\x{FFFD}\x{FFFD}",
	"tsv/R/BOM at start" => "a",
	"tsv/R/CR inside" => "a\x{A}b",
	"tsv/R/CRLF inside" => "a\x{A}b",
	"tsv/R/NUL inside" => "SHAPE:[['a', '']]",
	"tsv/R/lone surrogate" => "\x{FFFD}\x{FFFD}\x{FFFD}",
	"tsv/csv/lone surrogate" => "\x{FFFD}\x{FFFD}\x{FFFD}",
	"tsv/pandas/NUL inside" => "a",
	"tsv/pandas/lone surrogate" => "\x{FFFD}\x{FFFD}\x{FFFD}",
	"xlsx/LibreOffice/CRLF inside" => ['s', "a\x{A}b"],
	"xlsx/LibreOffice/lone surrogate" => ['s', undef],
	"xlsx/openpyxl/CR inside" => ['s', "a_x000D_b"],
	"xlsx/openpyxl/CRLF inside" => ['s', "a_x000D_\x{A}b"],
	"xlsx/openpyxl/NUL inside" => ['s', "a_x0000_b"],
	"xlsx/openpyxl/control 0x01" => ['s', "_x0001_"],
	"xlsx/openpyxl/escape lookalike" => ['s', "_x005F_x0041_"],
	"xlsx/openpyxl/escaped underscore" => ['s', "_x005F_x005F_"],
	"xlsx/openpyxl/lone surrogate" => ['s', "_xD800_"],
	"xlsx/openpyxl/noncharacter U+FFFE" => ['s', "_xFFFE_"],
	"xlsx/openpyxl/vertical tab" => ['s', "_x000B_"],
);
# END GENERATED



my %why;
# A lone surrogate is not a character any Unicode encoding has: only broken
# data (a UTF-16 pair cut in half) holds one.  The maintainer decided on
# 2026-11-20 that write_table() writes it rather than refusing the table, so
# it goes out as perl's own UTF-8 for it, and as _xD800_ in an .xlsx.
my $surrogate = 'a lone surrogate has no UTF-8; it is written as perl\'s bytes for it, '
	. 'ED A0 80, which a UTF-8 reader replaces, rather than refused (the maintainer\'s '
	. 'decision of 2026-11-20); read_table() reads it back as written';
for my $fmt (qw(csv tsv)) {
	$why{"$fmt/$_/lone surrogate"} = [documented => $surrogate] for qw(csv pandas R);
	$why{"$fmt/R/BOM at start"} = [reader => 'R drops U+FEFF from a field anywhere in '
		. 'the file, not only at its start; Python\'s csv and pandas return it'];
	$why{"$fmt/R/$_"} = [reader => 'R turns a CR or CR LF inside a quoted field into LF; '
		. 'Python\'s csv and pandas return it as written'] for 'CR inside', 'CRLF inside';
	$why{"$fmt/R/NUL inside"} = [reader => 'an R string cannot hold a NUL: read.csv warns '
		. '"embedded nul(s) found" and loses the rest of the row; Python\'s csv reads it whole'];
	$why{"$fmt/pandas/NUL inside"} = [reader => 'pandas\' C parser ends a field at a NUL; '
		. 'Python\'s csv reads it whole'];
}
$why{'xlsx/LibreOffice/lone surrogate'} = [documented => 'written _xD800_, Excel\'s escape, '
	. 'rather than refused; LibreOffice shows an empty cell, as the POD says, and '
	. 'read_table() reads it back as U+D800'];
$why{'xlsx/LibreOffice/CRLF inside'} = [reader => 'LibreOffice turns a CR LF in a cell '
	. 'into LF; "a\rb" alone comes back whole, so the _x000D_ escape itself is read'];
$why{"xlsx/openpyxl/$_"} = [reader => 'openpyxl returns the _xHHHH_ escape of '
	. "ECMA-376's ST_Xstring as text, where LibreOffice reads the cell as written"]
	for 'CR inside', 'CRLF inside', 'NUL inside', 'control 0x01', 'vertical tab',
		'escape lookalike', 'escaped underscore', 'noncharacter U+FFFE', 'lone surrogate';

# Each character but printable ASCII as \x{HEX}.  By ord and substr, not a
# regex: on perl 5.10.1 and 5.12.5 a match over a lone surrogate dies
# "Malformed UTF-8 character (fatal)" (5.16.3 does not).
sub esc_text {
	my ($t) = @_;
	my $s = '';
	for my $i (0 .. length($t) - 1) {
		my $o = ord substr $t, $i, 1;
		$s .= $o >= 0x20 && $o < 0x7f ? chr $o : sprintf('\\x{%X}', $o);
	}
	return $s;
}
# A reading as ASCII, so that a diagnostic can show any character, a lone
# surrogate included, which no UTF-8 output layer accepts.
sub esc {
	my ($r) = @_;
	return join(':', map { esc($_) } @$r) if ref $r;
	return 'undef' unless defined $r;
	return "'" . esc_text($r) . "'";
}

sub slurp_raw {
	open my $fh, '<:raw', $_[0] or die "cannot read $_[0]: $!";
	local $/;
	my $s = <$fh>;
	return defined $s ? $s : '';
}
sub cell_a2 {
	my $z = IO::Uncompress::Unzip->new($_[0], Name => 'xl/worksheets/sheet1.xml')
		or die "no sheet1.xml in $_[0]";
	my ($xml, $buf) = ('', '');
	$xml .= $buf while $z->read($buf) > 0;
	$z->close;
	return $xml =~ m{(<c r="A2"[^>]*>.*?</c>)}s ? $1 : undef;
}

my $dir = File::Temp->newdir;

# The row end write_table writes: "\r\n" where perl is a CRLF shop (Windows),
# which is where a '>' open gets :crlf, and "\n" elsewhere (WT_EOL in
# LikeR.xs). The probe is the one t/write_table.quoting.t uses.
my $NL = do {
	open my $fh, '>', "$dir/nl.probe" or die "cannot write a probe: $!";
	my $crlf = grep { $_ eq 'crlf' } PerlIO::get_layers($fh);
	close $fh;
	$crlf ? "\x0D\x0A" : "\x0A";
};
# The bytes of a frozen .csv or .tsv as write_table writes them here. %golden
# was written on Linux, so its two rows end in LF; only those two row ends
# change, since an LF inside a quoted field ('LF inside', 'CRLF inside') is
# written as it is (the handle is binary). 0.3426 compared the LF bytes on
# MSWin32 too and failed the 120 .csv and .tsv subtests on both of its Windows
# reports. The header "v<sep>w" holds no LF, so its row end is the first LF and
# the data row's is the last byte. By index and substr, not a regex, for the
# lone surrogate (see esc_text).
sub with_row_ends {
	my ($g) = @_;
	return $g if $NL eq "\x0A";
	my $h = index $g, "\x0A";
	die "a frozen file is not two LF-terminated rows" unless $h > 0 && substr($g, -1) eq "\x0A";
	substr($g, -1, 1, $NL);	# the last first, so that $h still points at the first
	substr($g, $h, 1, $NL);
	return $g;
}

my %label_of;
for my $i (0 .. $#case) {
	my $label = $case[$i][0];
	die "label '$label' is used twice" if $label_of{$label}++;
	my $g = $golden{$label};
	unless ($g) {
		fail("'$label' has frozen output; run t/write_table.oracle.R.python.py");
		next;
	}
	my @warn = write_case($dir, $i);
	is(scalar @warn, 0, "'$label': written without a warning") or diag(@warn);
	is(slurp_raw("$dir/$i.csv"), with_row_ends($g->{csv}), "'$label': the .csv is the file the readers read");
	is(slurp_raw("$dir/$i.tsv"), with_row_ends($g->{tsv}), "'$label': the .tsv is the file the readers read");
	is(cell_a2("$dir/$i.xlsx"), $g->{xlsx}, "'$label': the .xlsx cell is the one the readers read");
}
is(scalar(grep { !$label_of{$_} } keys %golden), 0, 'every frozen output is a case of @case');

# Each divergence a reader showed, against what was written.
my %value_of = map { $_->[0] => $_ } @case;
for my $key (sort keys %read) {
	my ($fmt, $reader, $label) = split m{/}, $key, 3;
	my $c = $value_of{$label};
	ok($c, "$key names a case") or next;
	my $want;
	if ($fmt eq 'xlsx') {
		$want = $c->[1] eq 'n' ? ['n', $c->[2] + 0] : ['s', length $c->[2] ? "$c->[2]" : undef];
	} else {
		$want = "$c->[2]";
	}
	my $w = $why{$key};
	ok($w, "$key: why the reader differs is recorded in %why") or next;
	if ($w->[0] eq 'todo') {
		TODO: {
			local our $TODO = $w->[1];
			is(esc($read{$key}), esc($want), "$key reads back as written");
		}
	} else {
		ok($w->[0] eq 'reader' || $w->[0] eq 'documented', "$key: $w->[0]: $w->[1]");
	}
}
is(join(', ', grep { !exists $read{$_} } sort keys %why), '', 'every entry of %why is a frozen divergence');

done_testing();
