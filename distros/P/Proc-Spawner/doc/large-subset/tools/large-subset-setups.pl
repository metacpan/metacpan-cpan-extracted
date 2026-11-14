#!/usr/bin/perl
# large-subset-setups.pl (X27, step 2; 2026-11-10): from large-subset-blocks.pl -d's record (DEPS.jsonl), the example
# setups for the undecided samples whose comparison may depend only on files, variables, standard input, arguments, the
# directory or HOME, each named exactly by the text (no expansion in the name; with -step3 also names with an expansion, below), for large-subset-runcompare.pl -setup.  A setup changes what the
# sample finds: the files of the run's directory, variables in its environment, its standard input.
#
# Usage: perl -Ilib large-subset-setups.pl [-all] [-full M] DEPS.jsonl PREFIX
#   -full M: a sample with at most M dependences (a file, a variable, HOME, the arguments, the input: those of the same
#   name move together) gets every combination of their states, 3^M setups (setups 1-3 the same as without; the user,
#   2026-11-10: "3^m tries", as far as they add at most 25 %: -full 2 adds 18 %, -full 3 would add 28 %)
#   -one: a sample with more dependences gets, after setups 1-3, each dependence alone in each of its states, the others
#   as in the base run: 3 + 3m setups (the user, 2026-11-10: "3+3*m where 3^m is too large")
#   writes PREFIX-1.jsonl, PREFIX-2.jsonl, PREFIX-3.jsonl (setup K of each sample, one line per sample) and
#   PREFIX-samples.tsv (each sample taken: id, blocks, its dependences, what each setup does).  Without -all only the
#   samples where one block (one command) carries the undecided codes; with -all also those where several do.
#
# The states tried, by what the shell does with the name (DEPS.jsonl's KIND; the run's base is the first column):
#   read  (< <> . test -e -f -r -s ...)  base: absent (or the fixture's file)  1 a file with two lines  2 an empty file
#                                        3 a directory          (for . the file holds "echo sourced"; if the fixture has
#                                        the file, 1 is: absent)
#   write (> >> >|)                      base: absent  1 a file with two lines  2 a directory  3 a read-only file
#   exec  (./prog)                       base: absent  1 an executable script that prints its arguments  2 the same,
#                                        not executable  3 a directory
#   glob  (a pattern word)               base: the fixture's matches  1 no file matches (the fixture's matches removed)
#                                        2 one new matching file  3 two new matching files
#   vars  (read before set)              base: unset  1 empty  2 "x1"  3 "two  words *"
#   input (read from the run's input)    base: /dev/null  1 two lines  2 a line without its newline  3 "a b\ c"
#   args  ($1, $@, $#, ... unset)        base: none  1 one empty argument  2 x1  3 "two  words", "*", "last" ($0: as without arguments, so that the messages keep their prefix)
#   directory (cd NAME)                  base: absent  1 a directory  2 a file  3 a directory with mode 000
#   HOME (~ alone, cd without operand)   base: the run's home directory  1 /nonexistent/home  2 empty  3 unset
#   (post-0.11: args, directory and tilde; the codes name, test-ops, eval and unquoted are taken where the same block
#   reads a variable or argument that the setups vary)
# -step3 STEP3.tsv (X27, step 3; post-0.11, 2026-11-12): instead, the samples of class control in large-subset-blocks.pl
#   -p's record (their values reach the environment only through what the run can set), for a run with -env cowroot:
#   absolute names are taken (a read or cd target as the system has it in the base run, absent in state 1 if the system
#   has it; glob patterns too), and a sample whose values come from programs (codes prog-output, prog-status, time,
#   random, or a program the record names) gets one more dependence, the programs' answer: base nothing and status 0,
#   1 "x1", 2 "two  words *" and "last" with status 1, 3 "-n a\b %s" (every stand-in of the run answers so; the programs
#   the record names that the runner runs for real are stand-ins in all its setups, setup 0 included); PREFIX-0.jsonl:
#   setup 0 of every sample, its stand-ins alone, for the base runs.
#   A name with an expansion (post-0.11, 2026-11-12: a file or directory whose name only an expansion gives at run time,
#   as cat < "$fname" or cd `dirname $f`; the user: choose the value and make the file of that name together): every
#   value in it is chosen (resolve() below: x1, or the run's own), and the file of the name it then gives gets the
#   states of its kind; where no dependence of its own sets those values, the setup sets them as chosen ("chosen: ..."),
#   and where such a dependence never holds the chosen value (HOME; $2 and later), the name gets 3 setups more, alone.
#   Left out: a name from a variable the text sets (for, read, an assignment), from arithmetic, from a program not on
#   PATH, ~user.
# A sample with several dependences gets state K of each in setup K.  Variables the run itself sets (HOME, PATH, ...)
# and the shells' own are not changed: such samples are left out, as are names with .. or an absolute path.
use strict; use warnings; use JSON::PP; use Getopt::Long; use Proc::ShellSubset::Large;
my ($ALL, $FULL, $ONE, $STEP3, $CLASS) = (0, 0, 0, '', 'control'); GetOptions('all' => \$ALL, 'full=i' => \$FULL, 'one' => \$ONE, 'step3=s' => \$STEP3, 'class=s' => \$CLASS) && @ARGV == 2
  or die "usage: $0 [-all] [-full M] [-one] [-step3 STEP3.tsv [-class control|affects-shell]] DEPS.jsonl PREFIX\n";
my $AFFECTS = $CLASS eq 'affects-shell';   # -class affects-shell: every code is under the run's control (-env cowroot, samearg0,
  # pidns, clock; the programs' answer); the variables the shells set themselves may be varied too (how each takes an
  # inherited value), but not the run's own (PATH, HOME, the locale, the recorders')
my %CTL;   # -step3: id => [the programs the record names]
if (length $STEP3) { open my $in, '<', $STEP3 or die "$STEP3: $!"; binmode $in, ':utf8';
  while (<$in>) { next if /^#/ || /^id\t/; chomp; my @f = split /\t/; next unless $f[1] eq $CLASS;
    $CTL{$f[0]} = [do { my %u; grep !$u{$_}++, map { /^[\w-]+:(.+)\z/ ? $1 =~ s{.*/}{}r : () } grep !/^ruling:/, split /,/, $f[3] }] } }
my %RUNCTL = map +($_ => 1), qw(prog-output prog-status time random path-root path-proc path-tmp path-random unquoted directory interactive);
  # -step3: under the run's control (unquoted without a name: a program's output split, which the answers vary;
  # directory without one: pwd, the same directory for the three; interactive: B2, no environment)
my @ANSWER = ([out => "x1\n", 0], [out => "two  words *\nlast\n", 1], [out => "-n a\\b %s\n", 0]);
my ($DEPS, $PRE) = @ARGV; my $J = JSON::PP->new->canonical->utf8;
# the fixture of large-subset-runcompare.pl (its %FIXTURE): every run starts with these
my @FIXTURE = ('a.txt', 'b.txt', 'file.txt', 'c.log', '.hidden', 'dir/', 'dir/x.txt', 'dir/sub/', 'dir/sub/y.sh', 'home/', 'home/.profile', 'empty');
my %RUNVAR = map +($_ => 1), qw(HOME PATH LANG LC_ALL USER LOGNAME TERM SHELL TMPDIR RECLOG REALDIR REALNAMES PWD OLDPWD
  PPID IFS OPTIND OPTARG LINENO PS1 PS2 PS4 STANDIN_STATUS STANDIN_OUTPUT);
my %RUNOWN = map +($_ => 1), qw(HOME PATH LANG LC_ALL TMPDIR RECLOG REALDIR REALNAMES STANDIN_STATUS STANDIN_OUTPUT RECBUILTIN
  RECPARENT LD_PRELOAD FAKETIME TZ);   # -class affects-shell: what the run itself needs
my %READOP = map +($_ => 1), qw(< <>); my %WRITEOP = map +($_ => 1), qw(> >> >|);
my $TWO = "line one\nline two\n";
my %STATE = (
  read  => [[file => $TWO], [file => ''], ['dir']],
  write => [[file => $TWO], ['dir'], [file => $TWO, 0444]],
  exec  => [[file => "#!/bin/sh\necho \"ran \$0:\" \"\$@\"\n", 0755], [file => "#!/bin/sh\necho \"ran \$0:\" \"\$@\"\n", 0644], ['dir']],
  vars  => ['', 'x1', 'two  words *'],
  input => [$TWO, 'no newline', "a b\\ c\n"],
  args  => [[''], ['x1'], ['two  words', '*', 'last']],   # $1 ...: the shells get them after the text (sh -c TEXT sh ARGS)
  home  => ['/nonexistent/home', '', undef],              # ~ and cd without operand: HOME missing, empty, unset
  dir   => [['dir'], [file => $TWO], ['dir', undef, 0]]);         # cd NAME: a directory, a file, a directory not searchable
my %VIA = map +($_ => 1), qw(name test-ops eval unquoted);   # codes that come with a variable or argument of the same block

sub bracket {   # a bracket expression at the start of $_[0] ("[...]"): (its regex, its length), or () if there is none
  my $p = shift; return () unless $p =~ /^\[/; my $i = 1; my $neg = ''; my $set = '';
  if ($i < length $p && substr($p, $i, 1) =~ /[!^]/) { $neg = '^'; $i++ }
  if ($i < length $p && substr($p, $i, 1) eq ']') { $set .= '\]'; $i++ }   # a first ] is a member
  while ($i < length $p) { my $r = substr $p, $i;
    if ($r =~ /^\]/) { return ("[$neg$set]", $i + 1) }
    if ($r =~ /^(\[:(\w+):\])/) { $set .= "[:$2:]"; $i += length $1; next }
    if ($r =~ /^\\(.)/s) { $set .= quotemeta $1; $i += 2; next }
    $r =~ /^(.)/s; my $c = $1; $set .= $c eq '-' ? '-' : quotemeta $c; $i++ }
  () }   # no closing ]: the [ is an ordinary character
sub pat_re { my $p = shift; my $r = '';   # a glob pattern (the text of a '*' part) as a Perl regex, for one path
  while (length $p) {
    if ($p =~ s/^\\(.)//s) { $r .= quotemeta $1 } elsif ($p =~ s/^\*//) { $r .= '[^/]*' } elsif ($p =~ s/^\?//) { $r .= '[^/]' }
    elsif (my ($b, $n) = bracket($p)) { $r .= $b; substr($p, 0, $n) = '' }
    else { $p =~ s/^(.)//s; $r .= quotemeta $1 } }
  $r }
sub pat_example { my ($p, $v) = @_; my $o = '';   # a name the pattern matches; $v: which (0, 1)
  while (length $p) {
    if ($p =~ s/^\\(.)//s) { $o .= $1 } elsif ($p =~ s/^\*//) { $o .= ('m', 'n')[$v] } elsif ($p =~ s/^\?//) { $o .= ('q', 'r')[$v] }
    elsif (my ($b, $n) = bracket($p)) { substr($p, 0, $n) = ''; my $re = eval { qr/^$b\z/ } or return undef;
      my @c = grep /$re/, ('a' .. 'z', 'A' .. 'Z', 0 .. 9, '_', '-'); return undef unless @c; $o .= $c[$v] // $c[0] }
    else { $p =~ s/^(.)//s; $o .= $1 } }
  $o }
sub glob_word {   # the word of a glob dep (its text, as large-subset-blocks.pl writes it) as [regex, example 1, example 2]
  my $text = shift; my $t = Proc::ShellSubset::Large::parse("x $text", empty => 1);
  my $w = ref $t eq 'ARRAY' && $t->[0][0][0]{argv} or return; return unless @$w == 2 && ref $w->[1]; $w = $w->[1];
  my ($re, @ex) = ('', '', ''); for my $p (@$w) {
    if (!ref $p) { $re .= quotemeta $p; $_ .= $p for @ex } elsif ($p->[0] eq "'") { $re .= quotemeta $p->[1]; $_ .= $p->[1] for @ex }
    elsif ($p->[0] eq '*') { $re .= pat_re($p->[1]); for my $v (0, 1) { my $e = pat_example($p->[1], $v); return unless defined $e; $ex[$v] .= $e } }
    else { return } }
  my $qr = eval { qr/^$re\z/ } or return;   # (a pattern Perl cannot take: left out)
  return if grep { m{(?:^|/)\.\.?(?:/|\z)} || m{^/} && !length $STEP3 || m{^/(?:dev|proc|sys)(?:/|\z)} || !length || !/$qr/ } @ex;   # (a dot name: a pattern does not match it)
  [$qr, @ex] }

sub system_path {   # -step3: an absolute name whose setups would take from the run what it needs to run: an ancestor of
  my $f = shift =~ s{/+\z}{}r; return 0 unless $f =~ m{^/};   #   the programs, the loader, the user database, the
  for my $need (qw(/usr/bin/dash /usr/bin/bash /usr/bin/perl /usr/bin/mount /usr/bin/prlimit /usr/bin/setpriv /usr/bin/timeout
    /lib64/ld-linux-x86-64.so.2 /usr/lib /etc/passwd /etc/group /etc/nsswitch.conf /etc/ld.so.cache /tmp /var/tmp /runcompare)) {   # fresh /tmp
    return 1 if $need eq $f || index($need, "$f/") == 0 }
  -e $f && $f =~ m{^/(?:usr/)?(?:bin|sbin|lib\w*)/} }   # an existing program or library: kept as it is
my %QUIETP = map +($_ => 1), qw(echo printf test [ true false pwd kill);   # large-subset-runcompare.pl's %QUIET: never stand-ins
sub litword { my $w = shift; !ref $w ? $w : join '', map { !ref $_ ? $_ : $_->[0] eq "'" ? $_->[1] : return undef } @$w }   # a literal word's text
sub word1 { my $t = Proc::ShellSubset::Large::parse("x $_[0]", empty => 1); my $a = ref $t eq 'ARRAY' && $t->[0][0][0]{argv}; $a && @$a == 2 ? $a->[1] : [['?']] }   # a word as the parser reads it
sub squote { "'" . ($_[0] =~ s/'/'\\''/gr) . "'" }
sub resolve {   # -step3 (post-0.11): a name with an expansion (a file or directory whose name only an expansion gives at run
  # time) as the name the setup chooses, so that it can make the file of that name: every value in it is "x1" (a
  # variable the run reads before it sets it: x1, as its state 2; $1, $2, $@, $*: the arguments x1 ...; a program's
  # output: x1, as the programs' answer 1, the program a stand-in then), or the run's own (~ and $HOME: the run's home,
  # home/ in its directory; $PWD and $(pwd): the run's directory; $$: 2 with -env pidns; $0: sh with -env samearg0).
  # Returns ({ text: the name, globs as one name each matches; word: the name as a word, globs kept; env, args,
  # standin: what the run needs for it, unless a dependence of its own sets it; src: [the keys of those dependences,
  # with 1 where their states hold the same value] }), or (undef, why it cannot).
  my ($w, $read) = @_;
  my $t = Proc::ShellSubset::Large::parse("x $w", empty => 1); my $a = ref $t eq 'ARRAY' && $t->[0][0][0]{argv};
  return (undef, 'a name with an expansion (not one word)') unless $a && @$a == 2;
  my @parts = ref $a->[1] ? @{$a->[1]} : ($a->[1]); my (@out, %env, $args, @stand, %src);   # @out: [literal] or [glob, PATTERN]
  my $param = sub { my $n = shift;   # a parameter's value
    if ($n =~ /^[1-9]\z/) { $args = [('x1') x $n] if !$args || @$args < $n; $src{args} //= $n == 1 ? 1 : 0; return 'x1' }
    if ($n eq '@' || $n eq '*') { $args //= ['x1']; $src{args} //= 1; return 'x1' }
    if ($n eq '$') { return $AFFECTS ? '2' : (undef, 'a name with $$ (without a PID namespace)') }
    if ($n eq '0') { return $AFFECTS ? 'sh' : (undef, 'a name with $0 (a different one in each shell)') }
    if ($n eq 'HOME') { $src{HOME} = 0; return 'home' } if ($n eq 'PWD') { return '.' }
    if ($read->{$n}) { $env{$n} = 'x1'; $src{"var:$n"} = 1; return 'x1' }
    (undef, $n =~ /^\w+\z/ ? 'a name from a variable the text sets' : "a name with \$$n") };
  for my $p (@parts) {
    if (!ref $p) { push @out, [$p]; next } my $k = $p->[0] =~ s/^"//r;
    if ($k eq "'") { push @out, [$p->[1]] }
    elsif ($k eq '*') { push @out, ['', $p->[1]] }
    elsif ($k eq '~') { length $p->[1] and return (undef, '~user (the user database)'); $src{HOME} = 0; push @out, ['home'] }
    elsif ($k eq '$') { my ($v, $why) = $param->($p->[1]); defined $v or return (undef, $why); push @out, [$v] }
    elsif ($k eq '${') { my ($n, $op, $ow) = @$p[1 .. 3]; my ($v, $why) = $param->($n); defined $v or return (undef, $why);
      my $lit = !defined $ow ? '' : !ref $ow ? $ow : join '', map { !ref $_ ? $_ : $_->[0] eq "'" ? $_->[1] : return (undef, 'a name with an expansion in ${...}') } @$ow;
      if (!defined $op) { } elsif ($op =~ /^:?[-=?]\z/) { } elsif ($op =~ /^:?\+\z/) { $v = $lit }   # (x1 is set and not empty)
      elsif ($op =~ /^(%%?|##?)\z/) { my $re = qr/^(?:${\ pat_re($lit)})\z/s; my $L = length $v;   # the shortest or longest suffix or prefix
        my @i = $op eq '%' ? reverse(0 .. $L) : $op eq '%%' ? (0 .. $L) : $op eq '#' ? (0 .. $L) : reverse(0 .. $L);
        for my $i (@i) { if ($op =~ /%/ ? substr($v, $i) =~ $re : substr($v, 0, $i) =~ $re) { $v = $op =~ /%/ ? substr($v, 0, $i) : substr($v, $i); last } } }
      else { return (undef, "a name with \${$n$op...}") }
      push @out, [$v] }
    elsif ($k eq '$(') { my $l = $p->[1]; my $pl = @$l == 1 && @{$l->[0]} == 1 && $l->[0][0];
      ref $pl eq 'ARRAY' && ref $pl->[-1] eq 'HASH' && $pl->[-1]{argv} or return (undef, 'a name from a list of commands');
      my $c = $pl->[-1]{argv}; my $prog = $c->[0];
      ref $prog || $prog =~ m{/} and return (undef, 'a name from a program not on PATH');
      if ($prog eq 'pwd') { push @out, ['.']; next }
      if ($prog eq 'echo' && @$pl == 1 && !grep !defined, map litword($_), @$c) { my @w = map litword($_), @$c[1 .. $#$c]; shift @w if @w && $w[0] eq '-n';
        grep /\\/, @w and return (undef, "a name from echo with a backslash"); push @out, [join ' ', @w]; next }   # (echo with literal words: what it prints, less the newline)
      $QUIETP{$prog} and return (undef, "a name from $prog\'s output");
      @stand = do { my %u; grep !$u{$_}++, @stand, $prog }; $env{STANDIN_OUTPUT} = "x1\n"; $env{STANDIN_STATUS} = 0; $src{answers} = 1;
      push @out, ['x1'] }
    else { return (undef, $k eq '$((' ? 'a name from arithmetic' : "a name with $k") } }
  # the run's directory: $PWD/x is x
  if (@out > 1 && !defined $out[0][1] && $out[0][0] eq '.') { shift @out; while (@out && !length $out[0][0] && !defined $out[0][1]) { shift @out }
    @out && $out[0][0] =~ s{^/+}{} || @out && defined $out[0][1] && $out[0][1] =~ s{^/+}{} or return (undef, 'cd to an absolute path, . or ..') }
  my ($text, $word) = ('', '');
  for (@out) { if (defined $_->[1]) { my $e = pat_example($_->[1], 0); defined $e or return (undef, 'a pattern without a usable example');
      $text .= $_->[0] . $e; $word .= squote($_->[0]) . $_->[1] } else { $text .= $_->[0]; $word .= squote($_->[0]) } }
  length $text or return (undef, 'an empty name');
  ({ text => $text, word => $word, env => \%env, args => $args, standin => \@stand, src => \%src }) }
my (@out, %took); my %why;
open my $in, '<', $DEPS or die "$DEPS: $!";
SAMPLE: while (<$in>) { my $d = decode_json $_;
  next if length $STEP3 && !$CTL{$d->{id}};
  my @codes = @{$d->{codes}}; next if !$AFFECTS && grep !/^(?:files|vars|input|args|directory|tilde)\z/ && !$VIA{$_} && !(length $STEP3 && $RUNCTL{$_}), @codes;
  my %bv; $bv{$_->[4]} = 1 for grep { $_->[0] eq 'vars' || $_->[0] eq 'args' } @{$d->{deps}};   # (blocks with one)
  next if !$AFFECTS && grep { !($VIA{$_->[0]} && $bv{$_->[1]}) && !(length $STEP3 && $RUNCTL{$_->[0]}) } @{$d->{bare} // []};   # a code without a name, unless it comes with one
  next if !$d->{bare} && @{$d->{rest}} && !length $STEP3;
  next if $d->{blocks} > 1 && !$ALL;
  my @each;   # [KEY, [its states 1, 2, 3]] per dependence; dependences with the same KEY (a file, a variable, HOME, the
              # arguments, the input) move together
  my (@setup, $key, $via, $shown);   # $via: resolve()'s answer for a name with an expansion; $shown: that name
  my %read = map +($_->[2] => 1), grep $_->[0] eq 'vars', @{$d->{deps}};   # the variables the run reads before it sets them
  for my $p (@{$d->{deps}}) { my ($code, $kind, $name, $lit) = @$p;
    @setup = map +{ files => {}, env => {}, does => [] }, 1 .. 3; undef $key; undef $via; undef $shown;
    if (length $STEP3 && $code ne 'tilde' && (!$lit || $code eq 'files' && $kind ne 'glob' && !defined litword(word1($kind eq 'test' ? ($name =~ /^\S+ (.*)\z/s)[0] : $name)))) {
      # -step3: a name with an expansion as the name the setup chooses (also ~ or a pattern in a name the record calls literal)
      my $w = $kind eq 'test' ? ($name =~ /^\S+ (.*)\z/s)[0] : $name; ($via, my $no) = resolve($w, \%read);
      $via or do { $why{$no}++; next SAMPLE }; $shown = $kind eq 'test' ? $w : $name;
      $name = $kind eq 'glob' ? $via->{word} : $code eq 'directory' ? $via->{text} : ($kind eq 'test' ? ($name =~ /^(\S+)/)[0] . ' ' : '') . squote($via->{text}); $lit = 1 }
    $lit or $code eq 'tilde' or do { $why{'a name with an expansion'}++; next SAMPLE };
    if ($code eq 'vars') { ($AFFECTS ? $RUNOWN{$name} : $RUNVAR{$name}) and do { $why{"the run's own variable"}++; next SAMPLE }; $key = "var:$name";
      for my $k (0 .. 2) { $setup[$k]{env}{$name} //= $STATE{vars}[$k]; push @{$setup[$k]{does}}, "\$$name=" . $J->encode([$STATE{vars}[$k]]) } next }
    if ($code eq 'args') { $key = 'args'; for my $k (0 .. 2) { $setup[$k]{args} //= $STATE{args}[$k]; push @{$setup[$k]{does}}, "\$$name of " . $J->encode($STATE{args}[$k]) } next }
    if ($code eq 'tilde' || $code eq 'directory' && $name eq '') {   # HOME
      $code eq 'tilde' && !$lit and do { $why{'~user (the user database)'}++; next SAMPLE }; $key = 'HOME';
      for my $k (0 .. 2) { exists $setup[$k]{env}{HOME} or $setup[$k]{env}{HOME} = $STATE{home}[$k];
        push @{$setup[$k]{does}}, ($code eq 'tilde' ? $name : 'cd') . ': HOME ' . (defined $STATE{home}[$k] ? $J->encode([$STATE{home}[$k]]) : 'unset') } next }
    if ($code eq 'directory') { $lit or do { $why{'a name with an expansion'}++; next SAMPLE };
      $name eq '-' and do { $why{'cd - (OLDPWD)'}++; next SAMPLE };
      my $f = $name; $f =~ s{^(?:\./)+}{}; $f =~ s{/+\z}{};
      (!length $f || $f eq '.' || $f =~ m{(?:^|/)\.\.(?:/|\z)} || $f =~ m{^/} && !length $STEP3) and do { $why{'cd to an absolute path, . or ..'}++; next SAMPLE };
      $f = $name =~ s{/+\z}{}r if $name =~ m{^/};
      system_path($f) || $f =~ m{^/(?:dev|proc|sys)(?:/|\z)} and do { $why{'a system path the run itself needs'}++; next SAMPLE };
      $key = "file:$f";
      for my $k (0 .. 2) { $setup[$k]{files}{$f} //= $STATE{dir}[$k]; push @{$setup[$k]{does}}, "cd " . (defined $shown ? "$shown = " : '') . "$f: " . join(' ', map { !defined ? () : /^\d+$/ ? sprintf('%o', $_) : $J->encode([$_]) =~ s/^\[|\]$//gr } @{$STATE{dir}[$k]}) } next }
    if ($code eq 'input') { $key = 'input'; for my $k (0 .. 2) { $setup[$k]{stdin} //= $STATE{input}[$k]; push @{$setup[$k]{does}}, 'stdin ' . $J->encode([$STATE{input}[$k]]) } next }
    if ($kind eq 'glob') { my $g = glob_word($name)
        or do { $why{$name =~ m{^/} ? 'an absolute pattern (outside the run\'s directory)' : 'a pattern without a usable example'}++; next SAMPLE };
      my ($re, @ex) = @$g; my @fm = $name =~ m{^/} ? do { my @m = grep $_ =~ $re, map { -d $_ ? "$_/" : $_ } glob($name =~ s/\\//gr); @m > 100 ? () : @m }   # (absolute: the system's)
        : grep { $_ =~ $re || s{/\z}{}r =~ $re } @FIXTURE; $key = "glob:$name";   # (a directory matches with or without /)
      grep({ system_path($_) } @fm, @ex) and do { $why{'a system path the run itself needs'}++; next SAMPLE };
      for my $f (@fm) { $setup[0]{files}{$f =~ s{/\z}{}r} //= ['absent'] } push @{$setup[0]{does}}, "glob " . ($shown // $name) . ": none (" . (@fm ? "removed @fm" : 'as the fixture') . ')';
      my $make = sub { my $e = shift; $e =~ m{/\z} ? ($e =~ s{/+\z}{}r, ['dir']) : ($e, [file => $TWO]) };   # a pattern ending in /: directories
      { my ($f, $st) = $make->($ex[0]); $setup[1]{files}{$f} //= $st } push @{$setup[1]{does}}, "glob " . ($shown // $name) . ": + $ex[0]";
      for (@ex) { my ($f, $st) = $make->($_); $setup[2]{files}{$f} //= $st } push @{$setup[2]{does}}, "glob " . ($shown // $name) . ": + $ex[0] $ex[1]"; next }
    my $f = $kind eq 'test' ? ($name =~ /^\S+ (.*)\z/s)[0] : $name; my $op = $kind eq 'test' ? ($name =~ /^(\S+)/)[0] : $kind;
    # the operand as a word: no quoting left in it (literal), but written by wtext: take it as the parser reads it
    my $t = Proc::ShellSubset::Large::parse("x $f", empty => 1); my $w = ref $t eq 'ARRAY' && $t->[0][0][0]{argv};
    my @parts = $w && @$w == 2 ? (ref $w->[1] ? @{$w->[1]} : $w->[1]) : (undef);   # strings and quoted strings only
    (!grep { !defined || (ref && $$_[0] ne "'") } @parts) or do { $why{'a name with an expansion'}++; next SAMPLE };
    $f = join '', map ref ? $$_[1] : $_, @parts;
    (!length $f || $f =~ m{(?:^|/)\.\.(?:/|\z)} || $f =~ m{^/} && !length $STEP3) and do { $why{'a name with .. or an absolute path'}++; next SAMPLE };
    $f =~ m{^/(?:dev|proc|sys)(?:/|\z)} || $f eq '/' and do { $why{'a name in /dev, /proc or /sys'}++; next SAMPLE };
    system_path($f) and do { $why{'a system path the run itself needs'}++; next SAMPLE };
    $f =~ s{^(?:\./)+}{}; $f =~ s{/+\z}{}; length $f or do { $why{'the run\'s directory itself'}++; next SAMPLE }; $key = "file:$f";
    my $class = $kind eq 'exec' ? 'exec' : $WRITEOP{$kind} ? 'write' : 'read';
    my @st = @{$STATE{$class}};
    if ($kind eq 'dot') { @st = ([file => "echo sourced\n"], [file => ''], ['dir']) }
    if ($class eq 'read' && (grep($_ eq $f || $_ eq "$f/", @FIXTURE) || $f =~ m{^/} && -e $f)) { $st[0] = ['absent'] }   # the base has it: try without
    for my $k (0 .. 2) { $setup[$k]{files}{$f} //= $st[$k]; push @{$setup[$k]{does}}, "$op " . (defined $shown ? "$shown = " : '') . "$f: " . join(' ', map { /^\d+$/ ? sprintf('%o', $_) : $J->encode([$_]) =~ s/^\[|\]$//gr } @{$st[$k]}) } }
  continue { push @each, [$key, [@setup], $via] if defined $key }
  if (length $STEP3 && (grep(/^(?:prog-output|prog-status|time|random)\z/ || $AFFECTS && /^(?:name|eval|unquoted|test-ops|pid)\z/, @codes) || @{$CTL{$d->{id}}})) {   # the programs' answer
    push @each, ['answers', [map +{ files => {}, env => { STANDIN_OUTPUT => $ANSWER[$_][1], STANDIN_STATUS => $ANSWER[$_][2] },
      does => ["programs answer " . $J->encode([$ANSWER[$_][1]]) . ", status $ANSWER[$_][2]"] }, 0 .. 2]] }
  my @keys = do { my %s; grep !$s{$_}++, map $_->[0], @each };
  my @vec = map [($_) x @keys], 0 .. 2;   # setups 1-3: every dependence in its state 1, 2, 3 (as before -full)
  if (@keys <= $FULL) {   # -full: then every other combination, 3^m in all
    my @all = ([]); @all = map { my $v = $_; map [@$v, $_], 0 .. 2 } @all for @keys;
    push @vec, grep { my %u = map +($_ => 1), @$_; keys %u > 1 } @all }
  elsif ($ONE) {   # -one: then each dependence alone in each state, the others as in the base run (-1): 3 + 3m in all
    for my $i (0 .. $#keys) { push @vec, map { my $s = $_; [map { $_ == $i ? $s : -1 } 0 .. $#keys] } 0 .. 2 } }
  { my %ki = map +($keys[$_] => $_), 0 .. $#keys;   # -step3: a name with an expansion whose value a dependence of its own varies through
    for my $i (0 .. $#keys) {   #   states without the chosen one (HOME, $2): that name alone too, its value as chosen
      next unless grep { my $v = $_; grep { exists $ki{$_} && !$v->{src}{$_} } keys %{$v->{src}} } grep defined, map $_->[2], grep $_->[0] eq $keys[$i], @each;
      my %u = map +("@$_" => 1), @vec; push @vec, grep !$u{"@$_"}++, map { my $s = $_; [map { $_ == $i ? $s : -1 } 0 .. $#keys] } 0 .. 2 } }
  @setup = map { my $v = $_; my %at; @at{@keys} = @$v; my $s = { files => {}, env => {}, does => [] }; my @via;
    for (@each) { my ($key, $st, $via) = @$_; next if $at{$key} < 0; my $x = $st->[$at{$key}]; push @via, $via if $via;
      $s->{files}{$_} //= $x->{files}{$_} for keys %{$x->{files}}; exists $s->{env}{$_} or $s->{env}{$_} = $x->{env}{$_} for keys %{$x->{env}};
      $s->{$_} //= $x->{$_} for grep defined $x->{$_}, qw(args stdin); push @{$s->{does}}, @{$x->{does}} }
    my @stand = length $STEP3 ? @{$CTL{$d->{id}}} : ();
    for my $w (@via) {   # the values chosen for the names with an expansion, where no dependence of their own sets them
      for my $n (sort grep !exists $s->{env}{$_}, keys %{$w->{env}}) { $s->{env}{$n} = $w->{env}{$n};
        push @{$s->{does}}, $n eq 'STANDIN_OUTPUT' ? 'chosen: programs answer ["x1\\n"], status 0' : $n eq 'STANDIN_STATUS' ? () : "chosen: \$$n=" . $J->encode([$w->{env}{$n}]) }
      if ($w->{args} && !$s->{args}) { $s->{args} = $w->{args}; push @{$s->{does}}, 'chosen: arguments ' . $J->encode($w->{args}) }
      push @stand, @{$w->{standin}} }
    @stand = do { my %u; grep !$u{$_}++, @stand }; $s->{standin} = \@stand if @stand;
    $s } @vec;
  @keys or @setup = ();   # (-step3: nothing to vary, the run's control alone: the base runs only)
  $took{$d->{id}} = 1;
  push @out, [$d, \@setup] }
my $max = 0; $max = @{$_->[1]} > $max ? @{$_->[1]} : $max for @out;
if (length $STEP3) { open my $o, '>', "$PRE-0.jsonl" or die;   # setup 0: the stand-ins alone, for the base runs
  print $o $J->encode({ id => $_->[0]{id}, k => 0, files => {}, env => {}, does => ['base'], @{$CTL{$_->[0]{id}}} ? (standin => $CTL{$_->[0]{id}}) : () }), "\n" for @out; close $o }
for my $k (1 .. $max) { open my $o, '>', "$PRE-$k.jsonl" or die; print $o $J->encode({ id => $_->[0]{id}, k => $k, %{$_->[1][$k - 1]} }), "\n" for grep @{$_->[1]} >= $k, @out; close $o }
open my $o, '>', "$PRE-samples.tsv" or die; binmode $o, ':utf8';
print $o "# id\tblocks\tdependences\tsetup 1\tsetup 2\t... (as many as the sample has)\n";
for (@out) { my ($d, $s) = @$_; print $o join("\t", $d->{id}, $d->{blocks}, join(' ', map "$_->[0]:$_->[1]:$_->[2]", @{$d->{deps}}), map join('; ', @{$_->{does}}), @$s), "\n" }
printf STDERR "%d samples with setups (%s); left out: %s\n", scalar @out, $ALL ? 'one block or more' : 'one block',
  join(', ', map "$why{$_} $_", sort keys %why) || 'none';
