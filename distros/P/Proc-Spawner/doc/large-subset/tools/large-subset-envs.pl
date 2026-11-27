#!/usr/bin/perl
# large-subset-envs.pl (post-0.13, 2026-11-22): for each sample of a match (large-subset-matchreport.pl -o), every
# environment where ShellSpawn is not as both shells beyond the messages (its class is not same, msg=dash, msg=bash or
# msg-own), with what that environment's setup did and what dash, bash and ShellSpawn gave there: status, standard
# output, standard error, the programs called (rec), and whether the files left differ from dash's.
#
# Usage: perl large-subset-envs.pl [-only ID,...] MATCH.tsv DIR
#   DIR: large-subset-rerun.sh's OUT (base/, step2/, step3/, step3-affects-shell/: the runs and the setups' files).
#   The environments' labels are the match's: base, s1, ... (step 2), control/base, control/s1, ... (step 3, class
#   control: DIR/step3), affects-shell/base, ... (DIR/step3-affects-shell).  Long texts are cut at 200 characters.
# Used by large-subset-review.md, section 1.
use strict; use warnings; use JSON::PP;
sub ss { my $s = shift; $s->{shellspawn} //= delete $s->{ours} if ref $s eq 'HASH' && exists $s->{ours}; $s }   # records made before post-0.13's rename: ShellSpawn's result under the key ours
my %only; if (@ARGV && $ARGV[0] eq '-only') { shift; %only = map { $_ => 1 } split /,/, shift }
my ($match, $R) = @ARGV; die "usage: $0 [-only ID,...] MATCH.tsv DIR\n" unless defined $R;
my (%runs, %setups);
sub runs {   # DIR's run-*.jsonl, by sample
  my $d = shift; return $runs{$d} //= do { my %h;
    for my $f (glob "$d/run-*.jsonl") { open my $in, '<', $f or die "$f: $!"; while (<$in>) { my $j = ss(decode_json($_)); $h{$j->{id}} = $j } }
    \%h } }
sub does {   # what setup K of a family did to the sample
  my ($fam, $k, $id) = @_; my $f = "$R/$fam/setup-$k.jsonl"; return '(no setup file)' unless -e $f;
  $setups{$f} //= do { my %h; open my $in, '<', $f or die "$f: $!";
    while (<$in>) { my $j = ss(decode_json($_)); $h{$j->{id}} = join '; ', @{$j->{does} // []} } \%h };
  $setups{$f}{$id} // '(not in the setup)' }
sub cut { my $s = shift // ''; $s =~ s/\n/\\n/g; length($s) > 200 ? substr($s, 0, 200) . '...' : $s }
open my $in, '<', $match or die "$match: $!";
while (<$in>) {
  next if /^#/; chomp; my @c = split /\t/; my ($id, $classes) = ($c[0], $c[9] // '');
  next if %only && !$only{$id};
  print "=== $id\n";
  for my $e (split / /, $classes) {
    my ($env, $class) = split /:/, $e, 2; next if $class =~ /^(same|msg=dash|msg=bash|msg-own)\z/;
    my ($fam, $lab) = $env =~ m{/} ? split(m{/}, $env, 2) : ('', $env);
    my $famdir = $fam eq 'control' ? 'step3' : $fam eq 'affects-shell' ? 'step3-affects-shell' : 'step2';
    my $dir = !$fam && $lab eq 'base' ? "$R/base" : "$R/$famdir/$lab";
    my $k = $lab eq 'base' ? 0 : ($lab =~ /(\d+)/)[0];
    my $r = runs($dir)->{$id}; my $base = !$fam && $lab eq 'base';
    printf "  %-20s %-7s setup: %s\n", $env, $class, $base ? '(the base run)' : $lab eq 'base' ? '(the family\'s base run)' : does($famdir, $k, $id);
    unless ($r) { print "      (no record in $dir)\n"; next }
    for my $sh (qw(dash bash shellspawn)) {
      my $x = $r->{$sh} // {};
      printf "      %-4s st=%s out=[%s] err=[%s] rec=[%s]%s\n", $sh eq 'shellspawn' ? 'SS' : $sh, $x->{status} // '?', cut($x->{out}),
        cut($x->{err}), cut($x->{rec}), (($x->{files_nomsg} // '') ne ($r->{dash}{files_nomsg} // '') ? ' files differ from dash' : '') } } }
