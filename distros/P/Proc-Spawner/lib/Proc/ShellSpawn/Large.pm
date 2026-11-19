package Proc::ShellSpawn::Large;
our $VERSION = '0.13';
# EXPERIMENTAL, awaiting approval: what Proc::ShellSpawn needs to run Proc::ShellSubset::Large trees
# (doc/large-subset/large-subset-spec.md, sections 4 and 5), as handlers named in Proc::ShellSpawn's tables:
#   x_NAME(CONTEXT, NODE, TAIL, K)         command nodes { func | export | readonly | local | exec => ... }
#   b_NAME(CONTEXT, ARGV, ENV, K, DATA)    builtins, and call() for functions
# Each calls K exactly once, or ends the shell (Proc::ShellSpawn::leave or Proc::ShellSpawn::fail), and never waits.
use strict; use warnings; use feature 'current_sub';
use POSIX ();
use Scalar::Util qw(weaken);
use Proc::ShellSpawn;

# JU3 (post-0.12, the user, 2026-11-15): the shell layer's functions are called through the alias ProcSS (Proc::ShellSpawn
# sets it), not imported; lines longer than 132 columns because of it stay unwrapped (the user's word, an exception to JQ1)

our $UNSUPPORTED = 248;   # A4: the status when something outside the subset shows up at run time (250 - 2: sh's syntax error
                          # status, moved out of the common range; doc/large-subset/large-subset-spec.md, section 5)
sub unsupported {   # A4: something outside the subset, found at run time
  my ($c, $what) = @_; ProcSS::put($c, 2, "Proc::ShellSubset::Large: $what is not supported\n", sub { ProcSS::leave($c, $UNSUPPORTED) }) }
sub parse_text {   # TEXT read by the run's own parser (@opt: its options): the tree; or, outside the subset, undef after
  my ($c, $text, $what, @opt) = @_;   # ending the shell (A4), $what naming the text in the message
  my $t = $c->{sh}{parse}->($text, @opt);
  ref $t eq 'ARRAY' ? $t : do { unsupported($c, $what); undef } }
sub aliases { my $al = $_[0]{sh}{alias}; %$al ? (aliases => { %$al }) : () }   # the parser's option: the aliases defined so far
sub run_text {   # eval, ., trap actions: parse with the large grammar and run in this shell
  my ($c, $text, $what, $k) = @_; my $sh = $c->{sh};
  my $t = parse_text($c, $text, $what, aliases($c), $what =~ /^the text of '\. / ? () : (nolineno => 1))   # $LINENO in eval
    // return;                                                                                         # or trap text: A4 (G8)
  return ProcSS::defer($k, 0) unless @$t;
  $sh->{intext}++; ProcSS::x_list($c, $t, undef, sub { $sh->{intext}--; $k->(@_) }) }   # alias in this text: B1, A4
sub b_unsupported { my ($c, $argv) = @_; unsupported($c, "'$argv->[0]'") }   # a builtin left to sh, named at run time
sub x_rest {   # P1 (post2-0.04): the rest of the text after a line with an alias definition known only when it ran: parsed now,
  # with the aliases defined by now, as both shells read a text one complete command at a time; a form outside the subset: A4
  my ($c, $x, $tail, $k) = @_; my $sh = $c->{sh};
  my $t = parse_text($c, $x->{rest}, "a command after an alias definition", aliases($c), lineoff => $x->{lineoff}) // return;
  return ProcSS::defer($k, $sh->{q}) unless @$t;
  ProcSS::x_list($c, $t, $tail, $k) }
sub b_late {   # 3A (post-0.04): a command whose name the text also defines as a function, which is not defined (yet):
  # parsed again from its expanded words, quoted, so that the builtin's own checks apply as they would have at parse time
  my ($c, $argv, $env, $k) = @_; my $q = sub { (my $w = shift) =~ s/'/'\\''/g; "'$w'" };
  my $text = join ' ', (map "$_=" . $q->($env->{$_}), sort keys %$env), map $q->($_), @$argv;
  my $t = parse_text($c, $text, "'$argv->[0]' in this form") // return;   # (no aliases: every word is quoted)
  ProcSS::x_list($c, $t, undef, $k) }

# ------------------------------------------------------------------ functions
sub x_func { my ($c, $x, $tail, $k) = @_; $c->{sh}{cmd}{$x->{func}} = ['Proc::ShellSpawn::Large::call', $x->{body}]; ProcSS::defer($k, 0) }
sub call {   # NAME ARGS...: the body in this shell, with its own positional parameters and frame
  my ($c, $argv, $env, $k, $body) = @_; my $sh = $c->{sh};
  my ($old, %saved) = $sh->{args};   # settings before the call: for its duration, exported (dash)
  for (sort keys %$env) { $saved{$_} = [exists $sh->{vars}{$_}, $sh->{vars}{$_}, $sh->{exp}{$_}];
                          ProcSS::setvar($c, $_, $env->{$_}) or return; $sh->{exp}{$_} = 1 }
  $sh->{args} = [@$argv[1 .. $#$argv]];
  my $saved = \%saved;
  my $ret = sub { my $st = shift; restore($sh, $saved); $sh->{args} = $old; ProcSS::defer($k, $st) };
  ProcSS::x_cmd({ %$c, loops => [], held => 0, frame => { saved => $saved, ret => $ret } }, $body, undef, $ret) }
sub restore {   # put back variables a function changed with local, or settings before its call
  my ($sh, $saved) = @_;
  for my $n (keys %$saved) { my ($had, $v, $exp) = @{delete $saved->{$n}};
    if ($had) { $sh->{vars}{$n} = $v } else { delete $sh->{vars}{$n} }
    if ($exp) { $sh->{exp}{$n} = 1 } else { delete $sh->{exp}{$n} } } }
sub b_return {
  my ($c, $argv, $env, $k) = @_; my $st = $argv->[1] // $c->{sh}{q};
  return ProcSS::fail($c, 2, "return: Illegal number: $st")   # NV1 (X42): known only at run time, as the shells
    if defined $argv->[1] && !ProcSS::ok_num($st, 0);
  $st += 0;
  my $fr = $c->{frame} or return $c->{sh}{intext} ? ProcSS::leave($c, $st)   # outside a function, in eval or . text: as exit
    : $c->{cond} ? ProcSS::msg($c, "return: can only `return' from a function or sourced script", ProcSS::done($k, 2))   # X48:
    : ProcSS::fail($c, 2, "return: can only `return' from a function or sourced script");   # tested (&&, ||, !, if,
    # while): status 2, the shell goes on; else the shell ends, status 2: both as bash --posix (rule E)
  ProcSS::release_ctx($c); ProcSS::release_all(map $_->{scope}, @{$c->{loops}}); $fr->{ret}->($st) }

# ------------------------------------------------------------------ declarations
sub declare {   # export, readonly, local: [NAME, Word or undef, ...]; $each->(NAME) after the value is set
  my ($c, $list, $k, $each, $what) = @_; my @l = @$list; my @pairs; push @pairs, [splice @l, 0, 2] while @l;
  my @log;   # NAME or NAME=VALUE as set, for $Proc::ShellSpawn::ONBUILTIN (measurement)
  ProcSS::each_async(\@pairs, sub { my ($p, $next) = @_; my ($n, $w) = @$p;
    my $set = sub { my $m = shift;   # the name is known: its value, if one is given, then $each
      return push(@log, $m), $each->($m), $next->() unless defined $w;
      ProcSS::expand_str($c, $w, sub { my $v = shift; push @log, "$m=$v"; ProcSS::setvar($c, $m, $v) or return; $each->($m); $next->() }) };
    return $set->($n) unless ref $n;
    ProcSS::expand_str($c, $n, sub { my $m = shift;   # export $v[=value] (parser item P4): the name known only now
      Proc::ShellSubset::settable($m) or return unsupported($c, "the name '$m' in 'export'");   # post-0.04:
        # the old test let every name pass
      $set->($m) }) },
    sub { $Proc::ShellSpawn::ONBUILTIN->("x_$what", [$what, @log], {}) if $what && $Proc::ShellSpawn::ONBUILTIN; ProcSS::defer($k, 0) }) }
sub x_export   { my ($c, $x, $tail, $k) = @_; declare($c, $x->{export}, $k, sub { $c->{sh}{exp}{$_[0]} = 1 }, 'export') }
sub x_readonly { my ($c, $x, $tail, $k) = @_; declare($c, $x->{readonly}, $k, sub { $c->{sh}{ro}{$_[0]} = 1 }, 'readonly') }
sub x_local {
  my ($c, $x, $tail, $k) = @_; my $fr = $c->{frame};
  return ProcSS::fail($c, 2, "local: not in a function") unless $fr;   # A5 (reached only dynamically)
  my $sh = $c->{sh}; my %l = @{$x->{local}};
  $fr->{saved}{$_} //= [exists $sh->{vars}{$_}, $sh->{vars}{$_}, $sh->{exp}{$_}] for keys %l;
  declare($c, $x->{local}, $k, sub {}, 'local') }

# ------------------------------------------------------------------ exec with redirections only: for the rest of the shell
sub x_exec {
  my ($c, $x, $tail, $k) = @_;
  ProcSS::redirect($c, $x->{redir} // [], sub {
    my ($m, $opened) = @_ or return ProcSS::leave($c, 2);   # a special builtin: a failed redirection ends the shell
    ProcSS::hold($_) for grep defined, values %$m; ProcSS::release($_) for @$opened;
    my $old = $c->{held} && !$c->{released} ? $c->{map} : {};
    $c->{map} = $m; ProcSS::release($_) for grep defined, values %$old;
    push @{$c->{shell}{scope}}, $c unless $c->{held};   # released when the shell ends
    @$c{qw(held released)} = (1, 0); ProcSS::defer($k, 0) }) }

# ------------------------------------------------------------------ builtins
sub b_shift {
  my ($c, $argv, $env, $k) = @_; my $n = $argv->[1] // 1; my $a = $c->{sh}{args};
  return ProcSS::fail($c, 2, "shift: Illegal number: $n") unless ProcSS::ok_num($n, 0);   # NV1 (X46): -1, x1 at run time
  $n += 0;
  return ProcSS::fail($c, 2, "shift: can't shift that many") if $n > @$a;
  splice @$a, 0, $n; ProcSS::defer($k, 0) }

my %OPT = (errexit => 'e', nounset => 'u', noglob => 'f', noclobber => 'C', allexport => 'a',
  notify => 'b', ignoreeof => 'ignoreeof', nolog => 'nolog');   # the last three, and +m, do nothing here (P6)
sub b_set {
  my ($c, $argv, $env, $k) = @_; my @a = @$argv[1 .. $#$argv]; my $o = $c->{sh}{opt}; my $ops;
  while (@a) {
    my $x = $a[0];
    if ($x eq '--') { shift @a; $ops = 1; last }
    last unless $x =~ /^([-+])(.+)/; shift @a; my ($on, $f) = ($1 eq '-', $2);
    return ProcSS::fail($c, 2, "set: Illegal option -o history")   # B2: as dash, when the caller asked for dash's interactive builtins
      if $f eq 'o' && ($a[0] // '') eq 'history' && $c->{sh}{interactive} eq 'dash';
    if ($f eq 'o') {   # NV1 (X43): a name known only at run time; none: it lists (A4, as the parser has it)
      return unsupported($c, "'set -o' without a name (it lists)") unless @a;
      my $n = shift @a;
      exists $OPT{$n} || $n =~ /^(?:vi|emacs|history)\z/ or return ProcSS::fail($c, 2, "set: Illegal option -o $n");
      my $l = $OPT{$n} // ''; $on ? ($o->{$l} = 1) : delete $o->{$l}; next }
    for my $l (split //, $f) { $l =~ /^[eufCab]\z/ || $l eq 'm' && !$on
        or return ProcSS::fail($c, 2, "set: Illegal option $1$l");
      $on ? ($o->{$l} = 1) : delete $o->{$l} } }
  $c->{sh}{args} = [@a] if $ops || @a;
  ProcSS::defer($k, 0) }

sub b_eval { my ($c, $argv, $env, $k) = @_; run_text($c, join(' ', @$argv[1 .. $#$argv]), "'eval' text", $k) }
sub b_dot {
  my ($c, $argv, $env, $k) = @_; my $f = $argv->[1] // '';
  my ($p) = ProcSS::has_dir($f) ? $f : grep -f ProcSS::path_in($c, $_), map +($_ eq '' ? '.' : $_) . "/$f",
    ProcSS::path_list(ProcSS::var($c, 'PATH'));
  $p = ProcSS::path_in($c, $p) if defined $p;
  open my $fh, '<', $p // '' or return ProcSS::fail($c, 2, ".: cannot open $f: No such file");
  my $text = do { local $/; <$fh> } // '';   # (X39: in list context an empty file, or a directory, gave no argument at all)
  run_text($c, $text, "the text of '. $f'", $k) }

our %SIGNUM; *SIGNUM = \%Proc::Spawner::SIGNUM;   # signal names => numbers: Proc::Spawner's table (JH3, part e)
my %SIGNAME = (%Proc::Spawner::SIGNAME, 0 => 'EXIT');   # numbers => names: its table too, and 0 as the shells have it
sub b_trap {   # names in any case, or numbers (P6); KILL and STOP cannot be caught: nothing to do, status 0, as both shells
  my ($c, $argv, $env, $k) = @_; my ($act, @sigs) = @$argv[1 .. $#$argv]; my $sh = $c->{sh};
  for my $s (map /^[0-9]+\z/ ? $SIGNAME{$_} // $_ : uc, @sigs) {
    next if $s eq 'KILL' || $s eq 'STOP';
    next if $Proc::ShellSpawn::IGN0{$s};   # X49: ignored on entry: cannot be trapped or reset (POSIX; both shells)
    if ($act eq '-') { delete $sh->{trap}{$s} } else { $sh->{trap}{$s} = $act }
    next if $s eq 'EXIT';
    next if $sh->{main};   # X51: a subshell runs in this process; a signal sent to it ($$, the group) is the main shell's,
                           #   as in dash, where the subshell is another process (its trap: recorded, for 'trap' and its programs)
    my $w = $c; weaken $w;
    my $h = $sh->{tsub}{$s} = sub { return unless $w; push @{$w->{sh}{pend}}, $s };   # X51: run by the list, before its
                           #   next command (X19): after the foreground command, as POSIX and both shells
    next unless exists $SIGNUM{$s};   # a signal Perl does not have here (Windows: USR1, ...): only kill ... $$ sends it
    $Proc::ShellSpawn::TRAPSAVE{$s} //= $SIG{$s} // 'DEFAULT';
    $SIG{$s} = $act eq '-' ? $Proc::ShellSpawn::TRAPSAVE{$s} : $act eq '' ? 'IGNORE' : $h }   # queued: the action runs before the
  # main shell's next command (X19: as dash, before what follows the command; X51: not while the command still runs)
  ProcSS::defer($k, 0) }
sub run_pending {   # the actions of the signals caught since the last time, in order; then $k (and every other waiter)
  my ($c, $k) = @_; my $sh = $c->{sh};
  push @{$sh->{twait}}, $k if $k; return if $sh->{tbusy}; $sh->{tbusy} = 1;
  sub { my $p = $sh->{pend};
    return run_trap($c, shift @$p, __SUB__) if $p && @$p;
    $sh->{tbusy} = 0; my @w = @{$sh->{twait} // []}; $sh->{twait} = []; $_->() for @w }->() }
sub run_trap {   # a trap's action; $? is kept
  my ($c, $s, $k) = @_; my $a = $c->{sh}{trap}{$s}; my $q = $c->{sh}{q};
  return $k && $k->(0) unless defined $a && $a ne '';
  run_text({ %$c, loops => [], held => 0, intrap => 1 }, $a, "the action of 'trap'", sub { $c->{sh}{q} = $q; $k->(0) if $k }) }

sub b_wait {
  my ($c, $argv, $env, $k) = @_; my @pid = @$argv[1 .. $#$argv]; my @j = @{$c->{sh}{jobl}};
  if (@pid) {
    my $p = $pid[-1]; my ($j) = grep +($_->{first} // '') eq $p, @j;
    return ProcSS::defer($k, 127) unless $j;
    return ProcSS::defer($k, $j->{st}) if defined $j->{st};
    return push @{$j->{waiters}}, sub { ProcSS::defer($k, $j->{st}) } }
  my @left = grep !defined $_->{st}, @j; my $n = @left;
  return ProcSS::defer($k, 0) unless $n;
  push @{$_->{waiters}}, sub { ProcSS::defer($k, 0) unless --$n } for @left }

sub b_umask {
  my ($c, $argv, $env, $k) = @_;
  return ProcSS::put($c, 1, sprintf("%04o\n", $c->{sh}{umask}), ProcSS::done($k, 0)) unless defined(my $m = $argv->[1]);
  if ($m eq '-S') {   # umask -S (parser item P4): u=rwx,g=rx,o=rx
    my $u = $c->{sh}{umask};
    my @w = map { my $b = 7 & ~($u >> $_); join '', grep $b & {r => 4, w => 2, x => 1}->{$_}, qw(r w x) } 6, 3, 0;
    return ProcSS::put($c, 1, "u=$w[0],g=$w[1],o=$w[2]\n", ProcSS::done($k, 0)) }
  if ($m =~ /^[ugoa]*[-+=]/) {   # symbolic, as both shells (post4-0.03): on the permissions the mask leaves
    my $p = ~$c->{sh}{umask} & 0777;
    for (split /,/, $m) { my ($who, $op, $perm) = /^([ugoa]*)([-+=])([rwx]*)\z/;
      my $w = 0; $w |= { u => 0700, g => 070, o => 07, a => 0777 }->{$_} for split //, $who || 'a';
      my $b = 0; $b |= { r => 0444, w => 0222, x => 0111 }->{$_} for split //, $perm; $b &= $w;
      $p = $op eq '+' ? $p | $b : $op eq '-' ? $p & ~$b : ($p & ~$w) | $b }
    $c->{sh}{umask} = ~$p & 0777; return ProcSS::defer($k, 0) }
  $c->{sh}{umask} = oct $m; ProcSS::defer($k, 0) }

our $DEFPATH = '/usr/bin:/bin';   # command -p: bash's (glibc confstr _CS_PATH, in its order); dash adds /usr/sbin:/sbin
my %ASPROG = map +($_ => 1), qw(echo printf test [ kill true false pwd cd);   # command -v prints the name (spec, section 5)
sub b_pwd {   # X23 (the user's choice C, post2-0.03): the program, as '/bin/pwd -L', with PWD set to the shell's own
  # directory, so that it prints what both shells print (the directory as reached, also through symbolic links);
  # operands are dropped, as both shells ignore them (the program would warn); options as given, the last counts
  my ($c, $argv, $env, $k) = @_; my (undef, @a) = @$argv; my @o;
  while (@a && $a[0] =~ /^-/) { my $o = shift @a; last if $o eq '--'; push @o, $o }
  ProcSS::spawn($c, $c->{map}, ['pwd', '-L', @o], { %$env, PWD => $c->{sh}{cwd} }, $k) }
sub b_test {   # rule F (post3-0.04): 's1 < s2', 's1 > s2' (also after '!'), which the program refuses, compared here by
  # bytes, as both shells (POSIX 2024: "collates before/after ... in the current locale"; the same in the C locale);
  # every other form: the program, as before (P5)
  my ($c, $argv, $env, $k) = @_; my ($n, @a) = @$argv;
  if ($n eq '[') { return ProcSS::spawn($c, $c->{map}, $argv, $env, $k) unless @a && $a[-1] eq ']'; pop @a }
  my $not = @a == 4 && $a[0] eq '!' and shift @a;
  return ProcSS::spawn($c, $c->{map}, $argv, $env, $k) unless @a == 3 && $a[1] =~ /^[<>]\z/;
  my $r = $a[1] eq '<' ? $a[0] lt $a[2] : $a[0] gt $a[2]; $r = !$r if $not;
  ProcSS::defer($k, $r ? 0 : 1) }
sub b_command {
  my ($c, $argv, $env, $k) = @_; my (undef, @a) = @$argv;
  if (($a[0] // '') eq '-v') {
    return unsupported($c, "'command -v' with " . (@a - 1) . " names") if @a != 2;   # X53: as the parser (one name)
    my $n = $a[1] // ''; my $sh = $c->{sh};
    return ProcSS::put($c, 1, "$n\n", ProcSS::done($k, 0))
      if $sh->{cmd}{$n} || (ProcSS::cmd_of($n) // ['unsupported'])->[0] !~ /unsupported/
        || $Proc::ShellSpawn::SPECIAL{$n} || $ASPROG{$n} || $Proc::ShellSubset::BI{$n};
    my ($p) = ProcSS::find_cmd($c, $n, ProcSS::var($c, 'PATH'));
    $p //= $n if $Proc::ShellSpawn::INPROC{$n};   # run inside this process, no file (Windows): its name, as for a builtin
    return ProcSS::defer($k, 127) unless defined $p;
    return ProcSS::put($c, 1, "$p\n", ProcSS::done($k, 0)) }
  return ProcSS::defer($k, 0) unless @a;
  # X53: the forms the parser refuses (another option, -v with more than one name, -p with an option after it), when
  # only expansions make them: outside the subset at run time (A4), not a program named -n
  return unsupported($c, "'command " . ($a[0] eq '-p' ? "-p $a[1]" : $a[0]) . "'")
    if $a[0] =~ /^-/ && $a[0] ne '-p' || $a[0] eq '-p' && ($a[1] // '') =~ /^-/;
  if ($a[0] eq '-p') {   # command -p PROGRAM ... (parser item P4): looked up in a default PATH, run with the PATH it has
    shift @a; return (ProcSS::cmd_of($a[0]) // [''])->[0] !~ /b_test\z|^\z/ || $c->{sh}{cmd}{$a[0]}
      ? unsupported($c, "'command -p $a[0]'")
      : ProcSS::spawn($c, $c->{map}, \@a, $env, $k, $DEFPATH) }
  return b_late($c, \@a, $env, $k) if $Proc::ShellSubset::REGBI{$a[0]};   # a builtin, not a function: its checks, then it (3A)
  if (my $e = ProcSS::cmd_of($a[0])) { return ProcSS::handler($e->[0])->($c, \@a, $env, $k, $e->[1]) }   # a builtin,
    # not a function
  ProcSS::spawn($c, $c->{map}, \@a, $env, $k) }

sub b_getopts {   # OPTSTRING NAME [ARGS]: as dash, also OPTIND inside grouped options (A5)
  my ($c, $argv, $env, $k) = @_; my (undef, $os, $name, @a) = @$argv; my $sh = $c->{sh};
  @a = @{$sh->{args}} unless @$argv > 3;
  my $silent = $os =~ s/^://;
  my $ind = ProcSS::var($c, 'OPTIND'); $ind = 1 if $ind !~ /^[1-9][0-9]*\z/;
  my $off = ($sh->{optlast} // 0) eq $ind ? $sh->{optoff} // 0 : 0;
  $ind = 1, $off = 0 if $ind > @a + 1;   # past the end of these arguments: dash starts over (L7)
  my $set = sub { my ($v, $st, @arg) = @_;   # @arg undef: OPTARG unset (rule E: POSIX, as bash; dash keeps it, L8)
    ProcSS::setvar($c, $name, $v) && ProcSS::setvar($c, OPTIND => $ind) or return;
    !@arg ? () : defined $arg[0] ? ProcSS::setvar($c, OPTARG => $arg[0]) || return : delete $sh->{vars}{OPTARG};
    @$sh{qw(optlast optoff)} = ($ind, $off); ProcSS::defer($k, $st) };
  my $cur;
  if ($off) { $cur = $a[$ind - 2] }
  else {
    $cur = $a[$ind - 1];
    return $set->('?', 1, undef) if !defined $cur || $cur !~ /^-./;
    $ind++; return $set->('?', 1, undef) if $cur eq '--';
    $off = 1 }
  my $ch = substr $cur, $off++, 1; my $last = $off >= length $cur; $off = 0 if $last;
  my $i = index $os, $ch;
  if ($ch eq ':' or $i < 0) {
    return $silent ? $set->('?', 0, $ch) : ProcSS::msg($c, "Illegal option -$ch", sub { $set->('?', 0, undef) }) }
  return $set->($ch, 0, undef) unless substr($os, $i + 1, 1) eq ':';   # POSIX: OPTARG unset (rule E; dash: empty)
  unless ($last) { my $arg = substr $cur, $off; $off = 0; return $set->($ch, 0, $arg) }
  return $set->($ch, 0, $a[$ind++ - 1]) if defined $a[$ind - 1];
  $silent ? $set->(':', 0, $ch) : ProcSS::msg($c, "No arg for -$ch option", sub { $set->('?', 0, undef) }) }

sub b_unset {
  my ($c, $argv, $env, $k) = @_; my (undef, @n) = @$argv; my $sh = $c->{sh};
  my $f = ($n[0] // '') =~ /^-([vf])\z/ && (shift @n, $1)[1] // 'v';
  for (@n) {
    if ($f eq 'f') { delete $sh->{cmd}{$_}; next }
    # X35 (the user, 2026-11-08: as dash): a word that is not a name, from an expansion (a literal one the parser
    # rejects), stops the shell with status 2, as any error of a special builtin; the names before it are already unset
    return ProcSS::fail($c, 2, "unset: $_: bad variable name") unless /^[A-Za-z_][A-Za-z0-9_]*\z/;
    return ProcSS::fail($c, 2, "unset: $_: is read only") if $sh->{ro}{$_};
    delete $sh->{vars}{$_}; delete $sh->{exp}{$_} }
  ProcSS::defer($k, 0) }

sub b_kill {   # kill ... $$: the shell takes the signal itself (F9); every other form goes to the program kill
  my ($c, $argv, $env, $k) = @_; my (undef, @a) = @$argv; my $sh = $c->{sh};
  # JH4, part c (the user, 2026-11-14: way A, provisionally; X63): the options are read once: -s NAME, or one word of a
  # dash with letters and digits that does not start with -l; then a '--'.  $s: the signal; @ids: the process IDs
  my ($s, @ids) = ('TERM', @a);
  if (@ids && $ids[0] eq '-s') { shift @ids; $s = shift @ids }
  elsif (@ids && $ids[0] =~ /^-([0-9A-Za-z]+)\z/ && $ids[0] !~ /^-l/) { $s = $1; shift @ids }
  my $dd = @ids && $ids[0] eq '--' ? shift @ids : undef;
  # K0 (the user, 2026-11-05): a signal (-N, -NAME, -s NAME), maybe '--', and no process ID: as both shells, status 2,
  # with dash's text (the program kill: status 1, a long usage text).  'kill -s' alone: the program
  return ProcSS::msg($c, "kill: Usage: kill [-s sigspec | -signum | -sigspec] [pid | job]... or\nkill -l [exitstatus]", ProcSS::done($k, 2))
    if !@ids && "@a" ne '-s';
  if (defined $s) { $s = $SIGNAME{$s} // $s if $s =~ /^[0-9]+\z/; $s =~ s/^SIG// }
  # The shell takes the signal itself only when the signal is one that exists (0 is EXIT here), every word left is a
  # number (a process ID, or a group's with '-') and $$ is among them.  Every other form goes to the program kill as
  # written: it refuses what is no signal or no process ID, and the shell goes on
  return ProcSS::spawn($c, $c->{map}, $argv, $env, $k)
    unless defined $s && ($s eq 'EXIT' || $SIGNUM{$s}) && !grep(!/^-?[0-9]+\z/, @ids) && grep $_ eq $sh->{pid}, @ids;
  my $harmless = $s =~ /^(?:CHLD|CLD|URG|WINCH|CONT)\z/;   # post4-0.04: by default these do nothing to the shell (0 is EXIT here)
  my @other = grep $_ ne $sh->{pid}, @ids;
  my $m = $sh->{main} // $sh;   # $$ is the main shell, also in a subshell: its trap counts (L6)
  my $self = sub {
    my $t = $m->{trap}{$s};
    return ProcSS::defer($k, 0) if $s eq 'EXIT' || $harmless && !defined $t;   # kill -0 $$ only tests; as both shells, status 0
    return ProcSS::defer($k, 0) if defined $t && $t eq '';            # ignored
    return ProcSS::defer($k, 0) if $Proc::ShellSpawn::IGN0{$s};       # X49: ignored on entry, so no trap: nothing, as both shells
    return run_trap($c, $s, sub { ProcSS::defer($k, 0) }) if defined $t && $m == $sh;
    if (defined $t) { my $h = $m->{tsub}{$s}; $h->($s) if $h; return ProcSS::defer($k, 0) }   # as a real signal:
                                                                                      # the trap runs in the main shell
    $m->{trap}{EXIT} = '' if exists $m->{trap}{EXIT};         # a death by the signal runs no EXIT trap
    $Proc::ShellSpawn::SIGNALLED = $s;                                 # the caller may die by it too (try.pl does)
    $sh->{die}->(128 + ($SIGNUM{$s} // 15)) };                 # the whole string ends, as sh -c would
  return $self->() unless @other;
  ProcSS::spawn($c, $c->{map}, ['kill', "-$s", (defined $dd ? '--' : ()), @other], $env, sub { $self->() }) }

1;
