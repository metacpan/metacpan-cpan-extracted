#!/usr/bin/perl
# large-subset-stamp.pl (post-0.13): which stored runs, and which code, made each record of the corpus runs; writes
# doc/large-subset/tools/large-subset-tables-used.tsv (make corpus-stamp), which t/records.t checks in every make test.
# The list of the records, what each is to the runs, and what rewrites it, is %RECORD below: one place.
#
# Usage, from the distribution's directory:
#   perl doc/large-subset/tools/large-subset-stamp.pl -label LABEL -run COMMIT [-tools COMMIT] [-results DIR | -archive SHA256]
#        [-all | RECORD...]
#   -label    the collection the runs are stored in: proc-spawner/LABEL of the repository ilyaz-ai/Proc-Spawner-results
#   -run      the commit of Proc-Spawner the runs were made with
#   -tools    the commit whose tools wrote the records stamped (default: HEAD, which then must have no uncommitted
#             change in lib/, the tools or doc/corpus.mk)
#   -results  a clone of Proc-Spawner-results (default: $PROC_SPAWNER_RESULTS, else ../Proc-Spawner-results or
#             ../proc-spawner-results): the archive's SHA-256 is read from its proc-spawner/LABEL/SHA256SUMS
#   -archive  that SHA-256 given instead
#   RECORD    the records to stamp (paths or file names); default: every record whose content is not its row's, or that
#             has no row; -all: every record.  Rows of records that no longer exist are dropped.
# An empty value counts as not given (make passes them all).
use strict; use warnings; use Digest::SHA qw(sha256_hex); use Getopt::Long; use Cwd qw(abs_path getcwd); use File::Spec;

my $D = 'doc/large-subset'; my $T = "$D/tools"; my $TABLE = "$T/large-subset-tables-used.tsv";
my $RR = 'or make corpus-rereport (the reports again from the stored runs)';
our %RECORD = (   # record => [relation, what rewrites it]
  "$D/large-subset-provenance.tsv"             => [made => "make corpus-provenance corpus-calls, $RR"],
  "$T/large-subset-step3.tsv"                  => [made => "make corpus-provenance, $RR"],
  "$T/large-subset-ai-classes.tsv"             => [read => "kept by hand: after an edit, make corpus-rereport, or make corpus-all if a snippet moves into or out of step 3's classes"],
  "$T/large-subset-match-known.tsv"            => [read => 'kept by hand: after an edit, make corpus-rereport'],
  "$T/large-subset-run-differences.tsv"        => [made => "make corpus-runreport, $RR"],
  "$T/large-subset-builtins-differences.tsv"   => [made => "make corpus-builtins, $RR"],
  "$T/large-subset-threeway-db.jsonl"          => [made => 'make corpus-threeway'],
  "$T/large-subset-threeway-differences.tsv"   => [made => 'make corpus-threeway'],
  "$T/large-subset-env-variants.tsv"           => [made => "make corpus-env-variants, $RR"],
  "$T/large-subset-env-control.tsv"            => [made => "make corpus-step3, $RR"],
  "$T/large-subset-env-control-calls.jsonl"    => [made => 'make corpus-step3'],
  "$T/large-subset-env-affects-shell.tsv"      => [made => "make corpus-step3, $RR"],
  "$T/large-subset-env-affects-shell-calls.jsonl" => [made => 'make corpus-step3'],
  "$T/large-subset-env-races.tsv"              => [made => "make corpus-races, $RR"],
  "$T/large-subset-endmodes.tsv"               => [made => "make corpus-endmodes, $RR"],
  "$T/large-subset-match.tsv"                  => [made => "make corpus-match, $RR"],
  "$T/large-subset-match-calls.jsonl"          => [made => 'make corpus-match'],
  "$T/large-subset-env-setups.tsv"             => [made => "make corpus-match, $RR"],
  "$T/large-subset-rejected.tsv"               => [made => 'make corpus-rejected'],
  "$T/large-subset-rejected-setups.jsonl"      => [read => 'kept by hand (written by reading each snippet): after an edit, make corpus-rejected-envs'],
  "$T/large-subset-rejected-envs.tsv"          => [made => 'make corpus-rejected-envs'],
);
my @COLUMNS = qw(record sha256 relation runs archive run tools redo);
my $HEADER = <<'END';
# large-subset-tables-used.tsv: which stored runs, and which code, made each record of the corpus runs.  Written by
# make corpus-stamp (doc/large-subset/tools/large-subset-stamp.pl); checked by t/records.t in every make test.
# One row per record; columns (tab):
#   record    the file, from the distribution's directory
#   sha256    its content's SHA-256 (line ends as LF) when it was stamped
#   relation  made (written from the runs, by them or by a report on them) or read (a list the runs and reports read)
#   runs      where the runs are stored: proc-spawner/LABEL in the repository github.com/ilyaz-ai/Proc-Spawner-results
#   archive   the SHA-256 of that collection's corpus-work.tar.xz (its SHA256SUMS)
#   run       the commit the runs were made with, in Proc-Spawner's own repository (not public)
#   tools     the commit whose tools wrote the record (for read: whose runs and reports read this content); without
#             that repository, the SHA-256 of each record and of each archive are what can be checked
#   redo      what rewrites the record; afterwards make corpus-stamp.  A step whose runs are done (CORPUS/.../.done)
#             does not run again: make corpus-clean, or remove the .done, first.
END

sub hash_of { my $f = shift; open my $h, '<:raw', $f or return 'missing'; local $/; my $t = <$h> // ''; $t =~ s/\r\n/\n/g; sha256_hex($t) }
sub records_here { my %r = map +($_ => 1), grep -f, "$D/large-subset-provenance.tsv", glob("$T/*.tsv"), glob("$T/*.jsonl"); delete $r{$TABLE}; sort keys %r }
sub read_table {
  my %row; open my $h, '<', $TABLE or return {};
  while (<$h>) { next if /^#/ || !/\S/; chomp; my @f = split /\t/, $_, -1;
    @f == @COLUMNS or die "$TABLE: line $.: not ", scalar @COLUMNS, " columns\n"; my %r; @r{@COLUMNS} = @f; $row{$r{record}} = \%r }
  \%row }
sub git { my $n = File::Spec->devnull; my $o = `git @_ 2>$n`; chomp $o; $? ? undef : $o }

# Where a clone of Proc-Spawner-results is (t/records.t uses this too): (DIR) or (undef, why not and what to do, in
# words naming each place tried).  GIVEN: a directory named on the command line (-results), else PROC_SPAWNER_RESULTS,
# else beside the distribution's directory under either spelling.
our $RESULTS_URL = 'https://github.com/ilyaz-ai/Proc-Spawner-results';
sub find_results {
  my ($given, $how) = @_;
  ($given, $how) = ($ENV{PROC_SPAWNER_RESULTS}, 'PROC_SPAWNER_RESULTS') unless defined $given && length $given;
  if (defined $given && length $given) {
    return (undef, "$how=$given: no such directory") unless -d $given;
    return (undef, "$how=$given: not a clone of $RESULTS_URL (it has no directory proc-spawner/)") unless -d "$given/proc-spawner";
    return ($given) }
  # beside this directory, and beside the git clone of Proc-Spawner around it when that is elsewhere (make disttest
  # runs the tests in a directory inside the clone)
  my $n = File::Spec->devnull; my $top = `git rev-parse --show-toplevel 2>$n`; chomp $top;
  my @up = map { abs_path($_) // $_ } (length $top && -f "$top/Spawner.xs" ? "$top/.." : ()), '..';
  my %seen; @up = grep !$seen{$_}++, @up;
  for my $u (@up) { for my $d ("$u/Proc-Spawner-results", "$u/proc-spawner-results") { return ($d) if -d "$d/proc-spawner" } }
  my @tried = map +("$_/Proc-Spawner-results", "$_/proc-spawner-results"), @up;
  my @near = grep -d, @tried;
  (undef, (@near ? "@near: not a clone of $RESULTS_URL (no directory proc-spawner/)"
                 : "no clone of $RESULTS_URL found (looked for " . join(', ', @tried) . ')') .
    ".  To check them: git clone $RESULTS_URL $up[0]/Proc-Spawner-results (about 30 MB); or, with a clone elsewhere, PROC_SPAWNER_RESULTS=DIR") }

if (!caller) {
  my %o; GetOptions(\%o, 'label=s', 'run=s', 'tools=s', 'results=s', 'archive=s', 'all') or die "usage: see $0\n";
  defined $o{$_} && !length $o{$_} and delete $o{$_} for keys %o;
  my $label = $o{label} // die "$0: -label LABEL: the collection proc-spawner/LABEL of Proc-Spawner-results\n";
  $label =~ s{^proc-spawner/}{}; $label =~ /^\d{4}-\d\d-\d\d-[\w.-]+\z/ or die "$0: -label $label: not DATE-NAME\n";
  my $run = git('rev-parse', '--verify', '--quiet', ($o{run} // die "$0: -run COMMIT: the code the runs were made with\n") . '^{commit}')
    // die "$0: -run $o{run}: no such commit here\n";
  my $tools;
  if (defined $o{tools}) { $tools = git('rev-parse', '--verify', '--quiet', "$o{tools}^{commit}") // die "$0: -tools $o{tools}: no such commit here\n" }
  else {
    my $dirty = git('status', '--porcelain', '--', 'lib', "$T/*.pl", "$T/*.sh", 'doc/corpus.mk') // die "$0: not a git checkout: give -tools\n";
    die "$0: uncommitted changes in the tools, so HEAD did not write the records; commit first, or give -tools:\n$dirty\n" if length $dirty;
    $tools = git('rev-parse', 'HEAD') }
  my $archive = $o{archive};
  if (!defined $archive) {
    my ($dir, $why) = find_results($o{results}, '-results');
    $dir // die "$0: $why (here: -results DIR, or -archive SHA256)\n";
    my $sums = "$dir/proc-spawner/$label/SHA256SUMS"; open my $h, '<', $sums or die "$0: $sums: $!\n";
    while (<$h>) { $archive = $1 if /^([0-9a-f]{64})\s+\*?corpus-work\.tar\.xz$/ }
    $archive // die "$0: $sums names no corpus-work.tar.xz\n" }
  $archive =~ /^[0-9a-f]{64}\z/ or die "$0: -archive $archive: not a SHA-256\n";

  my @here = records_here(); my %known = map +($_ => 1), @here;
  my @unknown = grep !$RECORD{$_}, @here; die "$0: records not in %RECORD (add them there): @unknown\n" if @unknown;
  my $row = read_table(); delete $row->{$_} for grep !$known{$_}, keys %$row;
  my @todo;
  if (@ARGV) { for my $a (@ARGV) { my @m = grep { $_ eq $a || m{/\Q$a\E\z} } @here; @m == 1 or die "$0: $a: not one record\n"; push @todo, @m } }
  elsif ($o{all}) { @todo = @here }
  else { @todo = grep { !$row->{$_} || $row->{$_}{sha256} ne hash_of($_) } @here }
  for my $f (@todo) {
    $row->{$f} = { record => $f, sha256 => hash_of($f), relation => $RECORD{$f}[0], runs => "proc-spawner/$label",
                   archive => $archive, run => $run, tools => $tools, redo => $RECORD{$f}[1] } }
  my @missing = grep !$row->{$_}, @here; die "$0: no row yet for @missing: stamp them too\n" if @missing;
  open my $out, '>', "$TABLE.new" or die "$TABLE.new: $!\n"; print $out $HEADER;
  print $out join("\t", @{$row->{$_}}{@COLUMNS}), "\n" for sort keys %$row;
  close $out or die; rename "$TABLE.new", $TABLE or die "$TABLE: $!\n";
  printf "%s: %d of %d records stamped (runs proc-spawner/%s, run %.7s, tools %.7s)\n", $TABLE, scalar @todo, scalar @here, $label, $run, $tools;
}
1;
