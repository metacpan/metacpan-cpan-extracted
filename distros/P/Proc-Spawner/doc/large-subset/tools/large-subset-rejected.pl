#!/usr/bin/perl
# large-subset-rejected.pl (post-0.13, 2026-11-26): the corpus snippets that the large parser rejects, run in dash and
# bash --posix alone, and compared (README.md, "How close", the rejected snippets; make corpus-rejected).
# Usage: perl large-subset-rejected.pl -prepare CORPUS
#          writes CORPUS/rejected-samples.tsv (CORPUS/samples.tsv with column large set to 1 for the rejected, so that
#          large-subset-runcompare.pl runs them) and CORPUS/rejected.ids (their IDs, for its -only @FILE)
#        perl large-subset-rejected.pl [-full] [-o RECORD.tsv] SAMPLES.tsv SAMPLES.jsonl RUNDIR
#          RUNDIR: large-subset-runcompare.pl -shells dash,bash -only @CORPUS/rejected.ids's OUTDIR.  Prints the counts
#          per group; -o writes one line per snippet (the record large-subset-rejected.tsv).
#        -full (post-0.14, 2026-11-26): the record with the text (its last column, here and with -envs); without it
#          that column is left out and the header says how to restore it (large-subset-restore.pl, from SAMPLES.jsonl).
# The groups (README.md): work list (within the lower yardstick: verdict - or X), subtle (S), subtle, open (O), foreign
# (outside the upper yardstick, B): both shells parse it, or a shell cannot.  dash against bash, compared as
# large-subset-matchreport.pl compares (messages count nowhere: each shell's prefix taken off its messages, which are
# then compared as a multiset of characters; lines that start as a shell's message dropped from standard output; the
# files without such lines; the programs' calls sorted): same; messages only (they differ in the messages alone);
# differ (status, output, calls or files); timeout (a shell ran out of its 5 seconds, or was killed).
use strict; use warnings;
use JSON::PP ();

if (@ARGV == 3 && $ARGV[0] eq '-split') {   # (2026-11-26) the example environments, one file per environment K
  my (undef, $setups, $c) = @ARGV; my (%by, %ids);
  open my $in, '<', $setups or die "$setups: $!";
  while (<$in>) { next unless /\S/; my $o = JSON::PP->new->decode($_); push @{$by{$o->{k}}}, $_; $ids{$o->{id}} = 1 }
  for my $k (sort { $a <=> $b } keys %by) {
    open my $out, '>', "$c/rejected-setup-$k.jsonl" or die $!; print $out @{$by{$k}}; close $out or die $! }
  open my $out, '>', "$c/rejected-envs.ids" or die $!; print $out map "$_\n", sort keys %ids; close $out or die $!;
  print scalar(keys %ids), " snippets, environments ", join(' ', sort { $a <=> $b } keys %by), ": $c/rejected-setup-K.jsonl\n"; exit }

if (@ARGV == 2 && $ARGV[0] eq '-prepare') {
  my $c = $ARGV[1];
  open my $in, '<', "$c/samples.tsv" or die "$c/samples.tsv: $!";
  open my $out, '>', "$c/rejected-samples.tsv" or die $!; open my $ids, '>', "$c/rejected.ids" or die $!;
  my $n = 0;
  while (<$in>) {
    if ($. > 1) { chomp; my @f = split /\t/, $_, -1; if ($f[5] eq '0') { $f[5] = 1; print $ids "$f[1]\n"; $n++ } $_ = join("\t", @f) . "\n" }
    print $out $_ }
  close $out or die $!; close $ids or die $!;
  print "$n rejected snippets: $c/rejected.ids, $c/rejected-samples.tsv\n"; exit }

my $full; if (@ARGV && $ARGV[0] eq '-full') { shift; $full = 1 }
my $record; if (@ARGV && $ARGV[0] eq '-o') { shift; $record = shift }
my $envs; if (@ARGV && $ARGV[0] eq '-envs') { shift; $envs = shift }   # (2026-11-26) SETUPS.jsonl, then RUNDIR RUNDIR-1 ...
my @envdirs; if ($envs) { @envdirs = splice @ARGV, 3 }
@ARGV == 3 or die "usage: $0 -prepare CORPUS | $0 -split SETUPS.jsonl CORPUS | $0 [-full] [-o RECORD.tsv] [-envs SETUPS.jsonl] SAMPLES.tsv SAMPLES.jsonl RUNDIR [RUNDIR-K ...]\n";
my ($tsv, $jsonl, $dir) = @ARGV;
my %info;   # id => [source, id, both, verdict, features, large, why, note]
{ open my $in, '<', $tsv or die "$tsv: $!"; <$in>;
  while (<$in>) { chomp; my @f = split /\t/, $_, -1; $info{$f[1]} = \@f if $f[5] eq '0' } }
my $J = JSON::PP->new;
my %text;
{ open my $in, '<', $jsonl or die "$jsonl: $!";
  while (<$in>) { my $o = $J->decode($_); $text{$o->{id}} = $o->{text} if $info{$o->{id}} } }
sub unshipped { my ($n, $what, $r) = @_;   # the header's lines on the column left out (-full: none)
  "# Column $n ($what) is not shipped; to restore it: perl -Ilib doc/large-subset/tools/large-subset-restore.pl\n",
  "#   -samples corpus-work/samples.jsonl doc/large-subset/tools/$r > WHOLE.tsv\n",
  "#   (from the distribution's directory; needs: corpus-work/samples.jsonl, made by make corpora corpus-samples; no shell\n",
  "#   snippet is run)\n" }
my %PFX = (dash => qr/(?:\/\S*\/)?dash: \d+: /, bash => qr/(?:\/\S*\/)?bash: (?:line \d+: )?/);
my $MSGLINE = qr/^(?:(?:\S*\/)?dash: \d+: |(?:\S*\/)?bash: (?:line \d+: )?|sh: ).*(?:\n|\z)/m;
sub norm { my ($r, $sh) = @_; my %n;
  $n{err} = join '', sort split //, (($r->{err} // '') =~ s/$PFX{$sh}//gr) =~ s/\n//gr;
  $n{out} = ($r->{out} // '') =~ s/$MSGLINE//gr;
  $n{files} = $r->{files_nomsg} // $r->{files} // '';
  $n{rec} = join "\n", sort split /\n/, ($r->{rec} // '') =~ s/\n\z//r, -1;
  $n{status} = $r->{status} // ''; \%n }
sub group { my $f = shift; my ($v, $both) = @$f[3, 2];
  $v eq '-' || $v eq 'X' ? 'work list' : $v eq 'S' ? 'subtle' : $v eq 'O' ? 'subtle, open'
  : $both ? 'foreign, both parse' : 'foreign, a shell cannot parse' }
sub compare_dir { my $dir = shift; my %res;
for my $f (sort glob "$dir/run-*.jsonl") {
  open my $in, '<', $f or die "$f: $!";
  while (<$in>) { my $o = $J->decode($_); $info{$o->{id}} or next;
    my ($d, $b) = (norm($o->{dash}, 'dash'), norm($o->{bash}, 'bash'));
    my ($c, $parts) = ('timeout', '');
    unless (grep $_->{status} =~ /^(?:124|137|signal 9)\z/, $d, $b) {
      my @p = grep $d->{$_} ne $b->{$_}, qw(status out rec files);
      $c = @p ? 'differ' : $d->{err} ne $b->{err} ? 'messages only' : 'same'; $parts = join '+', @p }
    $res{$o->{id}} = [$c, $parts, $o->{dash}{status} // '', $o->{bash}{status} // ''] } }
\%res }
my %res = %{compare_dir($dir)};
if ($envs) {   # every snippet of SETUPS: its outcome in the base run and in each environment, and over all of them
  my (%does, %ids); open my $in, '<', $envs or die "$envs: $!";
  while (<$in>) { next unless /\S/; my $o = $J->decode($_); $ids{$o->{id}} = 1; $does{$o->{id}}{$o->{k}} = join '; ', @{$o->{does} // []} }
  my @E = map { my ($k) = /-s?(\d+)\z/ or die "$_: no environment number at the end\n"; [$k, compare_dir($_)] } @envdirs;
  my %n; my @lines;
  for my $id (sort keys %ids) {
    my @o = ['base', $res{$id} // ['not run']];
    push @o, map [$_->[0], $_->[1]{$id}], grep $_->[1]{$id}, @E;
    my $alike = grep $_->[1][0] eq 'same' || $_->[1][0] eq 'messages only', @o;
    my $over = $alike == @o ? 'alike in every one' : $alike ? 'alike in some' : 'differ in every one';
    $n{$over}++;
    push @lines, join("\t", $id, $over, join(' ', map "$_->[0]:" . ($_->[1][0] =~ s/ /-/gr) . "($_->[1][2]/$_->[1][3])", @o),
      join(' | ', map "$_: $does{$id}{$_}", sort { $a <=> $b } keys %{$does{$id}}), $full ? ($text{$id} // '') =~ s/\n/ \x{23CE} /gr =~ s/\t/ /gr : ()) . "\n" }
  if (defined $record) {
    open my $out, '>:encoding(UTF-8)', $record or die "$record: $!";
    print $out "# large-subset-rejected-envs.tsv: rejected snippets of the work list, run in dash and bash --posix in the base\n",
      "# environment and in example environments made by reading them (large-subset-rejected-setups.jsonl; make\n",
      "# corpus-rejected-envs), compared as large-subset-rejected.pl compares.  Columns (tab): id; over all its environments:\n",
      "# alike in every one, alike in some, differ in every one; each environment's outcome (dash's status/bash's status);\n",
      "# what each environment does; the text (\x{23CE}: a newline).\n", $full ? () : unshipped(5, 'the text', 'large-subset-rejected-envs.tsv');
    print $out $_ for @lines; close $out or die $! }
  printf "%-22s %3d\n", $_, $n{$_} // 0 for 'alike in every one', 'alike in some', 'differ in every one';
  exit }
my %n; my @lines;
for my $id (sort keys %info) {
  my $g = group($info{$id}); my $r = $res{$id} // ['not run', '', '', ''];
  $n{$g}{$r->[0]}++;
  my $t = ($text{$id} // '') =~ s/\n/ \x{23CE} /gr =~ s/\t/ /gr;
  $t = substr($t, 0, 100);
  push @lines, join("\t", $id, $g, @$r, $info{$id}[6], $full ? $t : ()) . "\n" }
if (defined $record) {
  open my $out, '>:encoding(UTF-8)', $record or die "$record: $!";
  print $out "# large-subset-rejected.tsv: the snippets the large parser rejects, run in dash and bash --posix alone\n",
    "# (make corpus-rejected: large-subset-runcompare.pl -shells dash,bash, the environment of the base run), compared by\n",
    "# large-subset-rejected.pl as the match compares (messages count nowhere).  Columns (tab): id; group (README.md, \"How\n",
    "# close\", the rejected snippets); dash against bash: same, messages only, differ, timeout; the parts that differ; dash's\n",
    "# status; bash's status; the parser's reason (samples.tsv, why); the text, shortened (\x{23CE}: a newline).\n",
    $full ? () : unshipped(8, 'the text, shortened', 'large-subset-rejected.tsv');
  print $out $_ for @lines; close $out or die $! }
my @C = ('same', 'messages only', 'differ', 'timeout', 'not run');
for my $g ('work list', 'subtle', 'subtle, open', 'foreign, both parse', 'foreign, a shell cannot parse') {
  my $t = 0; $t += $_ for values %{$n{$g} // {}};
  printf "%-30s %5d   %s\n", $g, $t, join '   ', map "$_ $n{$g}{$_}", grep $n{$g}{$_}, @C }
