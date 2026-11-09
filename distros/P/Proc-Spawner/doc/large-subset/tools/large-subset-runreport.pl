#!/usr/bin/perl
# large-subset-runreport.pl (post4-0.04, 2026-11-05): compare what dash, bash --posix and Proc::ShellSpawn did with each
# corpus sample (large-subset-runcompare.pl's OUTDIR/run-*.jsonl).
# Usage: perl large-subset-runreport.pl [-l LIST.tsv] [-q QDIR] OUTDIR
#   prints a table per source; -l writes one line per sample where ours differs: id, class, parts, verdict, text excerpt.
#   -q QDIR (large-subset-runcompare.pl -q's output): two tables more, for the samples where a program the subset runs in
#   place of a builtin (echo, printf, test, [, kill, pwd: "coreutils") is involved, and for the others.  Involved: ours
#   handed it a call (QDIR's log; not a call that another program makes, such as xargs kill, the same in every shell), or the name stands where a command does in the text (this catches the calls ours
#   answers itself in place of the program: K0, rule F, kill $$).
#   -x: also the atomic calls of external programs (not the coreutils ones): every sample that makes some, in the classes
#   of the main table (the calls compared as a sorted list); where dash and bash agree and ours differs, call by call.
#   -b BASEDIR (post-0.09, X27): OUTDIR is a run with -env (large-subset-runcompare.pl), BASEDIR one of the same samples
#   without: a table of each sample's class in BASEDIR against its class in OUTDIR, and every sample whose class changed
#   or whose result changed (status, out, err, rec, files, in any of the three shells: "same class, other result").
#   -c FILE: every sample's class, one line each (id, class).
# Before comparing, each shell's own prefix is taken off its messages ("dash: 1: ", "bash: line 1: ", "bash: ",
# "sh: 1: ", "sh: ", also after a path, and for dash and bash also inside a line): the wording after it is still
# compared, but as a multiset of characters, because the shells write a message of a pipeline element in several
# pieces, which mix with the other elements' (dash: "dash: 1: dash: 1: cannot open f: No such filecolumn: not found").
# So a different wording is seen; a different order of the same messages is not.  The parts compared: status, out, err, rec (the programs
# called, with their arguments, sorted: pipeline elements run at once), files (what the run's directory holds afterwards).
# Classes:  same      all three agree
#           msg=dash, msg=bash, msg-own: status, out, rec and files agree in all three, only the messages (err)
#                     differ: ours are worded as dash's, as bash's, or as neither (dash and bash word many alike
#                     messages differently: "not found" / "command not found")
#           OURS      dash and bash agree, ours differs, beyond the messages (the work list for accepted samples)
#           =dash, =bash, neither: dash and bash differ beyond the messages; ours agrees with dash, with bash, or
#                     with neither (messages ignored here)
#           timeout   a shell ran out of time (5 s); not compared
use strict; use warnings; use JSON::PP; use Getopt::Long; binmode STDOUT, ':utf8';
my ($LIST, $QD, $X, $BD, $CF); GetOptions('l=s' => \$LIST, 'q=s' => \$QD, 'x' => \$X, 'b=s' => \$BD, 'c=s' => \$CF) && @ARGV == 1
  or die "usage: $0 [-l LIST.tsv] [-q QDIR] [-x] [-b BASEDIR] [-c CLASSES.tsv] OUTDIR\n";
my %TOOL = map +($_ => 1), qw(echo printf test [ kill pwd);
my $CMD = qr/(?:^|[;&|({!`]\s*|\$\(\s*|\b(?:then|do|else|elif|command|exec|time|xargs|env)\s+|&&\s*|\|\|\s*)(?:echo|printf|test|\[|kill|pwd)(?=[\s;&|)`]|\z)/m;
my %INV;   # sample id => 1 if a coreutils tool is involved
if ($QD) { for my $f (glob "$QD/run-*.jsonl") { open my $in, '<', $f or die;
  while (<$in>) { my $s = eval { decode_json($_) } or next;
    for (split /\n/, $s->{ours}{rec} // '') { my $who = s/^([^\035\037]*)\035// ? $1 : 'perl';   # the caller (-q logs it)
      $INV{$s->{id}} = 1 if $who =~ /^perl/ && $TOOL{(split /\037/)[0] // ''} } } } }
my @P = qw(status out rec files);   # the messages (err) separately
my %PFX = (dash => qr/(?:\S*\/)?dash: \d+: /, bash => qr/(?:\S*\/)?bash: (?:line \d+: )?/, ours => qr/(?:^|(?<=\n))sh: /);
sub norm { my ($r, $sh) = @_; my %n = %$r;
  $n{err} =~ s/$PFX{$sh}//g;                   # dash and bash: also inside a line, where pipeline elements' messages mixed
  $n{err} = join '', sort split //, $n{err} =~ s/\n//gr;   # so the messages compare as a multiset of characters
  $n{rec} = join "\n", sort split /\n/, $n{rec};   # pipeline elements log in any order
  \%n }
sub classify { my $s = shift;   # the class of one sample, and the parts that differ
  my ($d, $b, $o) = map norm($s->{$_}, $_), qw(dash bash ours);
  my $diff = sub { my ($x, $y) = @_; grep $x->{$_} ne $y->{$_}, @P };
  my $cls; my @dp;
  if (grep { $_->{status} =~ /^(?:124|137)\z/ } $d, $b, $o) { $cls = 'timeout' }
  elsif (!$diff->($d, $b) && !$diff->($d, $o)) {
    $cls = $d->{err} eq $b->{err} && $d->{err} eq $o->{err} ? 'same' : $o->{err} eq $d->{err} ? 'msg=dash'
         : $o->{err} eq $b->{err} ? 'msg=bash' : 'msg-own' }
  elsif (!$diff->($d, $b)) { @dp = $diff->($d, $o); $cls = 'OURS' }
  else { $cls = !$diff->($o, $d) ? '=dash' : !$diff->($o, $b) ? '=bash' : 'neither'; @dp = $diff->($d, $b) }
  ($cls, @dp) }
my (%t, %parts, %srcs, @list, $total, %cls, %res);
for my $f (glob "$ARGV[0]/run-*.jsonl") {
  open my $in, '<', $f or die;
  while (<$in>) {
    my $s = eval { decode_json($_) } or next; $total++;
    my ($cls, @dp) = classify($s); $cls{$s->{id}} = $cls; $res{$s->{id}} = $s if $BD;
    $t{$s->{src}}{$cls}++; $t{ALL}{$cls}++; $srcs{$s->{src}} = 1;
    if ($QD) { my $g = $INV{$s->{id}} || ($s->{text} // '') =~ $CMD ? 'coreutils involved' : 'no coreutils'; $t{"$g:$s->{src}"}{$cls}++; $t{"$g:ALL"}{$cls}++ }
    if ($cls =~ /^(?:OURS|neither|msg-own)\z/) {
      $parts{$cls}{join '+', @dp}++;
      (my $x = $s->{text} // '') =~ s/\s+/ /g;
      push @list, join "\t", $s->{id}, $cls, join('+', @dp), $s->{verdict} // '', substr($x, 0, 120) } } }
die "no results in $ARGV[0]\n" unless $total;
my @C = qw(same msg=dash msg=bash msg-own OURS =dash =bash neither timeout);
for my $g ('', $QD ? ('coreutils involved:', 'no coreutils:') : ()) {
  print "\n", $g =~ s/:$//r, ":\n" if $g;
  printf "%-20s %7s %s\n", 'source', 'n', join ' ', map sprintf('%8s', $_), @C;
  for my $src (sort(keys %srcs), 'ALL') { my $n = 0; $n += $_ for values %{$t{"$g$src"} // {}}; next unless $n;
    printf "%-20s %7d %s\n", $src, $n, join ' ', map sprintf('%8d', $t{"$g$src"}{$_} // 0), @C } }
for my $c (qw(OURS neither)) { print "\n$c, by the parts that differ", $c eq 'OURS' ? " (ours against both shells)" : " (dash against bash)", ":\n";
  printf "  %6d  %s\n", $parts{$c}{$_}, $_ for sort { $parts{$c}{$b} <=> $parts{$c}{$a} } keys %{$parts{$c} // {}} }
if ($X) {   # the external calls (not the coreutils ones), as the main table: by sample, in the same classes, with their calls
  my %Q = map +($_ => 1), qw(echo printf test [ kill pwd true false); my (%n, %calls, @odd);
  for my $f (glob "$ARGV[0]/run-*.jsonl") { open my $in, '<', $f or die;
    while (<$in>) { my $s = eval { decode_json($_) } or next;
      my %L = map { my $sh = $_; ($sh => [sort grep { length && !$Q{(split /\037/)[0]} } split /\n/, $s->{$sh}{rec} // '']) } qw(dash bash ours);
      next unless grep @{$L{$_}}, qw(dash bash ours);
      my ($d, $b, $o) = map "@{$L{$_}}", qw(dash bash ours);
      my $cls = (grep { $s->{$_}{status} =~ /^(?:124|137)\z/ } qw(dash bash ours)) ? 'timeout'
              : $d eq $b ? ($o eq $d ? 'same' : 'OURS') : $o eq $d ? '=dash' : $o eq $b ? '=bash' : 'neither';
      my $g = $QD ? ($INV{$s->{id}} || ($s->{text} // '') =~ $CMD ? 'coreutils involved' : 'no coreutils') : 'all';
      $n{$g}{$cls}++; $n{'all '}{$cls}++ if $QD; $calls{$cls} += @{$L{dash}};
      if ($cls eq 'OURS') { my (%c, %oo); $c{$_}++ for @{$L{dash}}; $oo{$_}++ for @{$L{ours}};
        for my $l (sort keys %c) { push @odd, "missing\t$s->{id}\t" . ($l =~ s/\037/ /gr) for 1 .. $c{$l} - ($oo{$l} // 0) }
        for my $l (sort keys %oo) { push @odd, "extra\t$s->{id}\t" . ($l =~ s/\037/ /gr) for 1 .. $oo{$l} - ($c{$l} // 0) } } } }
  my @X = qw(same OURS =dash =bash neither timeout);
  print "\nExternal calls (programs other than echo, printf, test, [, kill, pwd, true, false), by sample, compared as sorted\n",
    "lists of the calls with their arguments:\n"; printf "%-20s %7s %s\n", '', 'samples', join ' ', map sprintf('%8s', $_), @X;
  for my $g (grep $n{$_}, 'coreutils involved', 'no coreutils', 'all', 'all ') { my $t = 0; $t += $_ for values %{$n{$g}};
    printf "%-20s %7d %s\n", $g, $t, join ' ', map sprintf('%8d', $n{$g}{$_} // 0), @X }
  printf "%-20s %7s %s\n", "dash's calls in them", '', join ' ', map sprintf('%8d', $calls{$_} // 0), @X;
  print "Where dash and bash agree and ours differs, call by call:\n", map "  $_\n", @odd }
if ($LIST) { open my $o, '>', $LIST or die; print $o "id\tclass\tparts\tverdict\ttext\n", map "$_\n", sort @list }
if ($CF) { open my $o, '>', $CF or die; print $o "id\tclass\n", map "$_\t$cls{$_}\n", sort keys %cls }
if ($BD) {   # base run against this (-env) run, sample by sample
  my (%tr, @chg, $nb); my @C2 = (@C, 'not in base');
  for my $f (glob "$BD/run-*.jsonl") { open my $in, '<', $f or die;
    while (<$in>) { my $b = eval { decode_json($_) } or next; my $v = $res{$b->{id}} or next; $nb++;
      my ($bc) = classify($b); my $vc = $cls{$b->{id}};
      my %nb = map +($_ => norm($b->{$_}, $_)), qw(dash bash ours); my %nv = map +($_ => norm($v->{$_}, $_)), qw(dash bash ours);
      my @what = grep { my $p = $_; grep { $nb{$_}{$p} ne $nv{$_}{$p} } qw(dash bash ours) } @P, 'err';   # as compared: rec sorted, err a multiset
      $tr{$bc}{$vc}++; delete $res{$b->{id}};
      (my $x = $v->{text} // '') =~ s/\s+/ /g;
      push @chg, join "\t", $b->{id}, $bc, $vc, join('+', @what), substr($x, 0, 120) if $bc ne $vc || @what } }
  $tr{'not in base'}{$cls{$_}}++ for keys %res;
  print "\nAgainst the base run $BD ($nb samples in both): rows the base run's class, columns this run's\n";
  printf "%-12s %s\n", '', join ' ', map sprintf('%8s', $_), @C;
  for my $r (grep $tr{$_}, @C2) { printf "%-12s %s\n", $r, join ' ', map sprintf('%8d', $tr{$r}{$_} // 0), @C }
  print "\nChanged (id, base class, class, what changed in any shell, text):\n", map "  $_\n", sort @chg }
