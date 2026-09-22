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
#   SC05: self-check: OrDie.pm passed to itself reports no violation
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

# Helper: run "perl OrDie.pm [args]" and capture its stdout and stderr.
# Returns the output string only; exit-code detection is omitted for
# portability across Unix/Windows/old-Perl where $? encoding differs.
#
# The command is deliberately NOT handed to a shell.  The former spelling
# built a single command line with every word quoted and opened it as a
# pipe.  On Windows such a line reaches cmd.exe, which strips the first and
# the last quote character of the line it is given: a line whose first word
# is quoted -- as the absolute path in $^X must be -- was torn in half, the
# child never ran, and run_cmd returned the empty string for every call.
# Every assertion here then examined an empty string, and the whole file
# passed only because the assertions were being evaluated in list context.
#
# system() with a LIST bypasses the shell on both platforms and quotes each
# argument itself.  The child inherits this process's standard handles, so
# redirecting them to a file first is enough to capture what it prints.
sub run_cmd {
    my @args = @_;
    my $out_file = File::Spec->catfile(File::Spec->tmpdir(),
                                       "ordie_out_$$.txt");
    my $out = '';
    local(*SAVEOUT, *SAVEERR, *_CMD_FH);

    if (open(SAVEOUT, '>&STDOUT') and open(SAVEERR, '>&STDERR')) {
        if (open(STDOUT, "> $out_file")) {
            open(STDERR, '>&STDOUT');
            select((select(STDOUT), $| = 1)[0]);
            system($PERL, $PM, @args);
            close(STDERR);
            close(STDOUT);
        }
        open(STDOUT, '>&SAVEOUT');
        open(STDERR, '>&SAVEERR');
        close(SAVEOUT);
        close(SAVEERR);
    }

    if (open(_CMD_FH, $out_file)) {
        $out = do { local $/; <_CMD_FH> };
        close _CMD_FH;
    }
    unlink $out_file;
    return defined($out) ? $out : '';
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
# The scanner masks the contents of qr// and of the other quote-like
# operators before it looks for a forbidden construct, so the BLACKLIST
# patterns the module carries in its own source are not mistaken for uses
# of what they describe.  The module must therefore come out clean when it
# is scanned against itself, and a violation reported here is a real defect
# in the masking, not the documented limitation it once was.
push @tests, sub {
    my $out = run_cmd($PM);
    ok($out !~ /VIOLATION/, 'SC05: self-check of OrDie.pm reports no violation');
};
push @tests, sub {
    my $out = run_cmd($PM);
    ok($out =~ /OrDie\.pm/, 'SC05b: self-check output names the file it checked');
};
push @tests, sub {
    my $out = run_cmd($PM);
    ok($out =~ m{1/1 passed}, 'SC05c: self-check counts OrDie.pm as passed');
};

# Cleanup temp file
END {
    local *_DEL;
    unlink $tmp_bad if defined $tmp_bad && -f $tmp_bad;
}

print '1..' . scalar(@tests) . "\n";
$_->() for @tests;
