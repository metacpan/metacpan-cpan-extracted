#!/usr/bin/perl
# large-subset-blocks.pl (post-0.08, 2026-11-07; known issue X27): cut every sample the large parser accepts into its
# atomic blocks, and sort the blocks and the samples into three levels by whether the result of comparing dash,
# bash --posix and ours on them can change with the environment:
#   strict     no, from the text alone, assuming only what any run needs: the shell started as in the run
#              (descriptors 0-2 open, no signal from outside, enough memory, processes and disk), and the programs the
#              subset runs in place of builtins (echo, printf, test, [, true, false; rule "the program beats", X21)
#   held       no, under assumptions known to hold in every environment tested (Linux, Linux without /proc,
#              Windows): devnull, heredoc
#   almost     no, under the assumptions named by its reasons (below), each mild but not nothing; since step 3
#              (post-0.11, 2026-11-12, the user's (a)) also a sample whose every value from the environment only
#              passes through the shell (assumptions passthrough, and splitglob where a value is split and globbed
#              into a program's words): large-subset-environment.md, section 12
#   undecided  not shown either way: a reason names what the result may depend on
# A sample's level is the lowest of its parts'.  Only forms argued safe pass; everything else is undecided, so a
# pass is meant to be definite (under the stated assumptions), a non-pass is not a verdict.  Programs are taken as
# real and opaque: nothing here knows what a program does, only what the shell does with it.
#
# Usage: perl -Ilib large-subset-blocks.pl [-batch] [-o BLOCKS.jsonl] [-s SAMPLES.tsv] [-e PROVENANCE.tsv] [-d DEPS.jsonl] [-p STEP3.tsv] samples.jsonl samples.tsv
#   -batch  first parse all the accepted samples one by one and joined into one text (one line apart), and compare
#           each sample's part of the joined tree with its own tree; report what keeps them apart
#   -o      one line per distinct block (with its place): its text (rebuilt from the tree), level, reasons, the samples
#   -s      one line per sample: id, level, reasons, the text
#   -e      every sample: its snippet ID and a short code (large-subset-provenance.tsv; the code is explained in the
#           file's header and in doc/large-subset/large-subset-environment.md)
#   -d      (X27, step 2, 2026-11-10) every undecided sample: exactly what its undecided codes come from, as far as the
#           text says it, and in which blocks: {id, text, codes, blocks (how many blocks carry an undecided code),
#           deps: [[CODE, KIND, NAME, LITERAL, BLOCK], ...], rest: [the undecided codes no dep names], bare: [[CODE,
#           BLOCK], ...] (the same, by block)}.  KIND: for files glob (NAME the pattern word as text), < > >> <> >| (a
#           redirection), test (NAME "OP OPERAND"), dot (the file . reads), exec (a relative program name); for vars
#           read (NAME the variable); for input stdin; for args arg (NAME 1, @, # ...); for directory cd (NAME its
#           operand, '' for none: HOME); for tilde tilde (NAME the word; LITERAL: ~ alone, not ~user).  LITERAL: 1 if
#           NAME is all the text says (no expansion in it).  BLOCK: the block's number in the sample, from 1.  -d lists
#           the samples undecided by the codes alone, before step 3 (so step 2's setups stay as they were).
#   -p      (X27, step 3) every sample undecided by the codes alone: id, class, what keeps it undecided, what the run
#           controls, its undecided codes, the text.  Class: pass (every value from the environment only passes
#           through: into a program's words, an assignment, a case word, a here-document, a program's output going
#           on, a status choosing between branches that are all alike); split (the same, some split and globbed into
#           a program's words); control (it depends on the environment only through what the run can set: a
#           redirection's or cd's target, a ./program, a value into echo, printf or test, a dot pattern, a program's
#           answer, /tmp, /dev/urandom); affects-shell (a value from the environment affects what the shell itself does: a
#           builtin other than echo, printf, test takes it, arithmetic, ${x:?}, set -u, set -e, the shells' own variables;
#           process IDs and the clock: $$, $SECONDS, kill and wait with operands).  pass and
#           split are almost strict (assumptions passthrough, splitglob); control and not stay undecided.
#
# A block is a simple command (with its settings and redirections), the word list of a 'for', the word and the
# patterns of a 'case', the redirections of a compound command; a command inside $( ) is a block of its own.
#
# The codes, what each assumes or depends on, and whether it can be put under our control:
# doc/large-subset/large-subset-environment.md, section 3.  In short:
#   held:      devnull heredoc
#   almost:    program pipeline devfd locale echo path-system path-var path-home path-dev path-mnt path-absent
#              passthrough splitglob (step 3)
#   undecided: files directory vars unquoted args start status prog-output prog-status race pid time random input
#              listing lookup limits fd tilde name test-ops eval interactive path-tmp path-random path-proc path-root
# Compositions: $? takes the status of what ran just before (in a loop: of any command of the loop; at the start of a
# function's body or a trap action it is unknown: status); after set -e (until set +e) every status decides but the
# text's last command's.  A function's name is a call of it only after the walk has passed its definition.
use strict; use warnings; use JSON::PP; use Getopt::Long; use Proc::ShellSubset::Large; use Time::HiRes 'time';
my ($BATCH, $OUTB, $OUTS, $OUTE, $OUTD, $OUTP, $AIF); GetOptions('batch' => \$BATCH, 'o=s' => \$OUTB, 's=s' => \$OUTS, 'e=s' => \$OUTE, 'd=s' => \$OUTD, 'p=s' => \$OUTP, 'ai=s' => \$AIF) && @ARGV == 2
  or die "usage: $0 [-batch] [-o BLOCKS.jsonl] [-s SAMPLES.tsv] [-e PROVENANCE.tsv] [-d DEPS.jsonl] samples.jsonl samples.tsv\n";
$ENV{HOME} //= '/root'; delete $ENV{CDPATH};
my $J = JSON::PP->new->canonical->utf8;
my ($SJ, $ST) = @ARGV;
my %acc; { open my $in, '<', $ST or die "$ST: $!"; my $h = <$in>; chomp $h; my @h = split /\t/, $h; my %c; @c{@h} = 0 .. $#h;
  while (<$in>) { chomp; my @f = split /\t/, $_, -1; $acc{$f[$c{id}]} = 1 if $f[$c{large}] } }
my @S; { open my $in, '<', $SJ or die "$SJ: $!"; my %seen; while (<$in>) { my $s = decode_json $_; push @S, $s if $acc{$s->{id}} && !$seen{$s->{id}}++ } }
if ($BATCH) { batch() }

my @HELD = qw(devnull heredoc);   # assumptions known to hold in every environment tested (Linux, Linux without /proc, Windows)
my @ALMOST = qw(program pipeline devfd locale echo path-system path-var path-home path-dev path-mnt path-absent passthrough splitglob);
my @UNDEC = qw(files directory vars unquoted args start status prog-output prog-status race pid time random input listing
  lookup limits fd tilde name test-ops eval interactive path-tmp path-random path-proc path-root);
my %LEVEL = ((map +($_ => 1), @HELD), (map +($_ => 2), @ALMOST), (map +($_ => 3), @UNDEC));
sub pclass { local $_ = shift;   # an absolute path, by the area it is in (see the header)
  return 'path-root' if m{^/+\z}; return 'path-tmp' if m{^/(?:tmp|var/tmp|dev/shm)(?:/|\z)};
  return '' if m{^/dev/null\z};   # given to a program: the program's business, the same under every shell
  return 'devfd' if m{^/dev/(?:std(?:in|out|err)|fd/\d+)\z}; return 'path-random' if m{^/dev/u?random\z};
  return 'path-dev' if m{^/dev(?:/|\z)}; return 'path-proc' if m{^/(?:proc|sys|run)(?:/|\z)};
  return 'path-system' if m{^/(?:etc|usr|bin|sbin|lib|lib32|lib64|libx32|opt|boot)(?:/|\z)};
  return 'path-var' if m{^/var(?:/|\z)}; return 'path-home' if m{^/(?:home|root)(?:/|\z)};
  return 'path-mnt' if m{^/(?:mnt|media|srv)(?:/|\z)}; 'path-absent' }
my %SHELLVAR = map +($_ => 1), qw(IFS OPTIND LINENO PS1 PS2 PS4);    # the shells set them to fixed values
my %FILEOPS = map +($_ => 1), qw(-e -f -d -r -w -x -s -L -h -p -S -b -c -g -u -k -O -G -N -nt -ot -ef -a);
my %INTER = map +($_ => 1), qw(history fc bind help compopt logout);
my %OWN = map +($_ => 1), qw(: true false echo printf test [ read getopts set shift unset alias unalias return break
  continue exit export readonly local umask ulimit eval trap . source cd pwd wait jobs fg bg disown kill times hash type
  command exec time), keys %INTER;   # builtins (and the subset's own programs): what the shell does is known

# Per sample.
our ($CUR, $LAST, @LOOPS, $FINAL); my ($ERREXIT, $ANYERR); my (%FDEF, %FNOW, @BLKS, $POS, %VSET, %VLIT, $ARGSET, $ARGSLIT, $FARGSOK, %OPENFD, @DEFER, %FOPQ);
our $PT = 0; our ($NOUNSET, %VALSINK, @SINKS);   # @SINKS: [BLOCK, MODE] where a value from the environment lands
sub why { my ($r, $b) = @_; $b //= $CUR; return unless $b; $b->{r}{$r} = 1; if ($PT) { $b->{pt}{$r}{$PT} = 1 } else { $b->{np}{$r} = 1 } }
my %OWNVAR = map +($_ => 1), qw(BASH BASHOPTS BASHPID BASH_ALIASES BASH_ARGC BASH_ARGV BASH_ARGV0 BASH_CMDS BASH_COMMAND BASH_EXECUTION_STRING
  BASH_LINENO BASH_LOADABLES_PATH BASH_REMATCH BASH_SOURCE BASH_SUBSHELL BASH_VERSINFO BASH_VERSION COLUMNS COMP_CWORD COMP_LINE
  COMP_POINT COMP_TYPE COMP_KEY COMP_WORDBREAKS COMP_WORDS DIRSTACK EPOCHREALTIME EPOCHSECONDS EUID FUNCNAME GROUPS HISTCMD HISTFILE
  HISTSIZE HOSTNAME HOSTTYPE LINES MACHTYPE MAILCHECK OLDPWD OPTERR OSTYPE PATH PIPESTATUS POSIXLY_CORRECT PWD RANDOM SHELL SHELLOPTS
  SHLVL SRANDOM TERM UID _);   # set by dash, bash or ours themselves (env -i ... set), or bash's own
our @DEPS;   # -d: [CODE, KIND, NAME, LITERAL, BLOCK] (see the header)
sub dep { my ($r, $kind, $name, $lit, $b) = @_; $b //= $CUR; why($r, $b); push @DEPS, [$r, $kind, $name, $lit ? 1 : 0, $b] if $b }
sub wlit { my $w = shift; !ref $w || !grep { ref && $$_[0] !~ /^(?:\*|')\z/ } @$w }   # no expansion in it (patterns allowed)
sub newblock { my ($text, $cx) = @_; my $b = { text => $text, cx => { %$cx }, r => {}, pos => ++$POS, errexit => $ERREXIT }; push @BLKS, $b; $b }
sub consume { my $b = shift; local $PT = 1; why('prog-status', $b) if $b->{sopaque} }   # this block's status decides something
sub safe_lit { my $w = shift; defined $w && !ref $w && $w !~ /[*?\[]/ }   # a literal word with no pattern characters
sub vassign { my ($n, $cx, $safe) = @_; return if ref $n || !defined $n;
  my $p = $cx->{infunc} || $cx->{late} ? -1 : $POS; $VSET{$n} = $p if !defined $VSET{$n} || $p < $VSET{$n};
  $VLIT{$n} = ($VLIT{$n} // 1) && $safe ? 1 : 0 }

# Words.  $mode: argv (split, then pathname expansion), assign (neither), redir, case (the word of a case), pattern
# (a case pattern, the word of ${x#...}), heredoc (as in double quotes).
sub word { my ($w, $cx, $mode) = @_; return unless defined $w;
  if (!ref $w) { why('locale') if $mode eq 'pattern' && $w =~ /[^\x00-\x7f]/; return }
  for my $p (@$w) { next unless ref $p; my ($k, @a) = @$p; my $q = $k =~ s/^"// || $mode ne 'argv';
    if ($k eq '*') { if ($mode eq 'argv') { my $wt = wtext($w); local $PT = $wt =~ /\[\^/ ? 0 : $wt =~ m{(?:^|/)\.[^/]*[*?\[]} ? 'g2' : $wt =~ m{[*?\[][^/]*//} ? 'a5' : 'split'; dep('files', 'glob', $wt, wlit($w)) } elsif ($mode eq 'pattern') { why('locale') if $a[0] =~ /\[|[^\x00-\x7f]/ } }
    elsif ($k eq '~') { dep('tilde', 'tilde', wtext($w), $a[0] eq '') }   # (-d: ~ alone depends on HOME only; ~user on the user database)
    elsif ($k eq '$' || $k eq '${#') { var($a[0], $cx, $q || $k eq '${#', $k eq '${#' ? 'length' : '', $mode) }
    elsif ($k eq '${') { var($a[0], $cx, $q, ($a[1] // '') =~ /^:?\?\z/ ? 'check' : '', $mode); my $op = $a[1] // '';
      word($a[2], $cx, $op =~ /^[%#]/ ? 'pattern' : $q ? 'assign' : $mode) if defined $a[2];
      vassign($a[0], $cx, safe_lit($a[2])) if $op =~ /^:?=\z/ }
    elsif ($k eq '$((') { arith($a[0], $cx) }
    elsif ($k eq '$(') { push @SINKS, [$CUR, $mode] if $CUR; if (!$q) { local $PT = 'split'; why('unquoted') } my $save = $CUR; walk_list($a[0], { %$cx, out => 'sub', tested => 0, bg => 0 }); $CUR = $save }
    elsif ($k eq "'") { why('locale') if $mode eq 'pattern' && $a[0] =~ /[^\x00-\x7f]/ }
    elsif ($k eq '{' || $k eq '{..') { word($_, $cx, $mode) for grep ref, @a } } }
sub arith { my ($e, $cx) = @_;
  while ($e =~ /\$?\b([A-Za-z_]\w*)\b(?=\s*(?:<<|>>|[-+*\/%&^|])?=(?!=))|\$\{?([A-Za-z_]\w*|[0-9]+|[#?\$!@*-])\}?|\b([A-Za-z_]\w*)\b/g) {
    if (defined $1) { vassign($1, $cx, 1) } else { var($2 // $3, $cx, 1, 'arith') } } }   # an arithmetic result is digits
sub var { my ($n, $cx, $quoted, $how, $mode) = @_; $how //= ''; $mode //= 'argv';
  if ($n eq '?') {   # the status of what ran before: unknown at the start of a function's body or a trap action
    if (!defined $LAST) { why('status') } else { consume($_) for @$LAST; $_->{q} = 1 for @LOOPS } }
  elsif ($n eq '-' || $n eq '0') { why('start') }
  elsif ($n =~ /^(?:\$|!|PPID)\z/) { why('pid') } elsif ($n eq 'SECONDS') { why('time') }   # the kernel's process IDs, the clock
  elsif ($SHELLVAR{$n}) { }
  elsif ($n =~ /^(?:[1-9]\d*|[@*#])\z/) { push @DEFER, ['args', $n, $POS, $quoted || $n eq '#', $cx->{infunc}, $CUR, $how, $mode] }
  else { push @DEFER, ['var', $n, $cx->{infunc} || $cx->{late} ? 1e9 : $POS, $quoted, $cx->{infunc}, $CUR, $how, $mode] } }

# Redirections.
sub redir { my ($r, $cx) = @_; my ($fd, $op, $w) = @$r;
  if ($op =~ /^<</) { why('heredoc') if ref $w || length $w >= 4096; word($w, $cx, 'heredoc'); return }   # small: a pipe in all three
  if ($op =~ /&\z/) { if (ref $w) { word($w, $cx, 'redir'); why('fd') } elsif ($w ne '-' && $w > 2 && !$OPENFD{$w}) { why('fd') }
    $OPENFD{$fd} = 1 if $fd > 2; return }
  $OPENFD{$fd} = 1 if $fd > 2;
  if (ref $w) { word($w, $cx, 'redir'); local $PT = 'a5'; dep('files', $op, wtext($w), 0); return }
  if ($w eq '/dev/null') { why('devnull'); return } if ($w =~ m{^/dev/(?:std(?:in|out|err)|fd/\d+)\z}) { why('devfd'); return }
  local $PT = 'a5'; dep('files', $op, $w, 1); if ($w =~ m{^/}) { my $p = pclass($w); why($p) if $p } }   # (absolute: named too, for step 3's setups)

# The walk.  Context: out (run, next, sub, file), in (run, pipe, file, heredoc), tested, bg, infunc, late (a trap
# action: runs at the end).
sub walk_list { my ($l, $cx) = @_; walk_andor($_, $cx) for @{$l // []} }
sub walk_andor { my ($ao, $cx) = @_; my @p = grep ref, @$ao; my $bg = $ao->[-1] eq '&'; my @all;
  for my $i (0 .. $#p) { my $l = walk_pipe($p[$i], { %$cx, tested => $cx->{tested} || $i < $#p, bg => $cx->{bg} || $bg });
    $LAST = $l; push @all, @$l }
  $LAST = $bg ? [] : \@all }   # $? after it: the status of one of its pipelines (after &: 0)
sub walk_pipe { my ($p, $cx) = @_; my $neg = $p->[0] eq '!'; my @c = grep ref, @$p;
  my @b; for my $i (0 .. $#c) {
    my $cxi = { %$cx, tested => $cx->{tested} || ($neg && $i == $#c) || 0, in => $i ? 'pipe' : $cx->{in} // 'run',
      out => $i < $#c ? 'next' : $cx->{out} // 'run' };
    my $first = @BLKS; walk_cmd($c[$i], $cxi); push @b, [@BLKS[$first .. $#BLKS]] }
  my $last = $b[-1]; $FINAL = $c[-1]{argv} ? $last->[0] : undef;   # the last pipeline walked: at the end, the text's last command
  return $last unless @c > 1;
  why('pipeline', $_) for map @$_, @b;
  for my $i (0 .. $#c - 1) {
    my ($w, $r) = ($c[$i], $c[$i + 1]);
    if (consumer($r) && opaque($w, {})) { why('prog-output', $_) for @{$b[$i + 1]} }
    if (!$w->{argv} || is_func($w)) { why('race', $_) for @{$b[$i]} } }
  $last }
sub name_of { my $c = shift; return undef unless ref $c eq 'HASH' && $c->{argv} && @{$c->{argv}};
  my @a = @{$c->{argv}}; shift @a while @a > 1 && !ref $a[0] && $a[0] =~ /^(?:command|exec)\z/ && !(!ref $a[1] && $a[1] =~ /^-[vV]/);
  shift @a while @a > 1 && !ref $a[0] && $a[0] =~ /^-/; ref $a[0] ? '' : $a[0] }
sub is_func { my $n = name_of(shift); defined $n && $FDEF{$n} }   # (for the pipe rules: a function, or a name that may be one)
sub consumer { my $c = shift; return 1 unless ref $c eq 'HASH';   # does the shell itself read this command's input?
  return 0 if grep { $$_[0] == 0 && $$_[1] =~ /^</ } @{$c->{redir} // []};
  return 1 unless $c->{argv}; my $n = name_of($c); return 1 if !defined $n || $n eq '';
  return 1 if $n eq 'read' || $n eq 'eval' || $FDEF{$n}; 0 }
sub opaque { my ($c, $seen) = @_;   # may this command's standard output hold a program's output?
  return 0 unless ref $c eq 'HASH';
  return 0 if grep { $$_[0] == 1 && $$_[1] =~ /^>/ } @{$c->{redir} // []};
  if ($c->{argv} && @{$c->{argv}}) { my $n = name_of($c); return 1 if !defined $n || $n eq '' || $n eq 'eval' || $n =~ m{/};
    if ($FDEF{$n}) { return 1 unless $FNOW{$n}; return 0 if $seen->{$n}++; return opaque($FDEF{$n}, $seen) }
    return $OWN{$n} ? 0 : 1 }
  my $any = 0; my @todo = map $c->{$_}, grep exists $c->{$_}, qw(sub group if while until do in body);
  while (@todo) { my $x = shift @todo; if (ref $x eq 'HASH') { $any ||= opaque($x, $seen) } elsif (ref $x eq 'ARRAY') { push @todo, @$x } }
  $any }
sub walk_cmd { my ($c, $cx) = @_;
  my $cin = { %$cx };
  for (@{$c->{redir} // []}) { $cin->{in} = $$_[1] =~ /^<</ ? 'heredoc' : 'file' if $$_[0] == 0 && $$_[1] =~ /^</;
    $cin->{out} = 'file' if $$_[0] == 1 && $$_[1] =~ /^>/ }
  if (exists $c->{func}) { local ($CUR, $LAST, @LOOPS); $FNOW{$c->{func}} = 1; walk_cmd($c->{body}, { %$cx, infunc => 1, tested => 0, in => 'run', out => 'run', bg => 0 }); return }
  if (!$c->{argv} && !$c->{env} && grep exists $c->{$_}, qw(sub group if while until for case)) {
    if ($c->{redir}) { $CUR = newblock('REDIR ' . ctext({ redir => $c->{redir} }), $cx); redir($_, $cx) for @{$c->{redir}} }
    why('race', $_) for grep $cx->{bg}, $CUR ? ($CUR) : ();
    if ($c->{sub} || $c->{group}) { walk_list($c->{sub} // $c->{group}, $cin) }
    elsif ($c->{if}) { my @x = @{$c->{if}}; while (@x) { my $cond = shift @x; if (@x) { walk_list($cond, { %$cin, tested => 1 }); walk_list(shift @x, $cin) } else { walk_list($cond, $cin) } } }
    elsif ($c->{while} || $c->{until}) { loop(sub { walk_list($c->{while} // $c->{until}, { %$cin, tested => 1 }); walk_list($c->{do}, $cin) }) }
    elsif ($c->{for}) { $CUR = newblock('for ' . $c->{for} . ($c->{in} ? ' in ' . join(' ', map wtext($_), @{$c->{in}}) : ''), $cx);
      why('race') if $cx->{bg}; $CUR->{kind} = 'for';
      if ($c->{in}) { word($_, $cx, 'argv') for @{$c->{in}}; vassign($c->{for}, $cx, !grep !safe_lit($_), @{$c->{in}}) }
      else { push @DEFER, ['args', '@', $POS, 1, $cx->{infunc}, $CUR]; vassign($c->{for}, $cx, 0) }
      loop(sub { walk_list($c->{do}, $cin) }) }
    elsif ($c->{case}) { my @x = @{$c->{in} // []}; $CUR = newblock('case ' . wtext($c->{case}) . ' in', $cx); $CUR->{kind} = 'case'; why('race') if $cx->{bg};
      word($c->{case}, $cx, 'case'); for my $i (0 .. @x / 2 - 1) { word($_, $cx, 'pattern') for @{$x[2 * $i]} }
      while (@x) { shift @x; walk_list(shift @x, $cin) } }
    return }
  $CUR = newblock(exists $c->{exec} && !$c->{argv} ? 'exec ' . ctext({ redir => $c->{redir} }) : ctext($c), $cin);
  simple($c, $cin) }

sub loop {   # a loop's body: $? in it may be the status of any of its commands (from the round before)
  my $code = shift; my $fr = { q => 0 }; my $first = @BLKS; { local @LOOPS = (@LOOPS, $fr); $code->() }
  if ($fr->{q}) { consume($_) for @BLKS[$first .. $#BLKS] } }
sub simple { my ($c, $cx) = @_;
  why('race') if $cx->{bg};
  redir($_, $cx) for @{$c->{redir} // []};
  for my $k (qw(env set export readonly local)) { my @e = @{$c->{$k} // []}; next unless exists $c->{$k};
    if (!@e && $k ne 'local') { why('listing') }
    while (@e) { my ($n, $v) = splice @e, 0, 2; word($n, $cx, 'argv') if ref $n; word($v, $cx, 'assign') if defined $v;
      vassign($n, $cx, !defined $v || safe_lit($v)) } }
  if (exists $c->{cd}) { { local $PT = !defined $c->{cd} || (!ref $c->{cd} && $c->{cd} eq '-') ? 0 : 'a5'; dep('directory', 'cd', wtext($c->{cd}), !ref $c->{cd}) } $CUR->{kind} = 'cd'; word($c->{cd}, $cx, 'argv') if ref $c->{cd}; return }
  my @a = @{$c->{argv} // []}; return unless @a;
  word($_, $cx, 'argv') for @a;
  my $n = $a[0];
  while (!ref $n && ($n eq 'command' || $n eq 'exec') && @a > 1) {
    if ($n eq 'command' && !ref $a[1] && $a[1] =~ /^-[vV]/) { why('lookup'); return }
    shift @a; shift @a while @a > 1 && !ref $a[0] && $a[0] =~ /^-/; $n = $a[0] }
  if (ref $n) { why('name'); $CUR->{sopaque} = 1; consume($CUR) if $cx->{tested}; why('prog-output') if $cx->{out} eq 'sub'; return }
  my @op = @a[1 .. $#a]; $CUR->{kind} = "builtin:$n";
  my $lit = !grep ref, @op;
  if ($n eq 'time') { why('time'); return }
  if ($n eq ':' || $n eq 'true' || $n eq 'false') { return }
  $CUR->{kind} = 'echo' if $n eq 'echo' || $n eq 'printf';
  if ($n eq 'echo') { why('echo') if !$lit || grep(/\\/, @op) || (@op && $op[0] =~ /^-/); return }
  if ($n eq 'printf') { my @f = @op; splice @f, 0, ($f[0] eq '-v' ? 2 : 1) if @f && !ref $f[0] && $f[0] =~ /^-v/; shift @f if @f && !ref $f[0] && $f[0] eq '--';
    if (!@f || ref $f[0]) { why('locale') } else { my $f = $f[0];
      why('time') if $f =~ /%[-+ #0-9.*]*\(/; why('locale') if $f =~ /%[-+ #0-9.*']*'|%[-+ #0-9.*]*[feEgGaAq]/ }
    return }
  if ($n eq 'test' || $n eq '[') { $CUR->{kind} = 'test'; my @t = @op; pop @t if $n eq '[' && @t && !ref $t[-1] && $t[-1] eq ']';
    for my $i (0 .. $#t) { next if ref $t[$i]; local $_ = $t[$i];
      if ($FILEOPS{$_}) { my @o = grep { $_ >= 0 && $_ <= $#t } $i + 1, (/^-(?:nt|ot|ef)\z/ ? $i - 1 : ());   # the operands it takes
        local $PT = 'status'; if (@o) { dep('files', 'test', "$_ " . wtext($t[$o[0]]), wlit($t[$o[0]]) && !grep(ref, @t)) } else { why('files') } }
      why('fd') if $_ eq '-t'; why('vars') if $_ eq '-v'; why('locale') if $_ eq '<' || $_ eq '>' }
    why('test-ops') if grep({ ref && unquoted($_) } @t) || (@t > 3 && grep ref, @t);
    return }
  if ($n eq 'read') { dep('input', 'stdin', '', 1) if $cx->{in} eq 'run'; vassign($_, $cx, 0) for grep { !ref && !/^-/ } @op; return }
  if ($n eq 'getopts') { vassign($op[1], $cx, 0) if @op > 1; vassign('OPTARG', $cx, 0);
    push @DEFER, ['args', '@', $POS, 1, $cx->{infunc}, $CUR, 'getopts'] if @op < 3; return }
  if ($n eq 'set') { if (!@op) { why('listing'); return }
    my $i = 0; while ($i < @op && !ref $op[$i] && $op[$i] =~ /^[-+]/ && $op[$i] ne '--' && $op[$i] ne '-') {
      my $o = $op[$i]; why('fd') if $o =~ /^-\w*m/ || ($o eq '-o' && $i < $#op && !ref $op[$i + 1] && $op[$i + 1] eq 'monitor'); $NOUNSET = 1 if $o =~ /^-\w*u/ || ($o eq '-o' && $i < $#op && !ref $op[$i + 1] && $op[$i + 1] eq 'nounset'); my $on = $o =~ /^-\w*e/ || ($o eq '-o' && $i < $#op && !ref $op[$i + 1] && $op[$i + 1] eq 'errexit');   # set -e: from here on
      my $off = $o =~ /^\+\w*e/ || ($o eq '+o' && $i < $#op && !ref $op[$i + 1] && $op[$i + 1] eq 'errexit');   #   every status decides
      if ($on) { $ERREXIT = $ANYERR = 1 } elsif ($off) { $ERREXIT = 0 }
      $i += $o =~ /^[-+]o\z/ ? 2 : 1 }
    $i++ if $i < @op && !ref $op[$i] && ($op[$i] eq '--' || $op[$i] eq '-');
    if ($i < @op || grep { !ref && $_ eq '--' } @op) { if (!$cx->{infunc}) { $ARGSET //= $POS } $ARGSLIT &&= !grep !safe_lit($_), @op[$i .. $#op] }
    return }
  if ($n eq 'shift') { push @DEFER, ['args', '@', $POS, 1, $cx->{infunc}, $CUR, 'shift']; return }
  if ($n =~ /^(?:unset|alias|unalias|return|break|continue|exit)\z/) { return }
  if ($n eq 'export' || $n eq 'readonly' || $n eq 'local') { my @o = grep { ref || !/^-/ } @op;
    if (!@o && $n ne 'local') { why('listing') } vassign(/^([^=]*)=(.*)\z/s ? ($1, $cx, $2 !~ /[*?\[]/) : ($_, $cx, 1)) for grep !ref, @o; return }
  if ($n eq 'umask') { why('limits') if !grep { ref || !/^-/ } @op; return }
  if ($n eq 'ulimit') { why('limits'); return }
  if ($n eq 'eval' || $n eq 'trap') { my @t = @op;
    if ($n eq 'trap') { return if !@t || (!ref $t[0] && $t[0] =~ /^-[lp]?\z|^\z/); }
    if (grep ref, ($n eq 'eval' ? @t : $t[0])) { why('eval'); return }
    my $text = $n eq 'eval' ? join(' ', @t) : $t[0]; my $tree = Proc::ShellSubset::Large::parse($text, empty => 1);
    if (ref $tree ne 'ARRAY') { why('eval'); return }
    my $save = $CUR; if ($n eq 'eval') { walk_list($tree, $cx) } else { local ($LAST, @LOOPS); walk_list($tree, { %$cx, late => 1, tested => 0, out => 'run', in => 'run', bg => 0 }) }
    $CUR = $save; return }
  if ($n eq '.' || $n eq 'source') { if (@op) { dep('files', 'dot', wtext($op[0]), !ref $op[0]) } else { why('files') } return }
  if ($n eq 'cd' || $n eq 'pwd') { local $PT = $n eq 'pwd' ? 1 : (!@op || grep { !ref && $_ eq '-' } @op) ? 0 : 'a5'; $CUR->{kind} = $n; why('directory'); return }
  if ($n =~ /^(?:wait|jobs|fg|bg|disown)\z/) { why('pid') if @op; return }
  if ($n eq 'kill') { why('pid') unless @op && !ref $op[0] && $op[0] =~ /^-[lL]/; return }
  if ($n eq 'times') { why('time'); return }
  if ($n eq 'hash' || $n eq 'type') { why('lookup'); return }
  if ($INTER{$n}) { my @o = grep { !ref && /^-/ } @op; my $file = grep(ref, @op) || ($n eq 'history' && grep /[rawn]/, @o) || ($n eq 'bind' && grep /f/, @o) || ($n eq 'fc' && !grep /[ls]/, @o);
    local $PT = $file ? 0 : 1; why('interactive'); return }
  $FARGSOK &&= !grep !safe_lit($_), @op if $FDEF{$n};
  if ($FNOW{$n}) { $CUR->{kind} = 'function';
    $CUR->{sopaque} = 1 if opaque_status($n, {}); consume($CUR) if $cx->{tested};
    return }
  # an external program
  if ($n =~ /^(?:env|printenv)\z/ && !grep { ref || !/^-/ } @op) { why(q(listing)); return }   # they print the environment the shell passes
  if ($n =~ m{/}) { if ($n =~ m{^/}) { my $p = pclass($n); why($p) if $p } else { local $PT = 'a5'; dep('files', 'exec', $n, 1) } }
  # programs known not to do the same in each run (a list of known cases, not complete): the assumption of "program" fails
  { local $PT = 'control';
  if ($n =~ /^(?:date|shuf|mktemp|uuidgen)\z/) { why($n eq 'date' ? 'time' : 'random') }
  if ($n eq 'sort' && grep { !ref && /^-(?:[a-zA-Z]*R|-random)/ } @op) { why('random') }
  if ($n eq 'stat' || ($n eq 'ls' && grep { !ref && /^-[a-zA-Z]*[ltcu]/ } @op)) { why('time') } }   # each run's copy of the directory has new file times
  if ($n eq 'xargs') { my $arg = ''; for (@op) { if ($arg) { why('race') if $arg eq 'P' && (ref || $_ ne '1'); $arg = ''; next }
      last if ref || !/^-/; why('race') if /^-(?:\w*P(?!1\z).|-max-procs(?!=1\z))/; $arg = $1 if /^-\w*([ILnPsdEa])\z/ } }
  why('program'); $CUR->{sopaque} = 1; $CUR->{kind} = 'program'; $CUR->{cmd} = $n;
  my %prev; for my $i (1 .. $#op) { $prev{$op[$i]} //= $op[$i - 1] if !ref $op[$i] && !ref $op[$i - 1] }
  for (grep !ref, @op) { my $p = m{^(/[^\s]*)} ? $1 : m{=(/[^\s]*)} ? $1 : m{^-[dFt](/)\z} ? $1 : next; my $k = pclass($p);
    next if $p eq '/' && ($n =~ /^(?:tr|sed)\z/ || ($prev{$_} // '') =~ /^-(?:d|F|t|-delimiter|-field-separator)\z/ || /^-[dFt]\//);   # text (cut -d /, -F/), no path
    local $PT = $k =~ /^path-(?:tmp|random|root|proc)\z/ ? 'control' : 0; why($k) if $k }   # absolute paths given to it
  consume($CUR) if $cx->{tested}; if ($cx->{out} eq 'sub') { local $PT = 1; why('prog-output') } }
sub unquoted { my $w = shift; grep { ref && $$_[0] =~ /^(?:\$|\$\{|\$\{#|\$\(|\*|~)\z/ } @$w }
sub opaque_status { my ($n, $seen) = @_; return 0 if $seen->{$n}++; my $any = 0; my @todo = ($FDEF{$n});   # may a call's status be a program's?
  while (@todo) { my $x = shift @todo;
    if (ref $x eq 'HASH') { if ($x->{argv} && @{$x->{argv}}) { my $m = name_of($x); $any = 1 if !defined $m || $m eq '' || $m =~ m{/} || (!$OWN{$m} && (!$FNOW{$m} || opaque_status($m, $seen))) }
      push @todo, values %$x } elsif (ref $x eq 'ARRAY') { push @todo, @$x } }
  $any }

# Each sample.
my (%B, %LV, %LV2, %DL, %RS, %RSA, %RSONLY, %BYSRC, %SAMPLE); my $t0 = time;
my %AICAT;   # -ai: id => category (read again and checked under -p); the rows of the tables take them as N+M=T (2026-11-13)
my %AIROW = ('AI-strict' => 0, 'AI-values passed on unchanged' => 3, 'AI-values passed on split' => 4);
if ($AIF) { open my $a, '<:utf8', $AIF or die "$AIF: $!"; while (<$a>) { next if /^#/ || /^id\t/; chomp; my ($id, $cat) = split /\t/; $AICAT{$id} = $cat } }
for my $s (@S) {
  my $tree = Proc::ShellSubset::Large::parse($s->{text}, empty => 1); if (ref $tree ne q(ARRAY)) { warn "$s->{id}: rejected alone, skipped\n"; next }
  (%FDEF, %FNOW, @BLKS, %VSET, %VLIT, %OPENFD, @DEFER, @DEPS, %VALSINK, @SINKS) = (); $NOUNSET = 0; ($CUR, $POS, $ARGSET, $ARGSLIT, $FARGSOK) = (undef, 0, undef, 1, 1);
  { my @todo = ($tree); while (@todo) { my $x = shift @todo;   # the functions this text defines (3A: called by name anywhere)
      if (ref $x eq 'HASH') { $FDEF{$x->{func}} = $x->{body} if exists $x->{func}; push @todo, values %$x } elsif (ref $x eq 'ARRAY') { push @todo, @$x } } }
  ($LAST, @LOOPS, $ERREXIT, $ANYERR, $FINAL) = ([]);
  walk_list($tree, { out => 'run', in => 'run', tested => 0, bg => 0 });
  if ($ANYERR) { for my $b (@BLKS) { consume($b) if ($b->{errexit} || $b->{cx}{infunc} || $b->{cx}{late}) && !(defined $FINAL && $b == $FINAL) } }   # under set -e a failure stops the rest; the last command has no rest
  for my $d (@DEFER) { my ($k, $n, $p, $q, $infunc, $b, $how, $mode) = @$d; $how //= ''; $mode //= 'argv';
    if ($k eq 'var') { my $set = defined $VSET{$n} && $VSET{$n} < $p; push @SINKS, [$b, $mode] if (!$set || !$VLIT{$n}) && $how ne 'length';
      if (!$set) { local $PT = !$how && !$OWNVAR{$n} ? ($q ? 1 : 'split') : 0; dep('vars', 'read', $n, 1, $b) } elsif (!$q && !$VLIT{$n}) { local $PT = 'split'; why('unquoted', $b) }
      elsif ($how eq 'arith' && !$VLIT{$n}) { $VALSINK{'arithmetic on a value'} = 1 } }
    elsif ($infunc) { push @SINKS, [$b, $mode] if !$FARGSOK && $n ne '#'; if (!$q && !$FARGSOK) { local $PT = 'split'; why('unquoted', $b) } $VALSINK{'arithmetic on a value'} = 1 if $how eq 'arith' && !$FARGSOK }
    elsif ((!defined $ARGSET || $ARGSET >= $p || !$ARGSLIT) && $n ne '#' && push(@SINKS, [$b, $mode]) && 0) { }
    elsif (!defined $ARGSET || $ARGSET >= $p) { local $PT = !$how ? ($q ? 1 : 'split') : 0; dep('args', 'arg', $n, 1, $b) } elsif (!$q && !$ARGSLIT) { local $PT = 'split'; why('unquoted', $b) }
    elsif ($how eq 'arith' && !$ARGSLIT) { $VALSINK{'arithmetic on a value'} = 1 } }
  my %r; $r{$_} = 1 for map keys %{$_->{r}}, @BLKS;
  my $lv = 0; $lv = $LEVEL{$_} > $lv ? $LEVEL{$_} : $lv for keys %r;
  my @rs = grep $r{$_}, @HELD, @ALMOST, @UNDEC; my @here = grep $LEVEL{$_} == $lv, @rs;
  $SAMPLE{$s->{id}} = [$lv, \@rs, $s];
  if ($lv == 3) {   # step 3 (X27): where each value from the environment lands; the class, its reasons
    my (%np, %pa, %sp, %ct, %ST, %R, %CTP); for my $b (@BLKS) { for my $r (grep $LEVEL{$_} == 3, keys %{$b->{r}}) {
        my $kd = $b->{pt}{$r} // {}; my $bk = $b->{kind} // '';
        if ($b->{np}{$r} || ($kd->{split} || $kd->{g2}) && $bk !~ /^(?:program|echo|for)\z/
            || $kd->{a5} && $bk !~ /^(?:program|echo|cd|pwd)\z/ && !($b->{text} =~ /^exec / && $r eq 'files')) { $np{$r} = 1; next }
        if ($kd->{control}) { $ct{$r} = 1; $CTP{"$r:" . ($b->{cmd} // ($b->{text} =~ /^(\S+)/ ? $1 : '?'))} = 1 }
        $sp{$r} = 1 if $kd->{split}; $pa{$r} = 1 if $kd->{1} || $kd->{status}; $ST{$r} = 1 if $kd->{status};
        if ($kd->{a5}) { $ct{$r} = 1; $R{A5} = 1 } if ($kd->{g2}) { $ct{$r} = 1; $R{G2} = 1 } } }
    for (@SINKS) { my ($b, $m) = @$_; next if $m =~ /^(?:assign|case|heredoc|redir)\z/; my $bk = $b->{kind} // '';
      if ($m eq 'pattern') { $VALSINK{'a value as a pattern'} = 1 } elsif ($bk =~ /^(?:program|for|function|cd)\z/) { }
      elsif ($bk =~ /^(?:echo|test)\z/) { $R{program} = 1 } else { $VALSINK{'a value into ' . ($bk =~ s/^builtin://r || 'a command')} = 1 } }
    my @x = (sort(keys %np), sort(keys %VALSINK));
    push @x, 'set -e' if $ANYERR && ($ct{'prog-status'} || $pa{'prog-status'} || %ST);
    push @x, 'set -u' if $NOUNSET && grep { $ct{$_} || $pa{$_} || $sp{$_} } qw(vars args);
    $SAMPLE{$s->{id}}[4] = [@x ? 'affects-shell' : (%ct || %R) ? 'control' : %sp ? 'split' : 'pass', join(',', @x),
      join(',', (sort keys %CTP), map "ruling:$_", sort keys %R), [grep $LEVEL{$_} == 3, @rs]] }
  if ($lv == 3 && $OUTD) {   # -d: what the undecided codes come from, block by block
    my %bn; my $i = 0; $bn{$_} = ++$i for @BLKS;
    my %ub; for my $b (@BLKS) { $ub{$bn{$b}} = 1 if grep $LEVEL{$_} == 3, keys %{$b->{r}} }
    my %seen; my @d = grep !$seen{join "\0", @$_}++, map [@$_[0 .. 3], $bn{$_->[4]}], grep $LEVEL{$_->[0]} == 3, @DEPS;
    my %bare;   # a code on a block that no dep of that block names (e.g. a test file operator with no operand)
    my @bare;   # [CODE, BLOCK]: the same, by block
    for my $b (@BLKS) { for my $r (sort grep $LEVEL{$_} == 3, keys %{$b->{r}}) { my $n = $bn{$b};
        next if grep { $_->[0] eq $r && $_->[4] == $n } @d; $bare{$r} = 1; push @bare, [$r, $n] } }
    $SAMPLE{$s->{id}}[3] = { id => $s->{id}, text => $s->{text}, codes => [grep $LEVEL{$_} == 3, @rs], blocks => scalar(keys %ub),
      deps => \@d, rest => [grep $bare{$_}, @UNDEC], bare => \@bare } }
  if ($lv == 3 && $SAMPLE{$s->{id}}[4][0] =~ /^(?:pass|split)\z/) {   # (a), the user 2026-11-12: almost strict, under passthrough
    @rs = (grep($LEVEL{$_} < 3, @rs), 'passthrough', $SAMPLE{$s->{id}}[4][0] eq 'split' ? 'splitglob' : ());   # (and splitglob)
    $lv = 2; @here = grep $LEVEL{$_} == 2, @rs; @{$SAMPLE{$s->{id}}}[0, 1] = ($lv, \@rs) }
  $LV{$lv}++;
  my $dl = $lv < 2 ? $lv : $lv == 3 ? 5 : (grep $_ eq 'splitglob', @rs) ? 4 : (grep $_ eq 'passthrough', @rs) ? 3 : 2;   # the rows (LV1)
  my $ai = defined $AICAT{$s->{id}} ? 1 : 0; $dl = $AIROW{$AICAT{$s->{id}}} // $dl if $ai;   # found by the programs 0, by reading 1
  $DL{$s->{id}} = $dl; $LV2{$dl}[$ai]++; $BYSRC{$s->{src}}{$dl}[$ai]++;
  if ($lv) { $RS{$lv}{$_}++ for @here; $RSONLY{$lv}{$here[0]}++ if @here == 1 }
  for my $b (@BLKS) { my $blv = 0; $blv = $LEVEL{$_} > $blv ? $LEVEL{$_} : $blv for keys %{$b->{r}};
    my $cx = $b->{cx}; my $ctx = join ',', grep $_, ($cx->{out} && $cx->{out} ne 'run' ? "out:$cx->{out}" : ''),
      ($cx->{in} && $cx->{in} ne 'run' ? "in:$cx->{in}" : ''), ($cx->{tested} ? 'tested' : ''), ($cx->{infunc} ? 'func' : ''), ($cx->{bg} ? 'bg' : '');
    my $e = $B{"$b->{text}\t$ctx"} //= { text => $b->{text}, ctx => $ctx, level => (qw(strict held almost undecided))[$blv],
      reasons => join(' ', grep $b->{r}{$_}, @HELD, @ALMOST, @UNDEC), n => 0, ids => [] };
    $e->{n}++; push @{$e->{ids}}, $s->{id} unless @{$e->{ids}} && $e->{ids}[-1] eq $s->{id} } }
printf STDERR "%d samples cut into blocks in %.1f s\n", scalar @S, time - $t0;

# Tables.  The rows (LV1, the user, 2026-11-13): almost strict apart from the samples that are so only by step 3's
# assumptions, "values passed on unchanged" (passthrough) and "values passed on split" (passthrough and splitglob; none
# needs splitglob alone): the user trusts those less.  The record (-e) keeps A for all three; its codes tell them apart.
my @LN = qw(strict held almost undecided);
my @LN2 = ('strict', 'held', 'almost strict', 'values passed on unchanged', 'values passed on split', 'undecided');
my $nb = 0; $nb += $_->{n} for values %B; my %bl; $bl{$_->{level}}++ for values %B;
printf "%d samples; %d blocks, %d distinct with their place: %s\n", scalar @S, $nb, scalar keys %B, join ', ', map "$_ $bl{$_}", grep $bl{$_}, @LN;
sub fmtn { my $x = reverse shift; $x =~ s/(\d{3})(?=\d)/$1,/g; scalar reverse $x }
sub pm { my $v = $_[0] // []; my ($p, $a) = ($v->[0] // 0, $v->[1] // 0); $a ? sprintf('%s+%s=%s', fmtn($p), fmtn($a), fmtn($p + $a)) : fmtn($p) }   # N+M=T, or N
sub tot { my $v = $_[0] // []; ($v->[0] // 0) + ($v->[1] // 0) }
printf "\nSamples by level:\n"; printf "  %-28s %13s  %5.1f %%\n", $LN2[$_], pm($LV2{$_}), 100 * tot($LV2{$_}) / @S for 0 .. 5;
print "  (N+M=T: N found by the programs, M classified by reading, -ai; AI-strict in strict, AI-values passed on ... in those rows,\n   the other categories undecided)\n" if $AIF;
print "\nBy source (strict / held / almost strict / values passed on unchanged / values passed on split / undecided):\n";
for (sort keys %BYSRC) { my $t = 0; $t += tot($_) for values %{$BYSRC{$_}}; my $src = $_; printf "  %-16s %6d: %s\n", $src, $t, join ' ', map sprintf('%10s', pm($BYSRC{$src}{$_})), 0 .. 5 }
for my $lv (1, 2, 3) { print "\n$LN[$lv]: samples with each reason of that level / with that reason alone:\n";
  printf "  %-12s %6d %6d\n", $_, $RS{$lv}{$_} // 0, $RSONLY{$lv}{$_} // 0 for $lv == 1 ? @HELD : $lv == 2 ? @ALMOST : @UNDEC }
{ my %set; for (values %SAMPLE) { $set{join ' ', @{$_->[1]}}++ if $_->[0] == 1 || $_->[0] == 2 }
  print "\nheld and almost, by the set of assumptions a sample needs:\n"; printf "  %6d  %s\n", $set{$_}, $_ for sort { $set{$b} <=> $set{$a} || $a cmp $b } keys %set }
if ($OUTB) { open my $o, '>', $OUTB or die; print $o $J->encode($_), "\n" for sort { $b->{n} <=> $a->{n} || $a->{text} cmp $b->{text} } values %B }
if ($OUTS) { open my $o, '>:utf8', $OUTS or die; print $o "id\tlevel\treasons\ttext\n";
  for my $s (grep $SAMPLE{$_->{id}}, @S) { my ($lv, $rs) = @{$SAMPLE{$s->{id}}}; (my $x = $s->{text}) =~ s/\s*\n\s*/\\n/g; print $o join("\t", $s->{id}, $LN2[$DL{$s->{id}}], "@$rs", $x), "\n" } }
if ($OUTP) { open my $o, '>:utf8', $OUTP or die;   # step 3: every sample undecided before it
  print $o <<'H', "id\tclass\twhat keeps it\tunder control through\tthe undecided codes before\ttext\n";
# large-subset-step3.tsv (X27, step 3; post-0.11, 2026-11-12): every corpus sample undecided by its codes alone, with
# where its values from the environment land; written by large-subset-blocks.pl -p.  Columns (tab): id; class (pass:
# they only pass through the shell; split: the same, some split and globbed into a program's words; both are almost
# strict in large-subset-provenance.tsv, assumptions passthrough and splitglob; control: it depends on the environment
# only through what the run can set; affects-shell: a value from the environment affects what the shell itself does; AI-...: a
# sample of those two classified by reading, large-subset-ai-classes.tsv, with -ai); what keeps it from pass (the
# codes, or "a value into BUILTIN", "set -e", "set -u", "arithmetic on a value", "a value as a pattern"); what the run
# controls (CODE:PROGRAM for a program's answer, /tmp, /dev/urandom, the tree; ruling:A5, G2, program for a switch whose
# other state the named ruling covers); the undecided codes; the text.  large-subset-environment.md, section 12.
H
  my %AI;   # -ai (post-0.11, 2026-11-13): samples classified by reading (large-subset-ai-classes.tsv): their category is
  if ($AIF) { open my $a, '<:utf8', $AIF or die "$AIF: $!";   # the class; each must be one the rules leave in control or affects-shell
    while (<$a>) { next if /^#/ || /^id\t/; chomp; my ($id, $cat, undef, undef, $rc) = split /\t/;
      my $c = $SAMPLE{$id} && $SAMPLE{$id}[4] && $SAMPLE{$id}[4][0];
      defined $c && $c =~ /^(?:control|affects-shell)\z/ or die "$AIF: $id is not a sample of the class control or affects-shell\n";
      $c eq $rc or die "$AIF: $id: the rules give $c, the file says $rc\n"; $AI{$id} = $cat } }
  for my $s (grep { $SAMPLE{$_->{id}} && $SAMPLE{$_->{id}}[4] } @S) { my ($c, $why, $ctl, $u) = @{$SAMPLE{$s->{id}}[4]}; $c = $AI{$s->{id}} // $c;
    (my $x = $s->{text}) =~ s/\s*\n\s*/\\n/g; print $o join("\t", $s->{id}, $c, $why, $ctl, join(',', @$u), $x), "\n" } }
if ($OUTD) { open my $o, '>', $OUTD or die; print $o $J->encode($SAMPLE{$_->{id}}[3]), "\n" for grep { $SAMPLE{$_->{id}} && $SAMPLE{$_->{id}}[3] } @S }
if ($OUTE) { open my $o, '>:utf8', $OUTE or die; print $o <<'H';
# large-subset-provenance.tsv: every corpus sample the large parser accepts (40,410), one line each, by snippet ID.
# Columns (tab): ID CODE
#   ID    where the text comes from: format in doc/parsers/shell-subset-test-provenance.md, section 2; the texts are
#         remade from the pinned sources by doc/large-subset/tools/large-subset-extract.pl (doc/test-pools.md, 3).
#   CODE  known issue X27: could the run-time comparison of dash, bash --posix and ours (large-subset-state.md,
#         section 7) come out otherwise in another environment?
#           S                    strict: no; only how the shell is started is assumed
#           H:a,b                held: no, under assumptions known to hold in every environment tested (devnull, heredoc)
#           A:a,b                almost strict: no, if the assumptions a, b hold (program, pipeline, path-system, ...);
#                                passthrough(r,s): the values the undecided codes r, s name only pass through (step 3)
#           U:r,s/a,b            undecided: may depend on r, s (files, vars, prog-status, path-tmp, ...); the
#                                assumptions a, b would be needed besides
#         Every code, how to remake this file and the findings: doc/large-subset/large-subset-environment.md
H
  for my $id (sort keys %SAMPLE) { my ($lv, $rs) = @{$SAMPLE{$id}};
    my @u = grep $LEVEL{$_} == 3, @$rs; my @a = grep $LEVEL{$_} < 3, @$rs;
    my $pt = $SAMPLE{$id}[4] && $lv < 3 ? '(' . join(',', @{$SAMPLE{$id}[4][3]}) . ')' : '';   # (a): the codes it passes through
    print $o "$id\t", $lv == 0 ? 'S' : $lv < 3 ? ('', 'H', 'A')[$lv] . ':' . join(',', map $_ eq 'passthrough' ? "$_$pt" : $_, @a) : 'U:' . join(',', @u) . (@a ? '/' . join(',', @a) : ''), "\n" } }

# Words.  A Word is a string or [Part, ...]; rebuilt as shell text for reading (approximately: quoting is not exact).
sub wtext { my $w = shift; return '' unless defined $w; return lit($w) unless ref $w; join '', map ptext($_), @$w }
sub lit { my $s = shift; $s =~ /^[-\w.\/,:=+@%^]*\z/ && length $s ? $s : "'" . ($s =~ s/'/'\\''/gr) . "'" }
sub ptext { my $p = shift; return $p =~ s/([\\\$`"' \t\n;&|<>(){}*?\[\]#~!])/\\$1/gr unless ref $p;
  my ($t, @a) = @$p; my $q = $t =~ s/^"// ? '"' : '';
  my $x = $t eq '$' ? "\$$a[0]" : $t eq '${' ? "\${$a[0]$a[1]" . wtext($a[2]) . '}' : $t eq '${#' ? "\${#$a[0]}"
    : $t eq '$((' ? "\$(($a[0]))" : $t eq '$(' ? '$(' . ltext($a[0]) . ')' : $t eq '~' ? "~$a[0]" : $t eq '*' ? $a[0]
    : $t eq "'" ? "'$a[0]'" : $t eq '{' ? '{' . join(',', map wtext($_), @a) . '}' : $t eq '{..' ? "{$a[0]..$a[1]}" : "<$t?>";
  $q ? "\"$x\"" : $x }
sub ltext { my $l = shift; join '; ', map { my $ao = $_; join ' ', map { ref $_ ? join(' | ', map ctext($_), @$_) : $_ } @$ao } @{$l // []} }
sub ctext { my $c = shift; return $c unless ref $c eq 'HASH';
  return '! ' if 0; my @r = map { my ($fd, $op, $w) = @$_; ($fd == ($op =~ /</ ? 0 : 1) ? '' : $fd) . $op . ($op =~ /^<</ ? 'EOF' : wtext($w)) } @{$c->{redir} // []};
  if ($c->{argv} || $c->{env} || (!grep exists $c->{$_}, qw(cd set export readonly local func sub group if while until for case))) {
    my @e = @{$c->{env} // []}; my @s; while (@e) { my ($n, $v) = splice @e, 0, 2; push @s, "$n=" . wtext($v) }
    return join ' ', @s, map(wtext($_), @{$c->{argv} // []}), @r }
  if (exists $c->{cd}) { return join ' ', 'cd', ($c->{cd_p} ? '-P' : ()), (defined $c->{cd} ? wtext($c->{cd}) : ()), @r }
  for my $k (qw(set export readonly local)) { next unless exists $c->{$k}; my @e = @{$c->{$k}}; my @s;
    while (@e) { my ($n, $v) = splice @e, 0, 2; push @s, defined $v ? "$n=" . wtext($v) : $n } return join ' ', ($k eq 'set' ? () : $k), @s, @r }
  return "$c->{func}() {...}" if exists $c->{func};
  return '(' . ltext($c->{sub}) . ')' if $c->{sub}; return '{ ' . ltext($c->{group}) . '; }' if $c->{group};
  return 'for ...' if $c->{for}; return 'case ...' if $c->{case}; return 'if ...' if $c->{if}; 'while ...' }

sub batch {   # all the accepted samples in one text
  my $t0 = time; my @tr = map { Proc::ShellSubset::Large::parse($_->{text}, empty => 1) } @S;
  printf "Batch: %d samples parsed one by one in %.1f s\n", scalar @S, time - $t0;
  my $norm; $norm = sub { my $x = shift; if (ref $x eq 'HASH') { delete $x->{line}; $_ = $norm->($_) for values %$x } elsif (ref $x eq 'ARRAY') { $_ = $norm->($_) for @$x } elsif (defined $x) { $x = "$x" } $x };
  my (%why, @keep);
  for my $i (0 .. $#S) { my ($s, $t) = ($S[$i], $tr[$i]); my %w; my @todo = ($t);
    while (@todo) { my $x = shift @todo;
      if (ref $x eq 'HASH') { $w{'defines a function (a command by its name anywhere in the text becomes a call of it)'} = 1 if exists $x->{func};
        if (ref $x->{argv} eq 'ARRAY' && @{$x->{argv}} > 1 && !ref $x->{argv}[0] && $x->{argv}[0] =~ /^(?:un)?alias\z/ && grep(!ref && !/^-/, @{$x->{argv}}[1 .. $#{$x->{argv}}])) {
          $w{'defines or removes an alias (it applies to the text after it)'} = 1 }
        push @todo, values %$x } elsif (ref $x eq 'ARRAY') { push @todo, @$x } }
    my $u = $norm->(Proc::ShellSubset::Large::parse("$s->{text}\n:", empty => 1));
    if (ref $u ne 'ARRAY' || $J->encode($u) ne $J->encode([@{$norm->($J->decode($J->encode($t)))}, [[{ argv => [':'] }]]])) {
      $w{ref $u ne 'ARRAY' ? "followed by a line, rejected: $u->{error}" : $s->{text} =~ /\\\z/ ? 'ends in a backslash (joins the next line)'
        : 'its effect on the text after it is known only when it runs (P1: the rest is parsed then)'} = 1 }
    if (%w) { $why{$_}++ for keys %w } else { push @keep, [$s, $t] } }
  printf "Set aside, since they change how the text after them parses (%d samples; one may have two reasons):\n", @S - @keep;
  printf "  %5d  %s\n", $why{$_}, $_ for sort { $why{$b} <=> $why{$a} } keys %why;
  my $all = join "\n", map $_->[0]{text}, @keep; $t0 = time; my $T = Proc::ShellSubset::Large::parse($all, empty => 1);
  printf "The other %d joined: %d characters, %d lines, parsed in %.1f s (%s)\n", scalar @keep, length $all, 1 + ($all =~ tr/\n//), time - $t0, ref $T eq 'ARRAY' ? 'accepted' : "rejected: $T->{error}";
  return unless ref $T eq 'ARRAY'; $norm->($T);
  my ($k, $d) = (0, 0); for my $p (@keep) { my $m = $norm->($J->decode($J->encode($p->[1])));
    my ($x, $y) = ($J->encode($m), $J->encode([@$T[$k .. $k + $#$m]])); $k += @$m;
    if ($x ne $y) { $d++; print "  differs: $p->[0]{id}\n    alone:  $x\n    joined: $y\n" } }
  printf "Top-level entries: %d alone, %d joined; samples whose part of the joined tree differs from their own tree: %d\n", $k, scalar @$T, $d;
  print "(Compared without the line numbers, which \$LINENO anywhere in the text adds to every command.)\n\n" }
