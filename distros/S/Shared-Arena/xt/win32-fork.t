#!/usr/bin/perl
# Every fork in the suite must be skipped where fork is emulated.
#
# Windows has no fork. Perl emulates one with threads, so a "child" is a thread
# in THIS process, and a child that calls exit or POSIX::_exit takes the whole
# test file with it. The damage is quiet: every assertion before the fork has
# already passed and printed, so the harness sees a file that ran, passed
# everything, and never printed a plan. It reports
#
#     All 53 subtests passed
#     Parse errors: No plan found in TAP output
#     Result: FAIL
#
# Shared-Arena 0.01 shipped with three files like that and failed on Strawberry
# 5.42 for all three.
#
# WHY A LINT AND NOT A RUN. The obvious test is to force $^O and check a plan
# comes out, and it proves nothing: on a POSIX box fork still really forks
# whatever $^O says, the child really exits, and the parent prints its plan
# either way. The hazard only exists where the emulation does. So this counts
# guards instead.
#
# Counting is what catches the case that actually shipped: two of those three
# files DID skip on Windows, once, and had a second fork block further down
# that nobody noticed. A file-level "mentions MSWin32 somewhere" check passes
# them both.

use strict;
use warnings;
use Test::More;

my @tests = sort glob('t/*.t');
plan skip_all => 'run from the distribution root' unless @tests;

for my $file (@tests) {
    open my $fh, '<', $file or die "$file: $!";
    my $src = do { local $/; <$fh> };
    close $fh;

    # Call sites, not the word: `$pid = fork` and `fork()`, but not a comment
    # about forking or a string.
    my @forks = $src =~ /^[^#\n]*?(?<![\w:>])fork\s*(?:\(|;|\s*or\b)/gm;
    next unless @forks;

    if ($src =~ /skip_all[^;]*(?:MSWin32|Win32)/) {
        pass("$file skips the whole file on MSWin32");
        next;
    }

    # Any of the spellings that actually mean "not where fork is emulated":
    # the house `$^O eq 'MSWin32'`, a looser Win32 match, or a d_pseudofork
    # probe.
    my @guards = $src =~ /^\s*skip\b[^;]*(?:MSWin32|Win32|d_pseudofork)/gm;

    cmp_ok(scalar @guards, '>=', scalar @forks,
           "$file guards all " . scalar(@forks) . ' fork call site'
           . (@forks == 1 ? '' : 's') . ' on MSWin32 ('
           . scalar(@guards) . ' skip' . (@guards == 1 ? '' : 's') . ')')
        or diag("A fork whose child exits ends the whole file where fork is "
              . "emulated with threads. Wrap the block:\n"
              . "    SKIP: {\n"
              . "        skip 'fork is POSIX-only here', N if \$^O eq 'MSWin32';\n"
              . "        ...\n"
              . "    }");
}

done_testing();
