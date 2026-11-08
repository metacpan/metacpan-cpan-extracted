#!/usr/bin/perl
# large-subset-blocks.pl (post-0.08, 2026-11-07; known issue X27): cut every sample the large parser accepts into its
# atomic blocks, and sort the blocks and the samples into three levels by whether the result of comparing dash,
# bash --posix and ours on them can change with the environment:
#   strict     no, from the text alone, assuming only what any run needs: the shell started as in the run
#              (descriptors 0-2 open, no signal from outside, enough memory, processes and disk), and the programs the
#              subset runs in place of builtins (echo, printf, test, [, true, false; rule "the program beats", X21)
#   held       no, under assumptions known to hold in every environment tested (Linux, Linux without /proc,
#              Windows): devnull, heredoc
#   almost     no, under the assumptions named by its reasons (below), each mild but not nothing
#   undecided  not shown either way: a reason names what the result may depend on
# A sample's level is the lowest of its parts'.  Only forms argued safe pass; everything else is undecided, so a
# pass is meant to be definite (under the stated assumptions), a non-pass is not a verdict.  Programs are taken as
# real and opaque: nothing here knows what a program does, only what the shell does with it.
#
# Usage: perl -Ilib large-subset-blocks.pl [-batch] [-o BLOCKS.jsonl] [-s SAMPLES.tsv] [-e PROVENANCE.tsv] samples.jsonl samples.tsv
#   -batch  first parse all the accepted samples one by one and joined into one text (one line apart), and compare
#           each sample's part of the joined tree with its own tree; report what keeps them apart
#   -o      one line per distinct block (with its place): its text (rebuilt from the tree), level, reasons, the samples
#   -s      one line per sample: id, level, reasons, the text
#   -e      every sample: its snippet ID and a short code (large-subset-provenance.tsv; the code is explained in the
#           file's header and in doc/large-subset/large-subset-environment.md)
#
# A block is a simple command (with its settings and redirections), the word list of a 'for', the word and the
# patterns of a 'case', the redirections of a compound command; a command inside $( ) is a block of its own.
#
# The codes, what each assumes or depends on, and whether it can be put under our control:
# doc/large-subset/large-subset-environment.md, section 3.  In short:
#   held:      devnull heredoc
#   almost:    program pipeline devfd locale echo path-system path-var path-home path-dev path-mnt path-absent
#   undecided: files directory vars unquoted args start status prog-output prog-status race pid time random input
#              listing lookup limits fd tilde name test-ops eval interactive path-tmp path-random path-proc path-root
# Compositions: $? takes the status of what ran just before (in a loop: of any command of the loop; at the start of a
# function's body or a trap action it is unknown: status); after set -e (until set +e) every status decides but the
# text's last command's.  A function's name is a call of it only after the walk has passed its definition.
use strict; use warnings; use JSON::PP; use Getopt::Long; use Proc::ShellSubset::Large; use Time::HiRes 'time';
my ($BATCH, $OUTB, $OUTS, $OUTE); GetOptions('batch' => \$BATCH, 'o=s' => \$OUTB, 's=s' => \$OUTS, 'e=s' => \$OUTE) && @ARGV == 2
  or die "usage: $0 [-batch] [-o BLOCKS.jsonl] [-s SAMPLES.tsv] [-e PROVENANCE.tsv] samples.jsonl samples.tsv\n";
$ENV{HOME} //= '/root'; delete $ENV{CDPATH};
my $J = JSON::PP->new->canonical->utf8;
my ($SJ, $ST) = @ARGV;
my %acc; { open my $in, '<', $ST or die "$ST: $!"; my $h = <$in>; chomp $h; my @h = split /\t/, $h; my %c; @c{@h} = 0 .. $#h;
  while (<$in>) { chomp; my @f = split /\t/, $_, -1; $acc{$f[$c{id}]} = 1 if $f[$c{large}] } }
my @S; { open my $in, '<', $SJ or die "$SJ: $!"; my %seen; while (<$in>) { my $s = decode_json $_; push @S, $s if $acc{$s->{id}} && !$seen{$s->{id}}++ } }
if ($BATCH) { batch() }

my @HELD = qw(devnull heredoc);   # assumptions known to hold in every environment tested (Linux, Linux without /proc, Windows)
my @ALMOST = qw(program pipeline devfd locale echo path-system path-var path-home path-dev path-mnt path-absent);
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
sub why { my ($r, $b) = @_; $b //= $CUR; $b->{r}{$r} = 1 if $b }
sub newblock { my ($text, $cx) = @_; my $b = { text => $text, cx => { %$cx }, r => {}, pos => ++$POS, errexit => $ERREXIT }; push @BLKS, $b; $b }
sub consume { my $b = shift; why('prog-status', $b) if $b->{sopaque} }   # this block's status decides something
sub safe_lit { my $w = shift; defined $w && !ref $w && $w !~ /[*?\[]/ }   # a literal word with no pattern characters
sub vassign { my ($n, $cx, $safe) = @_; return if ref $n || !defined $n;
  my $p = $cx->{infunc} || $cx->{late} ? -1 : $POS; $VSET{$n} = $p if !defined $VSET{$n} || $p < $VSET{$n};
  $VLIT{$n} = ($VLIT{$n} // 1) && $safe ? 1 : 0 }

# Words.  $mode: argv (split, then pathname expansion), assign (neither), redir, case (the word of a case), pattern
# (a case pattern, the word of ${x#...}), heredoc (as in double quotes).
sub word { my ($w, $cx, $mode) = @_; return unless defined $w;
  if (!ref $w) { why('locale') if $mode eq 'pattern' && $w =~ /[^\x00-\x7f]/; return }
  for my $p (@$w) { next unless ref $p; my ($k, @a) = @$p; my $q = $k =~ s/^"// || $mode ne 'argv';
    if ($k eq '*') { if ($mode eq 'argv') { why('files') } elsif ($mode eq 'pattern') { why('locale') if $a[0] =~ /\[|[^\x00-\x7f]/ } }
    elsif ($k eq '~') { why('tilde') }
    elsif ($k eq '$' || $k eq '${#') { var($a[0], $cx, $q || $k eq '${#') }
    elsif ($k eq '${') { var($a[0], $cx, $q); my $op = $a[1] // '';
      word($a[2], $cx, $op =~ /^[%#]/ ? 'pattern' : $q ? 'assign' : $mode) if defined $a[2];
      vassign($a[0], $cx, safe_lit($a[2])) if $op =~ /^:?=\z/ }
    elsif ($k eq '$((') { arith($a[0], $cx) }
    elsif ($k eq '$(') { why('unquoted') if !$q; walk_list($a[0], { %$cx, out => 'sub', tested => 0, bg => 0 }) }
    elsif ($k eq "'") { why('locale') if $mode eq 'pattern' && $a[0] =~ /[^\x00-\x7f]/ }
    elsif ($k eq '{' || $k eq '{..') { word($_, $cx, $mode) for grep ref, @a } } }
sub arith { my ($e, $cx) = @_;
  while ($e =~ /\$?\b([A-Za-z_]\w*)\b(?=\s*(?:<<|>>|[-+*\/%&^|])?=(?!=))|\$\{?([A-Za-z_]\w*|[0-9]+|[#?\$!@*-])\}?|\b([A-Za-z_]\w*)\b/g) {
    if (defined $1) { vassign($1, $cx, 1) } else { var($2 // $3, $cx, 1) } } }   # an arithmetic result is digits
sub var { my ($n, $cx, $quoted) = @_;
  if ($n eq '?') {   # the status of what ran before: unknown at the start of a function's body or a trap action
    if (!defined $LAST) { why('status') } else { consume($_) for @$LAST; $_->{q} = 1 for @LOOPS } }
  elsif ($n eq '-' || $n eq '0') { why('start') }
  elsif ($n =~ /^(?:\$|!|PPID)\z/) { why('pid') } elsif ($n eq 'SECONDS') { why('time') }
  elsif ($SHELLVAR{$n}) { }
  elsif ($n =~ /^(?:[1-9]\d*|[@*#])\z/) { push @DEFER, ['args', $n, $POS, $quoted || $n eq '#', $cx->{infunc}, $CUR] }
  else { push @DEFER, ['var', $n, $cx->{infunc} || $cx->{late} ? 1e9 : $POS, $quoted, $cx->{infunc}, $CUR] } }

# Redirections.
sub redir { my ($r, $cx) = @_; my ($fd, $op, $w) = @$r;
  if ($op =~ /^<</) { why('heredoc') if ref $w || length $w >= 4096; word($w, $cx, 'heredoc'); return }   # small: a pipe in all three
  if ($op =~ /&\z/) { if (ref $w) { word($w, $cx, 'redir'); why('fd') } elsif ($w ne '-' && $w > 2 && !$OPENFD{$w}) { why('fd') }
    $OPENFD{$fd} = 1 if $fd > 2; return }
  $OPENFD{$fd} = 1 if $fd > 2;
  if (ref $w) { word($w, $cx, 'redir'); why('files'); return }
  if ($w eq '/dev/null') { why('devnull'); return } if ($w =~ m{^/dev/(?:std(?:in|out|err)|fd/\d+)\z}) { why('devfd'); return }
  why('files'); if ($w =~ m{^/}) { my $p = pclass($w); why($p) if $p } }

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
      why('race') if $cx->{bg};
      if ($c->{in}) { word($_, $cx, 'argv') for @{$c->{in}}; vassign($c->{for}, $cx, !grep !safe_lit($_), @{$c->{in}}) }
      else { push @DEFER, ['args', '@', $POS, 1, $cx->{infunc}, $CUR]; vassign($c->{for}, $cx, 0) }
      loop(sub { walk_list($c->{do}, $cin) }) }
    elsif ($c->{case}) { my @x = @{$c->{in} // []}; $CUR = newblock('case ' . wtext($c->{case}) . ' in', $cx); why('race') if $cx->{bg};
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
  if (exists $c->{cd}) { why('directory'); word($c->{cd}, $cx, 'argv') if ref $c->{cd}; return }
  my @a = @{$c->{argv} // []}; return unless @a;
  word($_, $cx, 'argv') for @a;
  my $n = $a[0];
  while (!ref $n && ($n eq 'command' || $n eq 'exec') && @a > 1) {
    if ($n eq 'command' && !ref $a[1] && $a[1] =~ /^-[vV]/) { why('lookup'); return }
    shift @a; shift @a while @a > 1 && !ref $a[0] && $a[0] =~ /^-/; $n = $a[0] }
  if (ref $n) { why('name'); $CUR->{sopaque} = 1; consume($CUR) if $cx->{tested}; why('prog-output') if $cx->{out} eq 'sub'; return }
  my @op = @a[1 .. $#a];
  my $lit = !grep ref, @op;
  if ($n eq 'time') { why('time'); return }
  if ($n eq ':' || $n eq 'true' || $n eq 'false') { return }
  if ($n eq 'echo') { why('echo') if !$lit || grep(/\\/, @op) || (@op && $op[0] =~ /^-/); return }
  if ($n eq 'printf') { my @f = @op; splice @f, 0, ($f[0] eq '-v' ? 2 : 1) if @f && !ref $f[0] && $f[0] =~ /^-v/; shift @f if @f && !ref $f[0] && $f[0] eq '--';
    if (!@f || ref $f[0]) { why('locale') } else { my $f = $f[0];
      why('time') if $f =~ /%[-+ #0-9.*]*\(/; why('locale') if $f =~ /%[-+ #0-9.*']*'|%[-+ #0-9.*]*[feEgGaAq]/ }
    return }
  if ($n eq 'test' || $n eq '[') { my @t = @op; pop @t if $n eq '[' && @t && !ref $t[-1] && $t[-1] eq ']';
    for (grep !ref, @t) { why('files') if $FILEOPS{$_}; why('fd') if $_ eq '-t'; why('vars') if $_ eq '-v'; why('locale') if $_ eq '<' || $_ eq '>' }
    why('test-ops') if grep({ ref && unquoted($_) } @t) || (@t > 3 && grep ref, @t);
    return }
  if ($n eq 'read') { why('input') if $cx->{in} eq 'run'; vassign($_, $cx, 0) for grep { !ref && !/^-/ } @op; return }
  if ($n eq 'getopts') { vassign($op[1], $cx, 0) if @op > 1; vassign('OPTARG', $cx, 0);
    push @DEFER, ['args', '@', $POS, 1, $cx->{infunc}, $CUR] if @op < 3; return }
  if ($n eq 'set') { if (!@op) { why('listing'); return }
    my $i = 0; while ($i < @op && !ref $op[$i] && $op[$i] =~ /^[-+]/ && $op[$i] ne '--' && $op[$i] ne '-') {
      my $o = $op[$i]; why('fd') if $o =~ /^-\w*m/ || ($o eq '-o' && $i < $#op && !ref $op[$i + 1] && $op[$i + 1] eq 'monitor'); my $on = $o =~ /^-\w*e/ || ($o eq '-o' && $i < $#op && !ref $op[$i + 1] && $op[$i + 1] eq 'errexit');   # set -e: from here on
      my $off = $o =~ /^\+\w*e/ || ($o eq '+o' && $i < $#op && !ref $op[$i + 1] && $op[$i + 1] eq 'errexit');   #   every status decides
      if ($on) { $ERREXIT = $ANYERR = 1 } elsif ($off) { $ERREXIT = 0 }
      $i += $o =~ /^[-+]o\z/ ? 2 : 1 }
    $i++ if $i < @op && !ref $op[$i] && ($op[$i] eq '--' || $op[$i] eq '-');
    if ($i < @op || grep { !ref && $_ eq '--' } @op) { if (!$cx->{infunc}) { $ARGSET //= $POS } $ARGSLIT &&= !grep !safe_lit($_), @op[$i .. $#op] }
    return }
  if ($n eq 'shift') { push @DEFER, ['args', '@', $POS, 1, $cx->{infunc}, $CUR]; return }
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
  if ($n eq '.' || $n eq 'source') { why('files'); return }
  if ($n eq 'cd' || $n eq 'pwd') { why('directory'); return }
  if ($n =~ /^(?:wait|jobs|fg|bg|disown)\z/) { why('pid') if @op; return }
  if ($n eq 'kill') { why('pid') unless @op && !ref $op[0] && $op[0] =~ /^-[lL]/; return }
  if ($n eq 'times') { why('time'); return }
  if ($n eq 'hash' || $n eq 'type') { why('lookup'); return }
  if ($INTER{$n}) { why('interactive'); return }
  $FARGSOK &&= !grep !safe_lit($_), @op if $FDEF{$n};
  if ($FNOW{$n}) {
    $CUR->{sopaque} = 1 if opaque_status($n, {}); consume($CUR) if $cx->{tested};
    return }
  # an external program
  if ($n =~ /^(?:env|printenv)\z/ && !grep { ref || !/^-/ } @op) { why(q(listing)); return }   # they print the environment the shell passes
  if ($n =~ m{/}) { if ($n =~ m{^/}) { my $p = pclass($n); why($p) if $p } else { why('files') } }
  # programs known not to do the same in each run (a list of known cases, not complete): the assumption of "program" fails
  if ($n =~ /^(?:date|shuf|mktemp|uuidgen)\z/) { why($n eq 'date' ? 'time' : 'random') }
  if ($n eq 'sort' && grep { !ref && /^-(?:[a-zA-Z]*R|-random)/ } @op) { why('random') }
  if ($n eq 'stat' || ($n eq 'ls' && grep { !ref && /^-[a-zA-Z]*[ltcu]/ } @op)) { why('time') }   # each run's copy of the directory has new file times
  if ($n eq 'xargs') { my $arg = ''; for (@op) { if ($arg) { why('race') if $arg eq 'P' && (ref || $_ ne '1'); $arg = ''; next }
      last if ref || !/^-/; why('race') if /^-(?:\w*P(?!1\z).|-max-procs(?!=1\z))/; $arg = $1 if /^-\w*([ILnPsdEa])\z/ } }
  why('program'); $CUR->{sopaque} = 1;
  for (grep !ref, @op) { my $p = m{^(/[^\s]*)} ? $1 : m{=(/[^\s]*)} ? $1 : next; my $k = pclass($p); why($k) if $k }   # absolute paths given to it
  consume($CUR) if $cx->{tested}; why('prog-output') if $cx->{out} eq 'sub' }
sub unquoted { my $w = shift; grep { ref && $$_[0] =~ /^(?:\$|\$\{|\$\{#|\$\(|\*|~)\z/ } @$w }
sub opaque_status { my ($n, $seen) = @_; return 0 if $seen->{$n}++; my $any = 0; my @todo = ($FDEF{$n});   # may a call's status be a program's?
  while (@todo) { my $x = shift @todo;
    if (ref $x eq 'HASH') { if ($x->{argv} && @{$x->{argv}}) { my $m = name_of($x); $any = 1 if !defined $m || $m eq '' || $m =~ m{/} || (!$OWN{$m} && (!$FNOW{$m} || opaque_status($m, $seen))) }
      push @todo, values %$x } elsif (ref $x eq 'ARRAY') { push @todo, @$x } }
  $any }

# Each sample.
my (%B, %LV, %RS, %RSA, %RSONLY, %BYSRC, %SAMPLE); my $t0 = time;
for my $s (@S) {
  my $tree = Proc::ShellSubset::Large::parse($s->{text}, empty => 1); if (ref $tree ne q(ARRAY)) { warn "$s->{id}: rejected alone, skipped\n"; next }
  (%FDEF, %FNOW, @BLKS, %VSET, %VLIT, %OPENFD, @DEFER) = (); ($CUR, $POS, $ARGSET, $ARGSLIT, $FARGSOK) = (undef, 0, undef, 1, 1);
  { my @todo = ($tree); while (@todo) { my $x = shift @todo;   # the functions this text defines (3A: called by name anywhere)
      if (ref $x eq 'HASH') { $FDEF{$x->{func}} = $x->{body} if exists $x->{func}; push @todo, values %$x } elsif (ref $x eq 'ARRAY') { push @todo, @$x } } }
  ($LAST, @LOOPS, $ERREXIT, $ANYERR, $FINAL) = ([]);
  walk_list($tree, { out => 'run', in => 'run', tested => 0, bg => 0 });
  if ($ANYERR) { for my $b (@BLKS) { consume($b) if ($b->{errexit} || $b->{cx}{infunc} || $b->{cx}{late}) && !(defined $FINAL && $b == $FINAL) } }   # under set -e a failure stops the rest; the last command has no rest
  for my $d (@DEFER) { my ($k, $n, $p, $q, $infunc, $b) = @$d;
    if ($k eq 'var') { my $set = defined $VSET{$n} && $VSET{$n} < $p;
      if (!$set) { why('vars', $b) } elsif (!$q && !$VLIT{$n}) { why('unquoted', $b) } }
    elsif ($infunc) { why('unquoted', $b) if !$q && !$FARGSOK }
    elsif (!defined $ARGSET || $ARGSET >= $p) { why('args', $b) } elsif (!$q && !$ARGSLIT) { why('unquoted', $b) } }
  my %r; $r{$_} = 1 for map keys %{$_->{r}}, @BLKS;
  my $lv = 0; $lv = $LEVEL{$_} > $lv ? $LEVEL{$_} : $lv for keys %r;
  my @rs = grep $r{$_}, @HELD, @ALMOST, @UNDEC; my @here = grep $LEVEL{$_} == $lv, @rs;
  $SAMPLE{$s->{id}} = [$lv, \@rs, $s]; $LV{$lv}++; $BYSRC{$s->{src}}{$lv}++;
  if ($lv) { $RS{$lv}{$_}++ for @here; $RSONLY{$lv}{$here[0]}++ if @here == 1 }
  for my $b (@BLKS) { my $blv = 0; $blv = $LEVEL{$_} > $blv ? $LEVEL{$_} : $blv for keys %{$b->{r}};
    my $cx = $b->{cx}; my $ctx = join ',', grep $_, ($cx->{out} && $cx->{out} ne 'run' ? "out:$cx->{out}" : ''),
      ($cx->{in} && $cx->{in} ne 'run' ? "in:$cx->{in}" : ''), ($cx->{tested} ? 'tested' : ''), ($cx->{infunc} ? 'func' : ''), ($cx->{bg} ? 'bg' : '');
    my $e = $B{"$b->{text}\t$ctx"} //= { text => $b->{text}, ctx => $ctx, level => (qw(strict held almost undecided))[$blv],
      reasons => join(' ', grep $b->{r}{$_}, @HELD, @ALMOST, @UNDEC), n => 0, ids => [] };
    $e->{n}++; push @{$e->{ids}}, $s->{id} unless @{$e->{ids}} && $e->{ids}[-1] eq $s->{id} } }
printf STDERR "%d samples cut into blocks in %.1f s\n", scalar @S, time - $t0;

# Tables.
my @LN = qw(strict held almost undecided);
my $nb = 0; $nb += $_->{n} for values %B; my %bl; $bl{$_->{level}}++ for values %B;
printf "%d samples; %d blocks, %d distinct with their place: %s\n", scalar @S, $nb, scalar keys %B, join ', ', map "$_ $bl{$_}", grep $bl{$_}, @LN;
printf "\nSamples by level:\n"; printf "  %-10s %6d  %5.1f %%\n", $LN[$_], $LV{$_} // 0, 100 * ($LV{$_} // 0) / @S for 0 .. 3;
print "\nBy source (strict / held / almost / undecided):\n";
for (sort keys %BYSRC) { my $t = 0; $t += $_ for values %{$BYSRC{$_}}; my $src = $_; printf "  %-16s %6d: %6d %6d %6d %6d\n", $src, $t, map $BYSRC{$src}{$_} // 0, 0 .. 3 }
for my $lv (1, 2, 3) { print "\n$LN[$lv]: samples with each reason of that level / with that reason alone:\n";
  printf "  %-12s %6d %6d\n", $_, $RS{$lv}{$_} // 0, $RSONLY{$lv}{$_} // 0 for $lv == 1 ? @HELD : $lv == 2 ? @ALMOST : @UNDEC }
{ my %set; for (values %SAMPLE) { $set{join ' ', @{$_->[1]}}++ if $_->[0] == 1 || $_->[0] == 2 }
  print "\nheld and almost, by the set of assumptions a sample needs:\n"; printf "  %6d  %s\n", $set{$_}, $_ for sort { $set{$b} <=> $set{$a} || $a cmp $b } keys %set }
if ($OUTB) { open my $o, '>', $OUTB or die; print $o $J->encode($_), "\n" for sort { $b->{n} <=> $a->{n} || $a->{text} cmp $b->{text} } values %B }
if ($OUTS) { open my $o, '>:utf8', $OUTS or die; print $o "id\tlevel\treasons\ttext\n";
  for my $s (grep $SAMPLE{$_->{id}}, @S) { my ($lv, $rs) = @{$SAMPLE{$s->{id}}}; (my $x = $s->{text}) =~ s/\s*\n\s*/\\n/g; print $o join("\t", $s->{id}, $LN[$lv], "@$rs", $x), "\n" } }
if ($OUTE) { open my $o, '>:utf8', $OUTE or die; print $o <<'H';
# large-subset-provenance.tsv: every corpus sample the large parser accepts (40,410), one line each, by snippet ID.
# Columns (tab): ID CODE
#   ID    where the text comes from: format in doc/parsers/shell-subset-test-provenance.md, section 2; the texts are
#         remade from the pinned sources by doc/large-subset/tools/large-subset-extract.pl (doc/test-pools.md, 3).
#   CODE  known issue X27: could the run-time comparison of dash, bash --posix and ours (large-subset-state.md,
#         section 7) come out otherwise in another environment?
#           S                    strict: no; only how the shell is started is assumed
#           H:a,b                held: no, under assumptions known to hold in every environment tested (devnull, heredoc)
#           A:a,b                almost strict: no, if the assumptions a, b hold (program, pipeline, path-system, ...)
#           U:r,s/a,b            undecided: may depend on r, s (files, vars, prog-status, path-tmp, ...); the
#                                assumptions a, b would be needed besides
#         Every code, how to remake this file and the findings: doc/large-subset/large-subset-environment.md
H
  for my $id (sort keys %SAMPLE) { my ($lv, $rs) = @{$SAMPLE{$id}};
    my @u = grep $LEVEL{$_} == 3, @$rs; my @a = grep $LEVEL{$_} < 3, @$rs;
    print $o "$id\t", $lv == 0 ? 'S' : $lv < 3 ? ('', 'H', 'A')[$lv] . ':' . join(',', @a) : 'U:' . join(',', @u) . (@a ? '/' . join(',', @a) : ''), "\n" } }

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
