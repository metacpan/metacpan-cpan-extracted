use strict;
BEGIN { if ($] < 5.006 && !defined(&warnings::import)) { $INC{'warnings.pm'} = 'stub'; eval 'package warnings; sub import {}' } } use warnings; local $^W=1;

# t/9010-usascii.t - every file listed in MANIFEST that exists on disk must
# be US-ASCII (bytes 0x0A and 0x20-0x7E only).  Files not yet present (the
# pmake-generated Makefile.PL, META.*, LICENSE, ...) are skipped.
#
# This is the distribution's own, stricter form of INA_CPAN_Check check_C,
# so t/9000-ina-cpan-check.t does not call check_C as well.  The TAP
# helpers (ok, plan_tests) come from the shared library: its ok() carries
# an ($;$) prototype, which forces a match argument into scalar context and
# removes a whole class of silently-passing assertions.

use lib 't/lib';
use INA_CPAN_Check;

sub manifest_files {
    local *FH;
    open(FH, "<MANIFEST") or return ();
    my @f;
    while (<FH>) {
        chomp;
        s/\r\z//;         # a MANIFEST written on Windows, read on Unix
        s/\s+#.*$//;      # strip trailing MANIFEST comment
        s/^\s+//; s/\s+$//;
        next if $_ eq '';
        push @f, $_;
    }
    close FH;
    return @f;
}

# .bat files are excluded: a Windows batch polyglot legitimately carries
# CR (0x0D) line endings, so the strict LF-only US-ASCII rule does not apply.
#
# doc/tui_handy_cheatsheet.*.txt and doc/tui_i18n.txt are excluded: these
# are the 21-language cheatsheets (and their generator's source data), and
# most of those languages legitimately carry native-script or accented
# bytes outside 0x20-0x7E.  lib/, Changes, README, MANIFEST, t/*.t and
# t/lib/*.pm stay under the strict rule; see t/9080-cheatsheets.t for the
# per-language encoding check that applies to the doc/ files instead.
my @files = grep {
    -f $_
    && !/\.bat$/i
    && !/^doc\/tui_handy_cheatsheet\.[A-Z]+\.txt$/
    && !/^doc\/tui_i18n\.txt$/
} manifest_files();

my @tests;
for my $file (@files) {
    my $f = $file;
    push @tests, sub {
        local *FH;
        unless (open(FH, "<$f")) {
            ok(0, "$f - cannot open: $!");
            return;
        }
        # binmode matters on Windows: without it the CRLF of a text file is
        # folded to LF on the way in, and a stray CR would never be seen.
        binmode FH;
        my $bad = 0;
        my $no  = 0;
        while (<FH>) {
            $no++;
            if (/[^\x0A\x20-\x7E]/) {
                $bad = $no;
                last;
            }
        }
        close FH;
        if ($bad) {
            ok(0, "$f - non-US-ASCII byte at line $bad");
        }
        else {
            ok(1, "$f is US-ASCII");
        }
    };
}

# Guard against an empty plan if MANIFEST was unreadable.
unless (@tests) {
    push @tests, sub { ok(0, 'MANIFEST is readable and non-empty') };
}

plan_tests(scalar(@tests));
for my $x (@tests) {
    $x->();
}
