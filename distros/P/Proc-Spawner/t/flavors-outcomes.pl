#!/usr/bin/perl
# flavors-outcomes.pl (post-0.12; the user, 2026-11-18): each test's outcome, for one flavor of the spawn primitive, as a
# record: one line per test, LABEL, FILE, NUMBER, OUTCOME (ok, FAILED, TODO-FAILED, TODO-PASSED, SKIP; FILE-SKIPPED,
# FILE-FAILED for a whole file), DESCRIPTION, the TODO or SKIP reason; tab-separated.  prove's PASS counts a failing
# TODO test, and a test skipped because the flavor cannot do a setting, as passed: this keeps them apart.  The flavor
# is set by the environment, as t/flavors.pl sets it (PROC_SPAWNER_MISSING; Run on PERL5LIB for system1).  Run from the
# distribution's directory, after make (on Windows under Wine through cmd /c, as t/flavors.pl); compare the records
# with t/flavors-compare.pl.  Records of 2026-11-18: doc/test-results/*-flavors-by-test.txt.
# Usage: perl t/flavors-outcomes.pl LABEL OUT.tsv FILE...
use strict; use warnings; use TAP::Parser;
use File::Spec; my @INCD = map File::Spec->rel2abs($_), 'blib/lib', 'blib/arch';   # absolute: the tests change directory
my $SEP = $^O eq 'MSWin32' ? ';' : ':';
$ENV{PERL5LIB} = join $SEP, @INCD, grep length, $ENV{PERL5LIB} // '';   # as prove and make test set it, for child Perls
my ($label, $out, @files) = @ARGV; open my $o, '>', $out or die "$out: $!";
for my $f (@files) {
  my $p = TAP::Parser->new({ exec => [$^X, (map "-I$_", @INCD), $f], merge => 0 });
  my ($n, $plan_skip) = (0, undef);
  while (my $r = $p->next) {
    if ($r->is_plan && $r->directive eq 'SKIP') { $plan_skip = $r->explanation; next }
    next unless $r->is_test; $n++;
    my $st = $r->has_todo ? ($r->is_actual_ok ? 'TODO-PASSED' : 'TODO-FAILED')
           : $r->has_skip ? 'SKIP' : $r->is_ok ? 'ok' : 'FAILED';
    my $why = ($r->has_todo || $r->has_skip) ? $r->explanation : '';
    (my $d = $r->description // '') =~ s/^\s*-\s*//; s/[\t\n]/ /g for $d, $why;
    print $o join("\t", $label, $f, $r->number, $st, $d, $why), "\n" }
  print $o join("\t", $label, $f, 0, 'FILE-SKIPPED', '', $plan_skip // ''), "\n" if defined $plan_skip;
  print $o join("\t", $label, $f, 0, 'FILE-FAILED', 'exit ' . ($p->exit // '?') . ', planned ' . ($p->tests_planned // '?') . ', ran ' . $p->tests_run, ''), "\n"
    if !defined $plan_skip && ($p->exit || ($p->tests_planned // -1) != $p->tests_run) }
