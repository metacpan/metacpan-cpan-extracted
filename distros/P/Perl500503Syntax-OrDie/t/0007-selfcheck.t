######################################################################
#
# 0007-selfcheck.t - Self-check: run OrDie.pm as a command against
#                    itself and against clean test files
#
# Verifies:
#   SC01: command-line mode: no args prints usage
#   SC02: command-line mode: clean file reports no violations
#   SC03: command-line mode: multiple files, all clean
#   SC04: command-line mode: known-bad file reports violation
#   SC05: self-check: OrDie.pm passed to itself reports known
#         false-positive (qr// patterns visible to scanner) --
#         this is a documented limitation, not a bug
#
######################################################################
use strict;
BEGIN { if ($] < 5.006 && !defined(&warnings::import)) {
        $INC{'warnings.pm'} = 'stub'; eval 'package warnings; sub import {}' } }
use warnings; local $^W = 1;
use File::Spec ();

use lib 'lib', File::Spec->catdir('t', 'lib');
use INA_CPAN_Check qw(ok plan_tests diag);

my $ROOT = do {
    -f File::Spec->catfile('lib', 'Perl500503Syntax', 'OrDie.pm')
        ? File::Spec->curdir()
        : File::Spec->catdir(File::Spec->updir());
};

my $PM   = File::Spec->catfile($ROOT, 'lib', 'Perl500503Syntax', 'OrDie.pm');
my $PERL = $^X;

# Helper: run perl PM [args] and capture stdout+stderr
# Returns output string only; exit-code detection is omitted for portability
# across Unix/Windows/old-Perl where $? encoding differs.
sub run_cmd {
    my @args = @_;
    my $cmd = join(' ', map { "\"$_\"" } ($PERL, $PM, @args));
    my $out = '';
    local *_CMD_FH;
    if (open(_CMD_FH, "$cmd 2>&1 |")) {
        $out = do { local $/; <_CMD_FH> };
        close _CMD_FH;
    }
    return $out;
}

my @tests = ();

# SC01: no args -> prints usage
push @tests, sub {
    my $out = run_cmd();
    ok($out =~ /Usage/i, 'SC01: no-args prints Usage');
};

# SC02: clean file -> no violations
my $clean_file = File::Spec->catfile($ROOT, 't', '9040-style.t');
push @tests, sub {
    my $out = run_cmd($clean_file);
    ok($out =~ /No violations found/, 'SC02: clean file reports no violations');
};

# SC03: multiple clean files -> all passed
my $clean2 = File::Spec->catfile($ROOT, 't', '9001-load.t');
push @tests, sub {
    my $out = run_cmd($clean_file, $clean2);
    ok($out =~ /2\/2 passed/, 'SC03: two clean files both pass');
};

# SC04: file with known violation -> reports VIOLATION
# We create a temp file containing "our $x = 1;"
my $tmp_bad = File::Spec->catfile(File::Spec->tmpdir(), "ordie_test_bad_$$.pl");
{
    local *_TMP_FH;
    if (open(_TMP_FH, ">$tmp_bad")) {
        print _TMP_FH "use strict;\nour \$x = 1;\n";
        close _TMP_FH;
    }
}
push @tests, sub {
    my $out = run_cmd($tmp_bad);
    ok($out =~ /VIOLATION/, 'SC04: bad file reports VIOLATION');
};

# SC04b: bad file -> Results shows failed count
push @tests, sub {
    my $out = run_cmd($tmp_bad);
    ok($out =~ /failed/, 'SC04b: bad file results show failed count');
};

# SC05: self-check -- OrDie.pm passed to itself
# The module contains qr// patterns (regex literals) which are intentionally
# NOT masked by the scanner (so that regex constructs inside qr// are
# detectable).  This means the BLACKLIST entries themselves trigger hits
# when OrDie.pm is scanned as source.  This is a documented limitation.
push @tests, sub {
    my $out = run_cmd($PM);
    ok($out =~ /VIOLATION/, 'SC05: self-check reports expected false-positive from qr// patterns');
};
push @tests, sub {
    my $out = run_cmd($PM);
    ok($out =~ /OrDie\.pm/, 'SC05b: self-check violation references OrDie.pm');
};

# Cleanup temp file
END {
    local *_DEL;
    unlink $tmp_bad if defined $tmp_bad && -f $tmp_bad;
}

print '1..' . scalar(@tests) . "\n";
$_->() for @tests;
