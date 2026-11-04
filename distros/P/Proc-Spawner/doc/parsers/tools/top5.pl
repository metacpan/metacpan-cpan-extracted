# Per source: top-5 reasons why a rejected piece of a script fails (the piece after an accepted run, or a script start)
use strict; use warnings; use Proc::ShellSubset; use JSON::PP;   # run with perl -Ilib (the distribution's lib/)
$ENV{HOME} //= '/root'; delete $ENV{CDPATH};
do './chunkcov-lib.pl'; our %ALL;
my %O = map +($_ => 1), qw(assign param_ops if while for case read);
my (%seen, %R, %N, %L, %EX);
open my $h, '<', 'samples.jsonl' or die;
while (<$h>) { my $x = decode_json($_); next unless $x->{kind} eq 'script'; next if $seen{$x->{text}}++;
  (my $src = $x->{src}) =~ s/^pure.*/pure-*-bible/; $src =~ s/:.*//;
  for my $mode (qw(default options)) {
    for my $p (grep !$_->[0], pieces($x->{text}, $mode eq 'options' ? %O : ())) {
      my $r = Proc::ShellSubset::parse($p->[1], empty => 1, $mode eq 'options' ? %O : ());
      my $e = ref $r eq 'HASH' ? $r->{error} : '(parses alone)';

      my $n = lines($p->[1]); $R{$mode}{$src}{$e}[0]++; $R{$mode}{$src}{$e}[1] += $n; $N{$mode}{$src}++; $L{$mode}{$src} += $n;
      ($EX{$mode}{$src}{$e}) = (split /\n/, substr($p->[1], ref $r eq 'HASH' ? $r->{pos} : 0))[0] =~ s/^\s+//r unless $EX{$mode}{$src}{$e} } } }
for my $mode (qw(default options)) { print "\n== $mode\n";
  for my $src (sort keys %{$R{$mode}}) { my $r = $R{$mode}{$src};
    printf "%s: %d rejected pieces, %d lines\n", $src, $N{$mode}{$src}, $L{$mode}{$src};
    for my $e ((sort { $r->{$b}[0] <=> $r->{$a}[0] } keys %$r)[0 .. 4]) {
      printf "  %5.1f%% of pieces %5.1f%% of lines  %-40s e.g. %s\n", 100 * $r->{$e}[0] / $N{$mode}{$src}, 100 * $r->{$e}[1] / $L{$mode}{$src}, $e, substr($EX{$mode}{$src}{$e}, 0, 40) } } }
