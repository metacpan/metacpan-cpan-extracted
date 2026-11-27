#!/usr/bin/perl
# large-subset-repeat.pl (X27, step 3; post-0.11, 2026-11-12): the same samples run many times in the same environment
# (large-subset-runcompare.pl, one OUTDIR per run), and what each shell gave: is a difference of ours a race (ShellSpawn gives
# only results that dash or bash also give, in some run) or ShellSpawn's own (a result neither shell gave in any run)?  For the
# samples the match report calls chance by the code race (large-subset-environment.md, section 12; TODO B: the races).
# A result is what the match report compares (large-subset-matchreport.pl's norm, copied): status, standard output
# without the shells' message lines, the programs' calls, the files (without message lines); messages do not count.
#
# Usage: perl large-subset-repeat.pl -ids MATCH.tsv DIR
#   from large-subset-matchreport.pl -o's table, the samples it calls chance by the code race: DIR/ids-ENV for every
#   environment (base, s1, ...) where such a sample was not the same in the three, one id a line (for -only).
# Usage: perl large-subset-repeat.pl [-o OUT.tsv] [-v] ENV=DIR ...
#   ENV: the environment's label (base, s1, ...); DIR: one run's OUTDIR; an ENV given many times: its runs.
#   Prints, per sample: each environment's runs, how many results each shell gave, and the verdict:
#     same         the three gave one result, the same, in every run (the difference seen before did not come again)
#     race         ShellSpawn gave only results that dash or bash gave too (in this environment, in some run)
#     ShellSpawn         ShellSpawn gave a result neither shell gave in any run (with -v: which parts differ from the nearest)
#   and over its environments the worst (shellspawn, then race, then same), with whether a shell varied (the shells' own race).
#   Then, over the pairs of a sample and an environment (post-0.12, the user, 2026-11-15): where ShellSpawn varies (more than
#   one result), whether each shell repeated (one result in every run), only one of them, or neither: only where a shell
#   repeats is ours' variation a difference of ours (chance); where both vary there is no one behaviour to compare with.
#   -o: one line per sample and environment (id, env, runs, results of dash, bash, ShellSpawn, verdict, ShellSpawn's own runs, shells
#   repeating: each, one, neither).
use strict; use warnings; use JSON::PP; use Getopt::Long; use Digest::MD5 'md5_hex';
sub ss { my $s = shift; $s->{shellspawn} //= delete $s->{ours} if ref $s eq 'HASH' && exists $s->{ours}; $s }   # records made before post-0.13's rename: ShellSpawn's result under the key ours
my ($OUT, $V, $IDS) = ('', 0, ''); GetOptions('o=s' => \$OUT, 'v' => \$V, 'ids=s' => \$IDS) && (@ARGV || length $OUT) or die "usage: $0 [-o OUT.tsv] [-v] ENV=DIR ... | -ids MATCH.tsv DIR\n";
if (length $IDS) { my $dir = shift; my %e; unlink glob "$dir/ids-*"; open my $in, '<', $IDS or die "$IDS: $!";
  while (<$in>) { next if /^#/; chomp; my @f = split /\t/; next unless ($f[7] // '') =~ /\(code [a-z -]*\brace\b/;
    for (split / /, $f[9] // '') { my ($env, $c) = split /:/; push @{$e{$env}}, $f[0] unless $c eq 'same' } }
  for my $env (sort keys %e) { open my $o, '>', "$dir/ids-$env" or die "$dir/ids-$env: $!"; my %u; print $o map "$_\n", grep !$u{$_}++, @{$e{$env}} }
  printf STDERR "%d environments, %d samples\n", scalar keys %e, scalar do { my %u = map +($_ => 1), map @$_, values %e; keys %u }; exit 0 }
my @P = qw(status out rec files);
my %PFX = (dash => qr/(?:\/\S*\/)?dash: \d+: /, bash => qr/(?:\/\S*\/)?bash: (?:line \d+: )?/, shellspawn => qr/(?:^|(?<=\n))sh: /);
my $MSGLINE = qr/^(?:(?:\S*\/)?dash: \d+: |(?:\S*\/)?bash: (?:line \d+: )?|sh: ).*(?:\n|\z)/m;
sub norm { my ($r, $sh) = @_; my %n = %$r; $n{err} =~ s/$PFX{$sh}//g;
  $n{out} =~ s/$MSGLINE//g; $n{files} = $r->{files_nomsg} if defined $r->{files_nomsg};
  $n{rec} = join "\n", sort split /\n/, $n{rec} =~ s/\n\z//r, -1; \%n }
sub key { my $n = shift; $n->{status} =~ /^(?:124|137)\z/ ? 'timeout' : md5_hex(join "\0", map $n->{$_} // '', @P) }
my (%R, %N, %EX);   # id => env => shell => key => count; id => env => runs; key => an example (the normalized result)
for (@ARGV) { my ($env, $dir) = /^([^=]+)=(.+)\z/ or die "$_: ENV=DIR\n";
  for my $f (glob "$dir/run-*.jsonl") { open my $in, '<', $f or die "$f: $!";
    while (<$in>) { my $s = ss(decode_json($_)); next unless ref $s->{shellspawn}; $N{$s->{id}}{$env}++;
      for my $sh (qw(dash bash shellspawn)) { my $n = norm($s->{$sh}, $sh); my $k = key($n); $R{$s->{id}}{$env}{$sh}{$k}++; $EX{$k} //= $n } } } }
my %RANK = (same => 0, race => 1, shellspawn => 2); my (%tally, @rows, %pairs, %psamples, %etally);
for my $id (sort keys %R) { my ($worst, $vary) = ('same', 0); my @lines;
  for my $env (sort { (($a =~ /(\d+)/)[0] // -1) <=> (($b =~ /(\d+)/)[0] // -1) || $a cmp $b } keys %{$R{$id}}) { my $r = $R{$id}{$env};
    my %sh = map +($_ => [sort keys %{$r->{$_} // {}}]), qw(dash bash shellspawn); my %shells = map +($_ => 1), @{$sh{dash}}, @{$sh{bash}};
    my @own = grep !$shells{$_}, @{$sh{shellspawn}}; my $nown = 0; $nown += $r->{shellspawn}{$_} for @own;
    my %all = map +($_ => 1), map @$_, values %sh;
    my $v = @own ? 'shellspawn' : keys %all == 1 ? 'same' : 'race'; $vary ||= @{$sh{dash}} > 1 || @{$sh{bash}} > 1;
    $worst = $v if $RANK{$v} > $RANK{$worst};
    my $line = sprintf "  %-5s %2d runs  results: dash %d, bash %d, ShellSpawn %d  %s%s", $env, $N{$id}{$env}, map(scalar @{$sh{$_}}, qw(dash bash shellspawn)), $v,
      @own ? " (ShellSpawn's own in $nown runs)" : '';
    if ($V && @own) { for my $k (@own) { my $e = $EX{$k};   # which parts differ from the nearest result of a shell
        my ($best) = sort { $a->[0] <=> $b->[0] } map { my $s = $EX{$_}; [scalar(grep { ($e->{$_} // '') ne ($s->{$_} // '') } @P), $s] } grep $_ ne 'timeout', keys %shells;
        $line .= "\n        ShellSpawn: " . ($k eq 'timeout' ? 'timeout' : join '; ', map { my $p = $_; "$p " . JSON::PP->new->encode([substr($e->{$p} // '', 0, 120)]) . ($best && ($best->[1]{$p} // '') ne ($e->{$p} // '') ? ' (a shell: ' . JSON::PP->new->encode([substr($best->[1]{$p} // '', 0, 120)]) . ')' : '') } @P) } }
    my $rep = (@{$sh{dash}} == 1) + (@{$sh{bash}} == 1); my $shells = (qw(neither one each))[$rep];
    my $pk = (@{$sh{shellspawn}} > 1 ? 'ShellSpawn varies' : 'ShellSpawn repeats') . ", $shells " . ($rep == 1 ? 'shell repeats' : $rep ? 'repeat' : 'varies (not comparable)');
    $pk =~ s/neither varies/both shells vary/; $pk =~ s/each repeat\b/each shell repeats/;
    $pairs{$pk}++; $psamples{$pk}{$id} = 1; $etally{$env}{$v}++; $etally{$env}{$pk}++;
    push @lines, $line; push @rows, join("\t", $id, $env, $N{$id}{$env}, map(scalar @{$sh{$_}}, qw(dash bash shellspawn)), $v, $nown, $shells) }
  $tally{$worst}++; $tally{"$worst, a shell varied"}++ if $vary;
  print "$id: $worst", ($vary ? ' (a shell varied)' : ''), "\n", map("$_\n", @lines) }
print "\n", (%tally ? join(', ', map "$_ $tally{$_}", sort keys %tally) : 'no samples (none called chance by the code race)'), "\n";
if (%pairs) { my $n = 0; $n += $_ for values %pairs;
  my ($e, $o) = map $pairs{"ShellSpawn varies, $_"} // 0, 'each shell repeats', 'one shell repeats';
  my %s = map +($_ => scalar keys %{$psamples{"ShellSpawn varies, $_"} // {}}), 'each shell repeats', 'one shell repeats';
  my %u = map +($_ => 1), map keys %{$psamples{"ShellSpawn varies, $_"} // {}}, 'each shell repeats', 'one shell repeats';
  printf "%d pairs of a sample and an environment; ShellSpawn varies where a shell repeats: %d + %d = %d (each shell repeats + one shell repeats; samples %d + %d, %d in all)\n",
    $n, $e, $o, $e + $o, $s{'each shell repeats'}, $s{'one shell repeats'}, scalar keys %u;
  print map "  $_: $pairs{$_}\n", sort keys %pairs;
  if (keys %etally > 1) { print "per environment (verdicts; where ShellSpawn varies: each shell repeats + one shell repeats; both shells vary):\n";
    for my $env (sort keys %etally) { my $t = $etally{$env};
      printf "  %-6s same %d, race %d, shellspawn %d; ShellSpawn varies %d + %d, both shells vary %d\n", $env, map($t->{$_} // 0, qw(same race shellspawn)),
        map($t->{"ShellSpawn varies, $_"} // 0, 'each shell repeats', 'one shell repeats'),
        ($t->{'ShellSpawn varies, both shells vary (not comparable)'} // 0) + ($t->{'ShellSpawn repeats, both shells vary (not comparable)'} // 0) } } }
if ($OUT) { open my $o, '>', $OUT or die "$OUT: $!";
  print $o "# large-subset-repeat.pl: id, environment, runs, results of dash, bash, ShellSpawn, verdict (same, race, shellspawn: ShellSpawn's own result), runs with ShellSpawn's own result, shells repeating (each, one, neither)\n", map "$_\n", @rows }
