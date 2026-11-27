# t/records.t: the records of the corpus runs (doc/large-subset/...) against large-subset-tables-used.tsv, which says which
# stored runs and which code made each (written by make corpus-stamp: doc/large-subset/tools/large-subset-stamp.pl, whose
# %RECORD lists the records and what rewrites each).  A failure says which make target to run.
#
# Runs in every make test, an installation's too (about 0.15 s).  By hand, from the distribution's directory:
#   prove t/records.t                                (prove -v: also what it could not check, and why)
#   PROC_SPAWNER_RESULTS=DIR prove t/records.t       (a clone of Proc-Spawner-results elsewhere)
# Three levels, each checked where it can be, else skipped with the reason and what to do:
#   the records      always: the table against the records the distribution holds
#   the commits      in a git clone of Proc-Spawner's own repository (not public): the commits the table names are in its history
#   the collections  with a clone of github.com/ilyaz-ai/Proc-Spawner-results (PROC_SPAWNER_RESULTS=DIR, else
#                    ../Proc-Spawner-results or ../proc-spawner-results): each collection and its archive as the table says
# Why a level was skipped is printed where it can be acted on (in a git clone of Proc-Spawner, with RELEASE_TESTING or
# PROC_SPAWNER_RESULTS set); elsewhere, as in an installation, only with prove -v.
use strict; use warnings; use Test::More; use Digest::SHA; use File::Spec;
my $NUL = File::Spec->devnull;
my $TOP = `git rev-parse --show-toplevel 2>$NUL`; chomp $TOP;
my $GIT = length `git --version 2>$NUL`;
my $WORK = $GIT && length $TOP && -f "$TOP/Spawner.xs";   # in a clone of Proc-Spawner: someone working on it
sub why { ($WORK || $ENV{RELEASE_TESTING} || $ENV{PROC_SPAWNER_RESULTS}) ? diag(@_) : note(@_) }
our %RECORD;
require './doc/large-subset/tools/large-subset-stamp.pl';
my $TABLE = 'doc/large-subset/tools/large-subset-tables-used.tsv';

my $row = eval { main::read_table() };
ok($row && %$row, "$TABLE: readable, one row per record") or do { diag $@ || "$TABLE: missing or empty: make corpus-stamp"; done_testing; exit };
sub stamp_cmd { my $r = shift; my ($l) = ($r->{runs} // '') =~ m{^proc-spawner/(.*)}; "make corpus-stamp LABEL=" . ($l // 'LABEL') . ' RUN=' . substr($r->{run} // 'COMMIT', 0, 7) }

# the form of each row
my @bad;
for my $r (values %$row) {
  my $f = $r->{record};
  push @bad, "$f: sha256 $r->{sha256}"   unless $r->{sha256} =~ /^[0-9a-f]{64}\z/;
  push @bad, "$f: relation $r->{relation}" unless $r->{relation} =~ /^(?:made|read)\z/;
  push @bad, "$f: runs $r->{runs}"       unless $r->{runs} =~ m{^proc-spawner/\d{4}-\d\d-\d\d-[\w.-]+\z};
  push @bad, "$f: archive $r->{archive}" unless $r->{archive} =~ /^[0-9a-f]{64}\z/;
  push @bad, "$f: $_ $r->{$_}" for grep $r->{$_} !~ /^[0-9a-f]{7,40}\z/, qw(run tools) }
ok(!@bad, 'every row well formed') or diag join "\n", @bad, 'make corpus-stamp writes them';

# rows and records: one each way; the table's list text as the script's
my @here = main::records_here();
my @norow = grep !$row->{$_}, @here; my %here = map +($_ => 1), @here; my @nofile = grep !$here{$_}, sort keys %$row;
my @unlisted = grep !$RECORD{$_}, @here;
ok(!@norow && !@nofile && !@unlisted, 'a row for every record, a record for every row') or diag join "\n",
  (map "$_: not in large-subset-stamp.pl's %RECORD: add it there (what it is to the runs, what rewrites it), then make corpus-stamp", @unlisted),
  (map "$_: no row: make corpus-stamp LABEL=... RUN=... (the runs it was made from)", grep $RECORD{$_}, @norow),
  (map "$_: a row, but no such record: make corpus-stamp drops the row", @nofile);
my @stale = grep { $RECORD{$_} && $row->{$_} && ($row->{$_}{relation} ne $RECORD{$_}[0] || $row->{$_}{redo} ne $RECORD{$_}[1]) } @here;
ok(!@stale, "relation and redo as large-subset-stamp.pl's %RECORD says") or diag join "\n",
  map { my $r = $row->{$_}; "$_: " . stamp_cmd($r) . ' TOOLS=' . substr($r->{tools}, 0, 7) . " RECORDS=$_" } @stale;

# each record as stamped
for my $f (grep $row->{$_}, @here) {
  my $r = $row->{$f};
  my $stamp = stamp_cmd($r);
  is(main::hash_of($f), $r->{sha256}, "$f: as stamped ($r->{relation}, $r->{runs})") or diag $r->{relation} eq 'read'
    ? "$f changed since the records were made with it.  It is $r->{redo}; then $stamp (it stamps every record that changed, this one too)."
    : "$f changed since it was stamped.\nIf it was made again from stored runs: $stamp, with LABEL and RUN of those runs.\n" .
      "Else (changed by hand, or a tool or list it comes from changed), to make it again: $r->{redo}; then $stamp." }

# the distribution ships them
if (open my $m, '<', 'MANIFEST') { my %in = map { chomp; s/\s.*//; ($_ => 1) } <$m>;
  my @out = grep !$in{$_}, $TABLE, @here; ok(!@out, 'MANIFEST lists the table and every record') or diag "not in MANIFEST: @out" }

# one collection, one archive and one run
my %of; push @{$of{$_->{runs}}}, $_ for values %$row;
for my $c (sort keys %of) { my %a = map +("$_->{archive} $_->{run}" => 1), @{$of{$c}};
  ok(keys %a == 1, "$c: one archive and one run commit in all its rows") or diag "$c: ", join(' | ', sort keys %a), ': make corpus-stamp' }

# the commits, in a git clone of Proc-Spawner
SKIP: {
  my $no = !$GIT ? 'git is not installed' : !length $TOP ? 'this directory is in no git clone (a distribution, as from CPAN)'
         : !$WORK ? "the git clone around it, $TOP, is not one of Proc-Spawner" : '';
  if ($no) { why("The commits the table names are not checked: $no.  Only a git clone of Proc-Spawner's own repository, " .
                 "which is not public, has them; what can be checked without it, each record's SHA-256, was checked above."); skip "the commits: $no", 1 }
  my $shallow = `git rev-parse --is-shallow-repository 2>$NUL` =~ /true/;
  my %c = map +($_ => 1), map @{$_}{qw(run tools)}, values %$row;
  for my $c (sort keys %c) {
    SKIP: {
      if (system(qq{git cat-file -e "$c^{commit}" 2>$NUL}) != 0) {
        if ($shallow) { diag "$c: not in this shallow clone; to check it: git fetch --depth=1000 origin main"; skip "$c: not in this shallow clone", 1 }
        fail("$c: a commit the table names is not in this clone"); diag "the records' runs or tools: make corpus-stamp with commits of this history"; next }
      ok(system(qq{git merge-base --is-ancestor "$c" HEAD 2>$NUL}) == 0, "$c: in HEAD's history") or
        diag "$c is not an ancestor of HEAD: the records were made by code this branch does not have" } } }

# the collections, with a clone of Proc-Spawner-results
SKIP: {
  my ($dir, $why) = main::find_results();
  if (!$dir) { why("The collections are not checked: $why."); skip 'the collections: ' . ($why =~ s/\.  To check them.*//sr), 1 }
  for my $c (sort keys %of) {
    my $r = $of{$c}[0]; my $d = "$dir/$c";
    ok(-d $d, "$c: in $dir") or do { diag "$d: missing: the clone may be older than the table (git -C $dir pull), or the runs were never stored there"; next };
    my $sum; if (open my $h, '<', "$d/SHA256SUMS") { while (<$h>) { $sum = $1 if /^([0-9a-f]{64})\s+\*?corpus-work\.tar\.xz$/ } }
    is($sum // 'none', $r->{archive}, "$c: SHA256SUMS names the archive the table names");
    SKIP: { skip "$c: corpus-work.tar.xz not in $d", 1 unless -f "$d/corpus-work.tar.xz";
      is(Digest::SHA->new(256)->addfile("$d/corpus-work.tar.xz")->hexdigest, $r->{archive}, "$c: corpus-work.tar.xz has that SHA-256") }
    my $readme = ''; if (open my $h, '<', "$d/README.md") { local $/; $readme = <$h> // '' }
    ok(index($readme, substr($r->{run}, 0, 7)) >= 0, "$c: its README names the run's commit " . substr($r->{run}, 0, 7)) } }

done_testing;
