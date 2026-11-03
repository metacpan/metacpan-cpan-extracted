#!/usr/bin/perl
# large-subset-yardsticks.pl (2026-11-02; see doc/large-subset/large-subset-ceiling.md). Two yardsticks per source:
#   upper ("both parse, nothing bogus found"): dash -n and bash --posix -n accept the sample, ShellCheck (-s dash)
#     gives no SC3xxx warning, and our parser did not reject it for a form where one shell errors or gives a
#     blatantly different result (%BLATANT);
#   lower ("compatible"): upper, and our parser did not reject it for a subtle difference either (%SUBTLE).
# The verdict per rejection message is a judgement, listed here so it can be checked and changed.
# Usage: perl large-subset-yardsticks.pl [-v] samples.jsonl large-scan.jsonl drops.tsv
use strict; use warnings; use JSON::PP;
my $V = @ARGV && $ARGV[0] eq '-v' && shift;
my @BLATANT = (   # [message regex, why]
  [qr/^unsupported parameter form/, 'arrays: dash "Bad substitution"'],
  [qr/^'\(\('/, '((...)): dash runs a subshell of a subshell or fails'],
  [qr/as a command \(bash reads an array\)/, 'NAME[...]=: dash runs a command of that name'],
  [qr/^an input redirection without a command/, '$(<file): dash gives nothing, bash the file'],
  [qr/^'&>'/, 'cmd &>f: dash runs cmd in the background'],
  [qr/^'>&' takes one digit/, '>& file: dash error'],
  [qr/^unsupported signal for 'trap'/, 'SIGINT, ERR: dash error'],
  [qr/^'(?:return|local)' outside a/, 'return: dash ends the string, bash errors and goes on; local: both error, only dash stops'],
);
my @SUBTLE = (
  [qr/without arguments|it lists/, 'listing format'],
  [qr/^pattern that may match/, '.* matches . and .. in dash (G2)'],
  [qr/^bracket expression/, '[^...] (G14)'],
  [qr/where it is not split|on the joined string/, '$@ joined differently (G3, G4)'],
  [qr/^'local NAME' without a value/, 'G1'],
  [qr/^settings with a redirection/, 'order of assignment and redirection'],
  [qr/^function named/, 'function named like a builtin (G17)'],
  [qr/^'\.' with other than one argument/, 'bash passes the arguments, dash ignores them'],
  [qr/^unsupported 'read' argument/, 'read -p and other options (G18, H12), or a name from an expansion'],
);
my $SETOPT = qr/^unsupported 'set(?: -o)?' (?:form|option)/;   # decided on the text: bash-only option or listing
my ($samples, $scan, $drops) = @ARGV; my (%t, %drop, %S, %cat);
open my $s, '<', $samples or die; while (<$s>) { my $h = decode_json $_; $t{"$h->{src}\0$h->{id}"} //= $h->{text} }
open my $d, '<', $drops or die; while (<$d>) { my ($src, $id) = split /\t/; $drop{"$src\0$id"} = 1 }
open my $in, '<', $scan or die;
while (<$in>) { my $r = decode_json $_; my $k = "$r->{src}\0$r->{id}"; next if $drop{$k};
  my $w = $r->{large} ? '' : $r->{why}; my $v = '';
  if ($w =~ $SETOPT) { $v = $t{$k} =~ /\bset[ \t]+(?:-o[ \t]*(?:$|[;|&)])|-[a-zA-Z]*[BHUgm]|-\w*o[ \t]+(?:history|pipefail|posix|histexpand))/m ? 'blatant' : $t{$k} =~ /\bset[ \t]+(?:-o[ \t]*(?:$|[;|&)])|[-+][a-zA-Z]*[xv])/m ? 'subtle' : '' }   # set -o vi, emacs: no difference
  else { $v = 'blatant' if grep $w =~ $$_[0], @BLATANT; $v ||= 'subtle' if grep $w =~ $$_[0], @SUBTLE }
  my $src = $r->{src} . ($r->{tag} ? ":$r->{tag}" : ''); my $x = $S{$src} //= {};
  my $up = $r->{dash} && $r->{bash} && !@{$r->{sc}} && $v ne 'blatant'; my $low = $up && $v ne 'subtle';
  $x->{n}++; $x->{lg} += $r->{large}; $x->{up} += $up; $x->{low} += $low; $x->{rej} += $low && !$r->{large};
  $x->{inc} += $r->{large} && @{$r->{sc}} ? 1 : 0; $cat{$v}{$w =~ s/'[^']*'/'…'/gr}++ if $v }
printf "%-20s %6s %8s %8s %8s %10s %10s\n", qw(source n large lower upper rej-lower accepted-inc);
for (sort keys %S) { my $x = $S{$_}; my $p = sub { sprintf '%.1f%%', 100 * $x->{$_[0]} / $x->{n} };
  printf "%-20s %6d %8s %8s %8s %10d %10d\n", $_, $x->{n}, map($p->($_), qw(lg low up)), $x->{rej}, $x->{inc} }
if ($V) { for my $v (sort keys %cat) { print "\n$v:\n"; printf "  %4d  %s\n", $cat{$v}{$_}, $_ for sort { $cat{$v}{$b} <=> $cat{$v}{$a} } keys %{$cat{$v}} } }
