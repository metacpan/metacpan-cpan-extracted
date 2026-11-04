# Per source: top-5 reasons why a one-liner is rejected, in percent of the rejected one-liners
use strict; use warnings; use Proc::ShellSubset; use JSON::PP;   # run with perl -Ilib (the distribution's lib/)
$ENV{HOME} //= '/root'; delete $ENV{CDPATH};
my %O = map +($_ => 1), qw(assign param_ops if while for case read);
my (%seen, %R, %N, %T, %EX); binmode STDOUT, ':utf8';
open my $h, '<', 'samples.jsonl' or die;
while (<$h>) { my $x = decode_json($_); next unless $x->{kind} eq 'line'; next if $seen{"$x->{src}\0$x->{text}"}++;
  my $src = $x->{src};
  for my $mode (qw(default options)) { $T{$mode}{$src}++;
    my $r = Proc::ShellSubset::parse($x->{text}, $mode eq 'options' ? %O : ()); next if ref $r eq 'ARRAY';
    (my $e = $r->{error}) =~ s/^(builtin|keyword|shell-set variable) '.*'/$1 NAME/;
    $R{$mode}{$src}{$e}++; $N{$mode}{$src}++;
    my $k = (split /\n/, substr $x->{text}, $r->{pos})[0] // ''; $EX{$mode}{$src}{$e}{substr $k, 0, 28}++ } }
for my $mode (qw(default options)) { print "\n== $mode\n";
  for my $src (sort keys %{$R{$mode}}) { my $r = $R{$mode}{$src};
    printf "%s: %d of %d one-liners rejected (%.1f%%)\n", $src, $N{$mode}{$src}, $T{$mode}{$src}, 100 * $N{$mode}{$src} / $T{$mode}{$src};
    for my $e ((sort { $r->{$b} <=> $r->{$a} } keys %$r)[0 .. 4]) { my $x = $EX{$mode}{$src}{$e};
      printf "  %5.1f%%  %-38s e.g. %s\n", 100 * $r->{$e} / $N{$mode}{$src}, $e, join ' | ', (sort { $x->{$b} <=> $x->{$a} } keys %$x)[0 .. 2] } } }
