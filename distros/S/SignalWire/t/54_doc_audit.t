#!/usr/bin/env perl
# t/54_doc_audit.t -- Layer C doc/example alignment smoke tests.
#
# Confirms that (a) every bundled Perl example parses with `perl -c`, so a
# syntax break never slips into a release, and (b) the DOC_AUDIT_IGNORE.md
# file exists and is well-formed (no empty lines, every entry carries a
# rationale). The full content audit against porting-sdk/scripts/audit_docs.py
# runs in the doc-audit GitHub workflow; this test keeps the scaffold
# honest at `prove` time.

use strict;
use warnings;
use Test::More;
use FindBin ();
use File::Spec ();

my $REPO = File::Spec->rel2abs(File::Spec->catdir($FindBin::Bin, '..'));
my $IGNORE = File::Spec->catfile($REPO, 'DOC_AUDIT_IGNORE.md');

ok(-f $IGNORE, 'DOC_AUDIT_IGNORE.md present at repo root');

# Every identifier entry in DOC_AUDIT_IGNORE.md must carry a rationale
# ('name: rationale'). A bare identifier with no explanation is a policy
# violation. Free-form prose paragraphs and '#'-comments are allowed.
#
# We recognise a potential entry as any unindented line that starts with
# a legal identifier followed by ':' (the same heuristic audit_docs.py
# uses to harvest names -- it does `split(":", 1)[0].strip()` and treats
# the result as an identifier). Prose text is not unindented+name+colon
# and so is skipped by both this test and audit_docs.py.
open my $fh, '<', $IGNORE or BAIL_OUT("cannot open $IGNORE: $!");
my $entries = 0;
my $violations = 0;
while (my $raw = <$fh>) {
    chomp $raw;
    # Skip blank lines and comments (trim-left before detection so indented
    # '#' comments still register).
    my $stripped = $raw; $stripped =~ s/^\s+//;
    next if $stripped eq '' || $stripped =~ /^#/;
    # Only unindented lines beginning with an identifier are candidates.
    # Prose continuations are indented; section headers are Markdown ('##').
    next unless $raw =~ /^([A-Za-z_][A-Za-z0-9_]*)\b/;
    # Bare identifier (no colon, no rationale) or empty rationale fail.
    $entries++;
    if ($raw !~ /^[A-Za-z_][A-Za-z0-9_]*\s*:\s*\S/) {
        $violations++;
        diag("IGNORE entry missing rationale: $raw");
    }
}
close $fh;

ok($entries > 0, "DOC_AUDIT_IGNORE.md has $entries entries");
is($violations, 0, 'every IGNORE entry carries a rationale');

# Every bundled Perl example must parse with `perl -c` so the CI cannot
# ship a broken snippet. The set matches the doc-audit workflow so local
# regressions surface immediately.
my @example_dirs = (
    File::Spec->catdir($REPO, 'examples'),
    File::Spec->catdir($REPO, 'rest', 'examples'),
    File::Spec->catdir($REPO, 'relay', 'examples'),
);

my $checked = 0;
for my $dir (@example_dirs) {
    opendir(my $dh, $dir) or next;
    my @pls = sort grep { /\.pl$/ && -f File::Spec->catfile($dir, $_) } readdir $dh;
    closedir $dh;
    for my $name (@pls) {
        my $path = File::Spec->catfile($dir, $name);
        my $rel = File::Spec->abs2rel($path, $REPO);
        my $out = `perl -I$REPO/lib -c "$path" 2>&1`;
        like($out, qr/syntax OK/, "example parses: $rel");
        $checked++;
    }
}
ok($checked > 0, "doc audit checked $checked example file(s)");

# If porting-sdk is available alongside, run the full audit as an extra
# assertion so a DOC_AUDIT_IGNORE.md regression fails at `prove` time too.
# Absent porting-sdk (common in release tarballs), skip gracefully.
SKIP: {
    my $porting_sdk = File::Spec->catdir($REPO, '..', 'porting-sdk');
    my $audit = File::Spec->catfile($porting_sdk, 'scripts', 'audit_docs.py');
    skip "porting-sdk audit_docs.py not available at $audit", 1 unless -f $audit;

    my $have_py = `python3 --version 2>&1`;
    skip "python3 not on PATH", 1 unless $have_py =~ /Python/;

    my $cmd = qq{python3 "$audit" --root "$REPO"}
            . qq{ --surface "$REPO/port_surface.json"}
            . qq{ --ignore "$IGNORE" 2>&1};
    my $out = `$cmd`;
    my $rc = $?;
    is($rc, 0, 'porting-sdk audit_docs.py exits clean')
        or diag "audit output:\n$out";
}

done_testing();
