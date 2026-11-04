#!/usr/bin/perl
# Chunk coverage of scripts: cut each script into maximal accepted runs and rejected top-level constructs,
# then measure what an executor that runs accepted runs itself and hands the rest to sh would get.
# A rejected construct ends at the shortest run of whole lines from the failure's chain start that
# bash -n accepts without complaint (so an if ... fi or a here-document is one rejected piece).
use strict; use warnings; use Proc::ShellSubset; use JSON::PP;   # run with perl -Ilib (the distribution's lib/)
$ENV{HOME} //= '/root'; delete $ENV{CDPATH};
my %ALL = map +($_ => 1), qw(assign param_ops if while for case read);

sub bash_ok {   # bash -n accepts the text, with nothing on stderr (a cut here-document only warns)
  my $t = shift; my $pid = open my $h, '-|' // die "fork: $!";
  if (!$pid) { open STDERR, '>&', \*STDOUT; exec 'bash', '-n', '-c', $t; exit 127 }
  local $/; my $o = <$h>; close $h; !$? && !length $o }
sub lines { scalar grep /\S/ && !/^\s*#/, split /\n/, shift }

sub pieces {   # [accepted?, text], in order
  my ($s, %o) = @_; my @p;
  while ($s =~ /\S/) {
    my $r = Proc::ShellSubset::parse($s, empty => 1, %o);
    if (ref $r eq 'ARRAY') { push @p, [1, $s]; last }
    push @p, [1, substr $s, 0, $r->{last}] if $r->{last};
    my $rest = substr $s, $r->{last}; my @L = split /(?<=\n)/, $rest; my $end = length $rest;
    for my $k (1 .. @L) { my $t = join '', @L[0 .. $k - 1]; if (bash_ok($t)) { $end = length $t; last } }
    push @p, [0, substr $rest, 0, $end]; $s = substr $rest, $end }
  grep lines($_->[1]), @p }

my $STATE = qr/(?:^|[;&|({]\s*|\b(?:then|do|else)\s+)(?:cd|export|unset|set|shift|local|read|source|\.|trap|umask|ulimit|readonly|declare|typeset|eval)\b/m;
sub defines {   # names a rejected piece may set (heuristic)
  my $t = shift; my %n;
  $n{$1}++ while $t =~ /(?:^|[\s;&|(])([A-Za-z_]\w*)\+?=/g;
  $n{$_}++ for map { split ' ' } $t =~ /\bread\s+(?:-\w+\s+)*((?:[A-Za-z_]\w*\s*)+)/g;
  $n{$1}++ while $t =~ /\bfor\s+([A-Za-z_]\w*)/g;
  $n{$1}++ while $t =~ /^\s*(?:function\s+)?([A-Za-z_][\w-]*)\s*\(\s*\)/mg;
  keys %n }
