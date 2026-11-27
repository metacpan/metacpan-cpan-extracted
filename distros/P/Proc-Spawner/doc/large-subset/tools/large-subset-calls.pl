#!/usr/bin/perl
# large-subset-calls.pl (post-0.12; A23 (c), the user, 2026-11-17: what each sample calls, kept for later use, each
# program marked by the shells that used it): marks the column CALLS of large-subset-provenance.tsv (written by
# large-subset-blocks.pl -e: the command names of each sample's parse tree) from the behaviour run
# (large-subset-runcompare.pl, without -q), shell by shell: NAME:DBO, one letter each for dash, bash and ShellSpawn,
#   p  that shell's run started a program of that name (the shell, or a program it ran: xargs, find -exec), as the
#      recorders logged it;
#   !  that shell said it was not found (its message on standard error);
#   -  neither.
# A name with neither in all three keeps no mark (a builtin, a function, or not reached).  A program started there whose
# name the text does not write as a command (an expansion made it, or another program started it) is added as
# =NAME:DBO, and so is a name not found there that an expansion made.
# Usage: perl large-subset-calls.pl PROVENANCE.tsv RUNDIR     (rewrites PROVENANCE.tsv; the marks of an earlier run go first)
use strict; use warnings; use JSON::PP;
sub ss { my $s = shift; $s->{shellspawn} //= delete $s->{ours} if ref $s eq 'HASH' && exists $s->{ours}; $s }   # records made before post-0.13's rename: ShellSpawn's result under the key ours
my ($PROV, $R) = @ARGV; defined $R or die "usage: $0 PROVENANCE.tsv RUNDIR\n";
sub enc { (my $e = shift) =~ s/([\s%!+=?:\\])/sprintf '%%%02X', ord $1/ge; $e }
my %NF = (dash => qr/^\S*dash: \d+: (?:.*: )?([^:\n]*): not found$/m, bash => qr/^\S*bash: (?:line \d+: )?(?:.*: )?([^:\n]*): command not found$/m,
          shellspawn => qr/^sh: (?:.*: )?([^:\n]*): not found$/m);
my %seen;   # id => { encoded name => [mark of dash, bash, ShellSpawn] }
for my $f (glob "$R/run-*.jsonl") { open my $in, '<', $f or die "$f: $!";
  while (<$in>) { my $s = eval { ss(decode_json($_)) } or next; my $h = $seen{$s->{id}} //= {};
    for my $i (0 .. 2) { my $r = $s->{(qw(dash bash shellspawn))[$i]} or next;
      for my $l (split /\n/, $r->{rec} // '') { my ($n) = split /[\036\037]/, $l, -1; next unless defined $n && length $n;   # (\036: a stand-in's input, IN1)
        ($h->{enc($n)} //= ['-', '-', '-'])->[$i] = 'p' }
      my $re = $NF{(qw(dash bash shellspawn))[$i]}; my $e = $r->{err} // '';
      while ($e =~ /$re/g) { my $m = $h->{enc($1)} //= ['-', '-', '-']; $m->[$i] = '!' unless $m->[$i] eq 'p' } } } }
keys %seen or die "$R: no run-*.jsonl\n";
open my $in, '<:utf8', $PROV or die "$PROV: $!"; my @l = <$in>; close $in; my ($n, $marked) = (0, 0);
for (@l) { next if /^#/; chomp; my ($id, $code, $calls) = split /\t/, $_, -1; defined $calls or die "$PROV: no column CALLS (large-subset-blocks.pl -e)\n";
  my @c = grep { !/^=/ } map { s/:[-p!]{3}\z//r } split ' ', $calls;   # (an earlier run's marks taken off)
  if (my $h = $seen{$id}) { my %in = map +($_ => 1), @c;
    @c = ((map { $_ ne '?' && $h->{$_} ? "$_:" . join('', @{$h->{$_}}) : $_ } @c), map "=$_:" . join('', @{$h->{$_}}), grep !$in{$_}, sort keys %$h);
    $marked++ }
  $_ = join("\t", $id, $code, join ' ', @c) . "\n"; $n++ }
open my $out, '>:utf8', "$PROV.new" or die; print $out @l; close $out; rename "$PROV.new", $PROV or die "$PROV: $!";
print STDERR "$n samples, $marked of them in the run $R\n";
