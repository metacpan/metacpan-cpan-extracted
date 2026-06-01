######################################################################
#
# 9080-cheatsheets.t - Regression tests for doc/ cheatsheet files
#
# Checks that all 21 language cheatsheets exist, are UTF-8, end with
# a newline, contain the required sections, and mention key constructs.
#
######################################################################
use strict;
BEGIN { if ($] < 5.006 && !defined(&warnings::import)) {
        $INC{'warnings.pm'} = 'stub'; eval 'package warnings; sub import {}' } }
use warnings; local $^W = 1;
use File::Spec ();

use lib 'lib', File::Spec->catdir('t', 'lib');
use INA_CPAN_Check qw(ok plan_tests diag _slurp);

my $root = do {
    my @up = (File::Spec->updir());
    -f File::Spec->catfile('lib', 'Perl500503Syntax', 'OrDie.pm')
        ? File::Spec->curdir()
        : File::Spec->catdir(@up);
};

# ------------------------------------------------------------------
# Language list: the standard 21-language cheatsheet set shared across
# this author's CPAN distributions.
# ------------------------------------------------------------------
my @LANGS = qw(
    BM BN EN FR HI ID JA KM KO MN
    MY NE SI TH TL TR TW UR UZ VI
    ZH
);

# Required sections that must appear in every cheatsheet
my @REQUIRED_SECTIONS = (
    'Perl500503Syntax::OrDie',
    'open',
    'our',
    'use vars',
    'ina.cpan@gmail.com',
);

# Key version markers that must appear
my @VERSION_MARKERS = (
    'Perl 5.6',
    'Perl 5.10',
    'Perl 5.38',
);

# ------------------------------------------------------------------
# Count tests
# ------------------------------------------------------------------
# Per language:
#   1. file exists
#   2. non-empty
#   3. ends with newline
#   4. contains module name
#   5. contains ina.cpan@gmail.com
#   6. contains "Perl 5.6"
#   7. contains "Perl 5.10"
#   8. contains "Perl 5.38"
#   9. contains "our"
#  10. contains "use vars"
#  11. raw bytes are free of the UTF-8 double-encoding (mojibake)
#      signature (a regression guard against re-encoded cheatsheets)
my $CHECKS_PER_LANG = 11;

# perldelta_summary.txt checks: 4
my $SUMMARY_CHECKS = 4;

my @tests = ();

# ------------------------------------------------------------------
# Build test closures for cheatsheets
# ------------------------------------------------------------------
for my $lang (@LANGS) {
    my $file = File::Spec->catfile($root, 'doc',
        "Perl500503Syntax-OrDie_cheatsheet.$lang.txt");
    my $l = $lang;  # capture for closure

    push @tests, sub {
        ok(-f $file, "CS01[$l]: cheatsheet file exists: $file");
    };
    push @tests, sub {
        my $content = -f $file ? _slurp($file) : '';
        ok(length($content) > 100, "CS02[$l]: cheatsheet non-empty");
    };
    push @tests, sub {
        my $content = -f $file ? _slurp($file) : '';
        ok(scalar($content =~ /\n$/), "CS03[$l]: cheatsheet ends with newline");
    };
    push @tests, sub {
        my $content = -f $file ? _slurp($file) : '';
        ok(scalar($content =~ /Perl500503Syntax/), "CS04[$l]: contains module name");
    };
    push @tests, sub {
        my $content = -f $file ? _slurp($file) : '';
        ok(scalar($content =~ /ina\.cpan\@gmail\.com/), "CS05[$l]: contains author email");
    };
    push @tests, sub {
        my $content = -f $file ? _slurp($file) : '';
        ok(scalar($content =~ /Perl 5\.6/), "CS06[$l]: mentions Perl 5.6");
    };
    push @tests, sub {
        my $content = -f $file ? _slurp($file) : '';
        ok(scalar($content =~ /Perl 5\.10/), "CS07[$l]: mentions Perl 5.10");
    };
    push @tests, sub {
        my $content = -f $file ? _slurp($file) : '';
        ok(scalar($content =~ /Perl 5\.38/), "CS08[$l]: mentions Perl 5.38");
    };
    push @tests, sub {
        my $content = -f $file ? _slurp($file) : '';
        ok(scalar($content =~ /\bour\b/), "CS09[$l]: mentions 'our'");
    };
    push @tests, sub {
        my $content = -f $file ? _slurp($file) : '';
        ok(scalar($content =~ /use vars/), "CS10[$l]: mentions 'use vars'");
    };
    push @tests, sub {
        # CS11: guard against UTF-8 double-encoding (mojibake).  When clean
        # UTF-8 is mis-decoded as Latin-1 and re-encoded, every non-ASCII
        # byte expands into a C3/C2 digraph; the tell-tale residue is a
        # C2 byte followed by a C1 control (\x80-\x9F), which never occurs
        # in well-formed UTF-8 prose, or the "A-tilde then C2" digraph.
        # The check works on raw bytes and needs no Encode (5.005_03-safe).
        my $bytes = -f $file ? _slurp($file) : '';
        my $bad = ($bytes =~ /\xC2[\x80-\x9F]/) || ($bytes =~ /\xC3\x83\xC2/);
        ok(!$bad, "CS11[$l]: free of UTF-8 double-encoding (mojibake)");
    };
}

# ------------------------------------------------------------------
# Build test closures for perldelta_summary.txt
# ------------------------------------------------------------------
my $summary_file = File::Spec->catfile($root, 'doc', 'perldelta_summary.txt');

push @tests, sub {
    ok(-f $summary_file, 'DS01: perldelta_summary.txt exists');
};
push @tests, sub {
    my $content = -f $summary_file ? _slurp($summary_file) : '';
    ok(scalar($content =~ /perl56delta/), 'DS02: summary mentions perl56delta');
};
push @tests, sub {
    my $content = -f $summary_file ? _slurp($summary_file) : '';
    ok(scalar($content =~ /perl5380delta/), 'DS03: summary mentions perl5380delta');
};
push @tests, sub {
    my $content = -f $summary_file ? _slurp($summary_file) : '';
    ok(scalar($content =~ /perldoc\.perl\.org/), 'DS04: summary has perldoc.perl.org URL');
};

# ------------------------------------------------------------------
# Run
# ------------------------------------------------------------------
plan_tests(scalar(@tests));
$_->() for @tests;
