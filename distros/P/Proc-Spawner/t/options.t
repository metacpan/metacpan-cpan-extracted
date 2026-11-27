# Two options of the caller that bring in bash's ways; neither needs bash or any program here (printf and echo run inside
# Perl), and each string's output goes to a file in a temporary directory.
# Brace expansion (X3; the parser's option brace, Proc::ShellSubset): what the shell layer makes of {a,b} and {x..y},
# against what bash 5.2.21 printed for the same strings (written down here).
# redir_strict (X4; run's option): "ambiguous redirect" for a file name from an unquoted expansion that gives a blank or
# a pattern character, or nothing, where bash outside POSIX mode says so (and for every pattern, and for blanks at the
# ends, where bash goes on); without the option the value is the name as it is, as in dash.
use strict; use warnings;
use Test::More; use File::Temp 'tempdir'; use Cwd 'getcwd';
use Proc::ShellSubset::Large; use Proc::ShellSpawn;   # (the large parser: run's default here; it has no option brace)
my $parser = sub { Proc::ShellSubset::parse($_[0], %Proc::ShellSpawn::PARSE, brace => 1) };
my $top = getcwd; my $dir = tempdir(CLEANUP => 1); chdir $dir or die "$dir: $!";
for my $f ('a.c', 'b.c', 'x y') { open my $h, '>', $f or die "$f: $!"; close $h }
my $P = q{printf '[%s]'};
my @t = (   # [the string, what bash prints for it]
  ["$P f{,.bak} x{1..3}y {a,\"b c\"}", '[f][f.bak][x1y][x2y][x3y][a][b c]'],
  ["$P {a,b}{c,d}{e,f}", '[ace][acf][ade][adf][bce][bcf][bde][bdf]'],
  ["$P pre{a,b}post{1..2} {1..2}/{x,y}", '[preapost1][preapost2][prebpost1][prebpost2][1/x][1/y][2/x][2/y]'],
  ["$P {5..1} {-2..2} {c..a} {0..0} {-1..-3}", '[5][4][3][2][1][-2][-1][0][1][2][c][b][a][0][-1][-2][-3]'],
  ["$P {01..10} {1..010} {-01..1}", '[01][02][03][04][05][06][07][08][09][10][001][002][003][004][005][006][007][008][009][010][-01][000][001]'],
  ["$P {08..11} {-05..5} {007..9} {-9..-011} {0..00}",
   '[08][09][10][11][-05][-04][-03][-02][-01][000][001][002][003][004][005][007][008][009][-009][-010][-011][00]'],
  ["$P {X..b}", '[X][Y][Z][[][][]][^][_][`][a][b]'],   # (the word that is a lone backslash comes out empty in bash)
  ["$P a{,}b {,} {a,}", '[ab][ab][a]'],                 # an empty alternative: a word only if something is left of it
  ["$P {a,\"\"} {\"\",a} {a,''} {a,\"\"b}", '[a][][][a][a][][a][b]'],   # empty quotes: a word that stays
  ["x='p q'; $P {\$x,\"\$x\",r}", '[p][q][p q][r]'],   # the other expansions come after it: split, or kept whole in quotes
  ["x=1; $P \${x}{a,b} \"\$x\"{a,b} {a,b}\$x", '[1a][1b][1a][1b][a1][b1]'],
  ["$P {a,\$(echo b c)}{1,2}", '[a1][a2][b][c1][b][c2]'],
  ["x=1; $P {\$((x+1)),\${x:-q}}", '[2][1]'],
  ["$P {*.c,x*}", '[a.c][b.c][x y]'],                   # patterns in the alternatives match files
  ["$P \"a{b,c}\" 'x'{b,c} {a,b}{}", '[a{b,c}][xb][xc][a{}][b{}]'],   # quoted braces are text; {} is always text
  ["for i in {1..3} {a,b}; do printf '%s,' \$i; done", '1,2,3,a,b,'],
);
for (@t) {
  my ($s, $want) = @$_;
  my ($st, $err) = Proc::ShellSpawn::run("{ $s; } > out.txt", parser => $parser);
  my $got = !defined $st ? "outside the subset: $err->{error}" : do { open my $h, '<', 'out.txt' or die "out.txt: $!"; local $/; <$h> // '' };
  is $got, $want, $s }
# what the parser refuses with the option: in bash a brace's text joins a $NAME before it ($x{a,b} is $xa $xb)
for my $s ('echo $x{a,b}', 'echo a$x{1..2}') {
  my $r = $parser->($s);
  is ref $r eq 'HASH' ? $r->{error} : 'accepted', 'brace expansion right after $NAME', "refused: $s" }
is_deeply $parser->('echo {a,""}'), [[[{ argv => ['echo', [['{', 'a', [["'", '']]]]] }]]], 'the tree of {a,""}: empty quotes as a part of their own';
{ my $n = 0;
  my $try = sub {   # (STATUS, the messages, whether the file NAME is there afterwards) of STRING, with or without the option
    my ($s, $strict, $name) = @_; my $d = 'r' . ++$n; mkdir $d or die "$d: $!"; chdir $d or die;
    my ($st, $e) = Proc::ShellSpawn::run("{ $s; } 2> err.txt", redir_strict => $strict);
    my $err = !defined $st ? "outside the subset: $e->{error}" : do { open my $h, '<', 'err.txt' or die "err.txt: $!"; local $/; <$h> // '' };
    my $there = -e $name ? 1 : 0;
    chdir '..' or die; ($st, $err, $there) };
  my $amb = [2, "sh: ambiguous redirect\n", 0];
  for (["x='a b'; echo hi > \$x", 'a b', $amb, [0, '', 1]],                    # [STRING, NAME, with the option, without]
       ["x=; echo hi > \$x", 'x', $amb, [2, "sh: cannot create : Directory nonexistent\n", 0]],
       ["x='a[b]'; echo hi > \$x", 'a[b]', $amb, [0, '', 1]],              # (names that Windows can make too: no * or :)
       ["x=' a'; echo hi > \$x", ' a', $amb, [0, '', 1]],
       ["echo hi > \$(echo a b)", 'a b', $amb, [0, '', 1]],
       ["IFS=,; x=a,b; echo hi > \$x", 'a,b', $amb, [0, '', 1]],
       ["x='a b'; echo hi > \"\$x\"", 'a b', [0, '', 1], [0, '', 1]],          # in quotes: the name as it is
       ["x='a b'; echo hi > p\"\$x\"q", 'pa bq', [0, '', 1], [0, '', 1]],
       ["x=ab; echo hi > \$x.txt", 'ab.txt', [0, '', 1], [0, '', 1]],
       ["IFS=; x='a b'; echo hi > \$x", 'a b', [0, '', 1], [0, '', 1]],        # IFS empty: nothing is split
       ["echo hi > ''", 'x', [2, "sh: cannot create : Directory nonexistent\n", 0], [2, "sh: cannot create : Directory nonexistent\n", 0]]) {
    my ($s, $name, $with, $without) = @$_;
    is_deeply [$try->($s, 1, $name)], $with, "redir_strict: $s";
    is_deeply [$try->($s, 0, $name)], $without, "without it: $s" } }
chdir $top; done_testing;
