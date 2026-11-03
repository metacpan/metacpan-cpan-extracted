# shellsubset-small-compare.pl DIR-WITH-ShellSubset.pm DIR-WITH-ShellSubsetSmall.pm TESTFILE...
# For every test string and probe: Proc::ShellSubset::parse($s, frozen options) vs Proc::ShellSubset::Small::parse($s), whole value
# (as Data::Dumper prints it). 2026-10-31: 0 of 1021 differ (816 test strings, 205 probes; the idioms-review copies too).
use strict; use warnings; use Data::Dumper;
my ($orig, $small, @files) = @ARGV;
unshift @INC, $orig, $small; require Proc::ShellSubset; require Proc::ShellSubset::Small;
$Data::Dumper::Indent = 0; $Data::Dumper::Terse = 1; $Data::Dumper::Sortkeys = 1; $Data::Dumper::Useqq = 1;
$ENV{HOME} //= '/root'; delete $ENV{CDPATH};
my %frozen = (empty => 1, fdmulti => 1);
my ($n, $diff, $acc, $drop) = (0, 0, 0, 0);
my @probe = (
  '', '   ', '# c', "\n#x\n",                                   # empty
  'a 10>f', 'a 10>&1', 'a 2>f', 'a 12<>f', 'a 0>f',             # fdmulti
  'a b^c', 'a ^', 'a c^', 'echo a^^b', 'a [a^b]', 'a $((1^2))', # nocaret
  'echo $PWD', 'echo "${PWD}"', 'PWD=/x a', 'echo ${PWD:-x}',  # nopwd
  'a b,c', 'a ,', 'a {b,c}', 'a {1..3}', 'a {b}', 'a {}', 'a x{}y', 'a {', 'a }', 'a [a,b]', 'a {,b}',  # brace
  'echo ${x:-y}', 'echo ${x-y}', 'echo ${#x}', 'echo ${x:+y}', 'echo "${x:-y z}"',  # param_ops
  'A=1', 'A=1 B=2', 'A=1 >f', 'HOME=x', 'HOME=x a', 'CDPATH=x a',  # assign
  'make PREFIX=~/x', 'make P=~', 'A=~ a', 'A=~:~ a', 'A=x:~/y a', 'a ~', 'a ~/x', 'a ~x', 'a x=~',  # tilde_args
  'if a; then b; fi', 'if a; then b; else c; fi', 'while a; do b; done', 'until a; do b; done',
  'for x in a b; do c; done', 'case $x in a) b;; esac', 'read -r x', 'read x y', 'read', 'IFS= read -r l',
  'while a; do break; done', 'while a; do continue 2; done', 'break', 'continue', 'a | break',
  'if', 'then', 'fi', 'a if', 'echo done', 'do', 'esac',           # compound, keywords
  '(exec a)', 'exec a; b', '{ exec a; }', '{ exec a; }; b', 'a && exec b', 'exec a &', '! exec a',
  'a `b` c', 'a $(b; c)', 'a "$(b)"', 'a `b \` c`', 'a $((1+2))', 'a $((x+$y))',
  "a\0b", 'a \'', 'a "', 'a \\', "a \x01", 'a $', 'a $x$', 'a ${x', 'a ${1}', 'a $1', 'a $@', 'a ${x%y}',
  'cd', 'cd x', 'cd -', 'cd a b', 'exit 3', 'exit 999', 'exit $x', ': a', 'A=1 :', 'A=1 exit',
  'a <<EOF', 'a <(b)', 'a >| f', 'a 2>&-', 'a >&x', 'a >f*', 'a >$x', 'a <&1', '((a))', '()', '{ }',
  'a | | b', 'a ;; b', 'a & & b', 'a &&', '! ! a', 'a |& b', 'a >f 2>&1 | b || c; d &',
  # round-3 probes: ~ (S6), {} and { (S5), $ forms (D6), first-word keyword (W16), blanks before a pipeline (D5)
  'a~', 'a ~b', 'a ~/x~y', 'a x~', 'a *~', 'a ""~', 'a \\~', 'A=~ a', 'A=~:~ a', 'A=:~ a', 'A=x:~/y a', 'A=x:"y"~ a', 'A=x\\:~ a',
  'A==~ a', 'A=~a:~b a', 'A=~- a', 'a ~"x"', 'a ~$x', 'a >~/x', 'a >x~', 'a ~x/y~z', 'A=', 'A= a', 'A=:',
  'a {}', 'a x{}y', 'a {}{}', 'a {}x{}', 'A={} a', 'a >{}', 'a {', 'a x{y', 'a {}{', 'a }', 'a {} {', '{a; }', '{}', '{} a',
  'a $x', 'a ${x}', 'a $?', 'a ${?}', 'a $!', 'a $0', 'a $#', 'a $*', 'a $-', 'a $$', 'a ${', 'a ${x', 'a ${}', 'a ${1}', 'a $[', 'a $\'x\'', 'a $"x"', 'a "$\'x\'"', 'a "$["', 'a $', 'a $ ', 'a $(',
  '"if" a', "'if' a", 'i\\f a', "if'' a", 'if$x a', 'if', 'a | if', 'a && then', 'x=1 if a', 'fi a', '! if', 'a | !',
  "a\n\n b", "a &&\n\n b", "a |\n b", "a ; \t b", " \n a", "a; # c\n b", "(\n a )", "{ \n a; }",
);
sub cmp1 { my ($id, $s) = @_;
  my $t = Proc::ShellSubset::parse($s, %frozen); my $u = Proc::ShellSubset::Small::parse($s); $n++;
  my ($a, $b) = (Dumper($t), Dumper($u));
  if ($a ne $b) { $diff++; (my $show = $s) =~ s/\n/\\n/g; print "DIFF $id  $show\n  A $a\n  B $b\n" } }
cmp1("probe:$_", $probe[$_]) for 0 .. $#probe;
for my $f (@files) {
  open my $fh, '<', $f or die "$f: $!"; my $data = 0;
  while (<$fh>) {
    if (!$data) { $data = 1 if /^__DATA__/; next }
    chomp; next unless /\S/ && !/^#/;
    my ($exp, $opt, $id, $s) = /^(ok|rej)\s+(\S+)\s+(\S+)\s+(.*)$/ or die "bad line $_";
    $s =~ s/\@N/\n/g; $s =~ s/\@T/\t/g; $s =~ s/\@R/\r/g;
    cmp1($id, $s);
    # how the test file's own expectation (with its own options) fares against the frozen parser
    my $ok = ref Proc::ShellSubset::Small::parse($s) eq 'ARRAY';
    if ($ok ne ($exp eq 'ok')) { $ok ? $acc++ : $drop++; (my $show = $s) =~ s/\n/\\n/g;
      printf "  %s %-8s %-28s %s\n", $ok ? 'ACC' : 'REJ', $opt, $id, $show } } }
print "$diff of $n differ between Proc::ShellSubset(frozen options) and Proc::ShellSubset::Small\n";
print "vs the test files' own expectations: $drop now rejected, $acc now accepted\n";
