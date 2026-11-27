#!/usr/bin/perl
# large-subset-restore.pl (post-0.14, 2026-11-26): a record shipped without its last column made whole again, byte for
# byte as its writer writes it with -full, from the distribution and the pinned public corpora alone: no stored run
# (the repository Proc-Spawner-results) is read and no shell snippet is run.  The owner decided (2026-11-26) to ship
# these records without a column the tools can make again; each such record's header ends with a line "# Column N
# (WHAT) is not shipped; to restore it: ..." and its continuation lines ("#   ..."), which the whole record has not.
#
# Usage, from the distribution's directory:
#   perl -Ilib doc/large-subset/tools/large-subset-restore.pl [-samples S.jsonl] [-setups SETUPS.tsv] RECORD > WHOLE
#   -samples  every corpus sample (default corpus-work/samples.jsonl; make corpora corpus-samples: the sources at their
#             pinned commits, about a minute, then large-subset-extract.pl)
#   -setups   (the large-subset-env-*.tsv records) a setups list already made (large-subset-setups.pl's
#             PREFIX-samples.tsv, as a stored run has it) instead of making it again
#   RECORD    one of these (known by the file name its first line gives):
#     large-subset-step3.tsv          column 6, the text: each sample's text (the first sample of that id: 22 IDs come
#                                     twice), as large-subset-blocks.pl -p -full writes it
#     large-subset-rejected.tsv       column 8, the text shortened, and
#     large-subset-rejected-envs.tsv  column 5, the text: from the last sample of that id, as large-subset-rejected.pl
#                                     -full writes them; the text only for the samples the large parser rejects (those
#                                     of large-subset-rejected.tsv), as there
#     large-subset-env-setups.tsv     column 8, what each setup did: the step-2 setups made again, as make corpus-step2
#                                     makes them before its runs (large-subset-blocks.pl -d, then large-subset-setups.pl
#                                     -all -full 2 -one), joined as large-subset-matchreport.pl -record -full joins them
#     large-subset-env-control.tsv    column 8, the same for step 3 (large-subset-setups.pl -step3
#     large-subset-env-affects-shell.tsv  large-subset-step3.tsv; -class affects-shell), as make corpus-step3 makes them
#   large-subset-blocks.pl -d takes the samples the large parser accepts from samples.tsv, which only the scan makes
#   (make corpus-scan, 25 minutes, then corpus-parse); here they are the samples of large-subset-provenance.tsv, the
#   same set (checked 2026-11-26: the same 40,409 IDs).  The step-3 setups of absolute names read this system's files
#   (a pattern's matches, whether a file exists: large-subset-setups.pl -step3), so those rows come back byte for byte
#   only on a system like the one of the runs (Ubuntu 24.04 in a Claude Code container, where /* matched the file
#   /container_info.json alone: 2 rows of large-subset-env-affects-shell.tsv); the step-2 setups name no absolute file.
use strict; use warnings; use JSON::PP; use Getopt::Long; use File::Basename qw(dirname); use File::Temp qw(tempdir); use File::Spec;
my ($SAMPLES, $SETUPS) = ('corpus-work/samples.jsonl');
GetOptions('samples=s' => \$SAMPLES, 'setups=s' => \$SETUPS) && @ARGV == 1
  or die "usage: $0 [-samples SAMPLES.jsonl] [-setups SETUPS.tsv] RECORD > WHOLE\n";
my $REC = shift; my $T = dirname($0); my $PROV = "$T/../large-subset-provenance.tsv";
my ($KIND) = do { open my $in, '<', $REC or die "$REC: $!"; my $l = <$in> // ''; $l =~ /^# (large-subset-[\w-]+)\.tsv\b/ }
  or die "$REC: its first line names no record\n";
my %LAYER = ('large-subset-rejected' => ':encoding(UTF-8)', 'large-subset-rejected-envs' => ':encoding(UTF-8)');   # as each writer
my $LAYER = $LAYER{$KIND} // ':utf8';   # reads and writes (the others: :utf8, the texts from decode_json)
exists $LAYER{$KIND} || $KIND =~ /^large-subset-(?:step3|env-setups|env-control|env-affects-shell)\z/ or die "$REC: $KIND is not a record this tool restores\n";

# the record, without the lines that say how to restore it
my (@L, $cut); { open my $in, "<$LAYER", $REC or die "$REC: $!"; my $in_note;
  while (<$in>) { if (/^# Column \d+ \(.*\) is not shipped; to restore it/) { $in_note = $cut = 1; next }
    if ($in_note && /^#   /) { next } $in_note = 0; push @L, $_ } }
$cut or die "$REC: no line says a column is not shipped (whole already?)\n";

my %COL;   # id => the column's content
if ($KIND eq 'large-subset-step3') {   # large-subset-blocks.pl: the first sample of each id, its text with each newline as \n
  open my $in, '<', $SAMPLES or die "$SAMPLES: $!";
  while (<$in>) { my $s = decode_json $_; next if exists $COL{$s->{id}}; (my $x = $s->{text}) =~ s/\s*\n\s*/\\n/g; $COL{$s->{id}} = $x } }
elsif ($KIND =~ /^large-subset-rejected/) {   # large-subset-rejected.pl: the last sample of each id the large parser rejects
  my %rej; { my $f = "$T/large-subset-rejected.tsv"; open my $in, '<:encoding(UTF-8)', $f or die "$f: $!";
    while (<$in>) { next if /^#/; my ($id) = split /\t/; $rej{$id} = 1 } }
  my $J = JSON::PP->new; open my $in, '<', $SAMPLES or die "$SAMPLES: $!";
  while (<$in>) { my $o = $J->decode($_); $COL{$o->{id}} = $o->{text} if $rej{$o->{id}} }
  for (values %COL) { $_ = $_ =~ s/\n/ \x{23CE} /gr =~ s/\t/ /gr; $_ = substr($_, 0, 100) if $KIND eq 'large-subset-rejected' } }
else {   # the env records: what each setup did, from the setups list (large-subset-matchreport.pl's -setups, without FAMILY)
  my $file = $SETUPS // do {
    my $d = tempdir(CLEANUP => 1);
    { open my $o, '>', "$d/accepted.tsv" or die; print $o "id\tlarge\n";   # samples.tsv's two columns that blocks.pl reads
      open my $in, '<', $PROV or die "$PROV: $!"; while (<$in>) { next if /^#/; my ($id) = split /\t/; print $o "$id\t1\n" } close $o or die }
    my @I = map "-I$_", grep !ref, @INC;   # (as this run of perl has them: -Ilib)
    run($^X, @I, "$T/large-subset-blocks.pl", '-d', "$d/deps.jsonl", $SAMPLES, "$d/accepted.tsv");
    run($^X, @I, "$T/large-subset-setups.pl", qw(-all -full 2 -one),
      $KIND eq 'large-subset-env-setups' ? () : ('-step3', "$T/large-subset-step3.tsv", $KIND eq 'large-subset-env-affects-shell' ? qw(-class affects-shell) : ()),
      "$d/deps.jsonl", "$d/setup");
    "$d/setup-samples.tsv" };
  open my $in, '<:utf8', $file or die "$file: $!";
  while (<$in>) { next if /^#/; chomp; my ($id, $blk, $deps, @does) = split /\t/, $_, -1; $COL{$id} = join ' || ', @does } }
sub run { my @c = @_; STDOUT->flush; open my $save, '>&', \*STDOUT or die; open STDOUT, '>', File::Spec->devnull or die;   # (their
  my $r = system @c; open STDOUT, '>&', $save or die; $r == 0 or die "failed: @c\n" }                                 # reports: away)

binmode STDOUT, $LAYER;
for (@L) {
  if (/^#/) { print; next }
  chomp(my $l = $_);
  if ($KIND eq 'large-subset-step3' && $l =~ /^id\t/) { print "$l\ttext\n"; next }   # the columns' names
  my ($id) = split /\t/, $l;
  exists $COL{$id} or $KIND =~ /^large-subset-rejected/ or die "$REC: $id: not in " . ($KIND eq 'large-subset-step3' ? $SAMPLES : 'the setups') . "\n";
  print "$l\t", $COL{$id} // '', "\n" }
