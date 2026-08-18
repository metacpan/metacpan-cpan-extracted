#!/usr/bin/perl
#
# build_cheatsheets.pl
#
# Copyright (c) 2026 INABA Hitoshi <ina.cpan@gmail.com> in a CPAN
#
# Generates doc/tui_handy_cheatsheet.<CODE>.txt for all supported
# languages from doc/tui_i18n.txt (tab-separated UTF-8 data).
#
# This tool itself follows the house Perl 5.005_03 compatibility rule:
# 2-argument bareword open() only, 'use vars' instead of 'our', no //
# or say or state, 4-space indent.
#
######################################################################

use strict;
use vars qw($VERSION);

$VERSION = '0.01';

my $DATA_FILE = 'doc/tui_i18n.txt';
my $OUT_DIR   = 'doc';

# ---------------------------------------------------------------------
# Static parts shared by every language: the title (never translated)
# and the ASCII/US-ASCII code samples for each of the eleven sections.
# ---------------------------------------------------------------------

my $TITLE = 'TUI::Handy Cheat Sheet';

my @CODE = (
    # 1. Install / Load
    "  use TUI::Handy;\n" .
    "  # or, as a command:  perl Handy.pm form.txt\n",

    # 2. Create and run
    "  my \$tui  = TUI::Handy->new(dsl => \$text);   # or new(file => \$path)\n" .
    "  my \$form = \$tui->run;\n" .
    "  print \"Company = \$form->{Company}\\n\";\n",

    # 3. Text box markers
    "  Company: [__________]\n" .
    "  Age:     [###]\n" .
    "  Price:   [\$\$\$\$\$\$]\n" .
    "  Date:    [YYYYMMDD]\n",

    # 4. Checkbox and radio button
    "  [X] Agree to terms\n" .
    "  Plan\n" .
    "  (*) Basic\n" .
    "  ( ) Premium\n",

    # 5. Push button
    "  \$tui->set('Register', sub { my \$form = shift; save(\$form); 0 });\n" .
    "  [Register]\n",

    # 6. Keys (no code sample)
    '',

    # 7. Encoding
    "  \$ENV{TUI_HANDY_ENCODING} = 'euc';   # utf8 / sjis / euc\n",

    # 8. Line-mode fallback
    "  \$ENV{TUI_HANDY_MODE} = 'line';      # ansi / line\n",

    # 9. Command line
    "  perl Handy.pm form.txt\n",

    # 10. Full example
    "  Registration\n" .
    "  Company: [__________]\n" .
    "  Age:     [###]\n" .
    "  [X] Agree to terms\n" .
    "  Plan\n" .
    "  (*) Basic\n" .
    "  ( ) Premium\n" .
    "  [Register]\n",

    # 11. Resources (no code sample)
    '',
);

# ---------------------------------------------------------------------
# Read the tab-separated language data.  Each line has 24 fields:
#   code, label, s1..s11 (section headers), d1..d11 (descriptions)
# ---------------------------------------------------------------------

local *DATA;
open(DATA, $DATA_FILE) or die "cannot open $DATA_FILE: $!";
binmode(DATA);

my @rows;
my $line;
while (defined($line = <DATA>)) {
    chomp $line;
    next if $line eq '';
    my @f = split(/\t/, $line, -1);
    if (scalar(@f) != 24) {
        die "malformed row (", scalar(@f), " fields): $f[0]\n";
    }
    push @rows, \@f;
}
close(DATA);

# ---------------------------------------------------------------------
# Generate one file per language.
# ---------------------------------------------------------------------

my $count = 0;
my $row;
foreach $row (@rows) {
    my ($code, $label, @rest) = @$row;
    my @s = @rest[0 .. 10];    # 11 section headers
    my @d = @rest[11 .. 21];   # 11 descriptions

    my $bar   = '=' x 70;
    my $head  = sprintf("%-56s%s", $TITLE, $label);

    my $out = '';
    $out .= "$bar\n";
    $out .= " $head\n";
    $out .= "$bar\n";

    my $i;
    for ($i = 0; $i <= 10; $i++) {
        my $n = $i + 1;
        $out .= "\n[ $n. $s[$i] ]\n\n";
        $out .= "  $d[$i]\n";
        if ($CODE[$i] ne '') {
            $out .= "\n$CODE[$i]";
        }
    }

    my $outfile = "$OUT_DIR/tui_handy_cheatsheet.$code.txt";
    local *OUT;
    open(OUT, ">$outfile") or die "cannot write $outfile: $!";
    binmode(OUT);
    print OUT $out;
    close(OUT);
    $count++;
}

print "Generated $count cheatsheet files in $OUT_DIR/\n";

1;
