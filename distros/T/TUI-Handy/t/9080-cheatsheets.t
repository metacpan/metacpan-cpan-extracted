use strict;
BEGIN { if ($] < 5.006 && !defined(&warnings::import)) { $INC{'warnings.pm'} = 'stub'; eval 'package warnings; sub import {}' } } use warnings; local $^W=1;

# t/9080-cheatsheets.t - the 21-language doc/tui_handy_cheatsheet.*.txt
# files stay consistent with each other:
#   S1  file exists and is a sane size (500-8000 bytes)
#   S2  sections are numbered 1..11, consecutively
#   S3  the trailing "[XX] Native Name" label matches the file's code
#   S4  ASCII-only languages stay ASCII; the rest carry native/accented
#       bytes (so a future translation pass is not silently skipped)
#   S5  no CR, file ends with a newline
#
# These are byte-level checks, so the files are read through binmode: on
# Windows a text-mode read would fold CRLF to LF and S5 could never fail.

use lib 't/lib';
use INA_CPAN_Check;

# A local slurp rather than INA_CPAN_Check::_slurp, because these checks
# need the raw bytes.
sub slurp_bytes {
    my $f = shift;
    local *FH;
    open(FH, "<$f") or return undef;
    binmode FH;
    local $/;
    my $s = <FH>;
    close FH;
    return $s;
}

# Languages expected to render in plain US-ASCII (unaccented Latin script
# in their standard orthography).
my @ascii_langs = qw(BM EN ID TL UZ);

# All other supported languages are expected to carry native-script or
# accented bytes outside 0x20-0x7E.
my @native_langs = qw(BN FR HI JA KM KO MN MY NE SI TH TR TW UR VI ZH);

my @codes = sort (@ascii_langs, @native_langs);

my @tests;
my $code;
foreach $code (@codes) {
    my $file = "doc/tui_handy_cheatsheet.$code.txt";

    push @tests, sub {
        my $text = slurp_bytes($file);
        unless (defined $text) {
            ok(0, "$file exists");
            ok(0, "$file size is sane (missing)");
            ok(0, "$file has 11 consecutive sections (missing)");
            ok(0, "$file label starts with [$code] (missing)");
            ok(0, "$file ASCII/native-script expectation matches (missing)");
            ok(0, "$file has no CR bytes (missing)");
            ok(0, "$file ends with a newline (missing)");
            return;
        }
        ok(1, "$file exists");

        my $len = length $text;
        ok(($len >= 500 && $len <= 8000), "$file size is sane ($len bytes)");

        my @nums = $text =~ /^\[ (\d+)\. /mg;
        my $consecutive = 1;
        my $i;
        for ($i = 0; $i <= $#nums; $i++) {
            $consecutive = 0 if $nums[$i] != $i + 1;
        }
        ok((scalar(@nums) == 11 && $consecutive), "$file has 11 consecutive sections");

        ok(($text =~ /\[$code\] \S/) ? 1 : 0, "$file label starts with [$code]");

        my $has_hi_byte = ($text =~ /[^\x00-\x7F]/) ? 1 : 0;
        my $want_hi_byte = grep { $_ eq $code } @native_langs;
        $want_hi_byte = $want_hi_byte ? 1 : 0;
        ok(($has_hi_byte == $want_hi_byte),
            "$file ASCII/native-script expectation matches ($code)");

        ok((index($text, "\r") == -1), "$file has no CR bytes");
        ok(($text =~ /\n\z/) ? 1 : 0, "$file ends with a newline");
    };
}

plan_tests(scalar(@tests) * 7);
foreach my $x (@tests) {
    $x->();
}
