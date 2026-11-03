package Proc::ShellSpawn::Large;
our $VERSION = '0.02';
# EXPERIMENTAL, awaiting approval: what Proc::ShellSpawn needs to run Proc::ShellSubset::Large trees
# (doc/large-subset/large-subset-spec.md, sections 4 and 5), as handlers named in Proc::ShellSpawn's tables:
#   x_NAME(CONTEXT, NODE, TAIL, K)         command nodes { func | export | readonly | local | exec => ... }
#   b_NAME(CONTEXT, ARGV, ENV, K, DATA)    builtins, and call() for functions
# Each calls K exactly once, or ends the shell (Proc::ShellSpawn::leave or Proc::ShellSpawn::fail), and never waits.
use strict; use warnings; use feature 'current_sub';
use POSIX ();
use Scalar::Util qw(weaken);
use Config ();
use Proc::ShellSpawn;

BEGIN { no strict 'refs'; *$_ = \&{"Proc::ShellSpawn::$_"} for qw(defer leave fail msg put var setvar expand_str each_async x_list x_cmd
                                          redirect hold release release_ctx release_all find_cmd spawn handler) }

our $UNSUPPORTED = 248;   # A4: the status when something outside the subset shows up at run time (250 - 2: sh's syntax error status, moved out of the common range; doc/large-subset/large-subset-spec.md, section 5)
sub unsupported {   # A4: something outside the subset, found at run time
  my ($c, $what) = @_; put($c, 2, "Proc::ShellSubset::Large: $what is not supported\n", sub { leave($c, $UNSUPPORTED) }) }
sub run_text {   # eval, ., trap actions: parse with the large grammar and run in this shell
  my ($c, $text, $what, $k) = @_;
  my $t = $c->{sh}{parse}->($text); return unsupported($c, $what) if ref $t ne 'ARRAY';   # the run's own parser
  @$t ? x_list($c, $t, undef, $k) : defer($k, 0) }
sub b_unsupported { my ($c, $argv) = @_; unsupported($c, "'$argv->[0]'") }   # a builtin left to sh, named at run time

# ------------------------------------------------------------------ functions
sub x_func { my ($c, $x, $tail, $k) = @_; $c->{sh}{cmd}{$x->{func}} = ['Proc::ShellSpawn::Large::call', $x->{body}]; defer($k, 0) }
sub call {   # NAME ARGS...: the body in this shell, with its own positional parameters and frame
  my ($c, $argv, $env, $k, $body) = @_; my $sh = $c->{sh};
  my ($old, %saved) = $sh->{args};   # settings before the call: for its duration, exported (dash)
  for (sort keys %$env) { $saved{$_} = [exists $sh->{vars}{$_}, $sh->{vars}{$_}, $sh->{exp}{$_}];
                          setvar($c, $_, $env->{$_}) or return; $sh->{exp}{$_} = 1 }
  $sh->{args} = [@$argv[1 .. $#$argv]];
  my $saved = \%saved;
  my $ret = sub { my $st = shift; restore($sh, $saved); $sh->{args} = $old; defer($k, $st) };
  x_cmd({ %$c, loops => [], held => 0, frame => { saved => $saved, ret => $ret } }, $body, undef, $ret) }
sub restore {   # put back variables a function changed with local, or settings before its call
  my ($sh, $saved) = @_;
  for my $n (keys %$saved) { my ($had, $v, $exp) = @{delete $saved->{$n}};
    if ($had) { $sh->{vars}{$n} = $v } else { delete $sh->{vars}{$n} }
    if ($exp) { $sh->{exp}{$n} = 1 } else { delete $sh->{exp}{$n} } } }
sub b_return {
  my ($c, $argv) = @_; my $st = $argv->[1] // $c->{sh}{q};
  my $fr = $c->{frame} or return leave($c, $st);   # outside a function (reached through eval): as exit
  release_ctx($c); release_all(map $_->{scope}, @{$c->{loops}}); $fr->{ret}->($st) }

# ------------------------------------------------------------------ declarations
sub declare {   # export, readonly, local: [NAME, Word or undef, ...]; $each->(NAME) after the value is set
  my ($c, $list, $k, $each) = @_; my @l = @$list; my @pairs; push @pairs, [splice @l, 0, 2] while @l;
  each_async(\@pairs, sub { my ($p, $next) = @_; my ($n, $w) = @$p;
    return $each->($n), $next->() unless defined $w;
    expand_str($c, $w, sub { setvar($c, $n, shift) or return; $each->($n); $next->() }) }, sub { defer($k, 0) }) }
sub x_export   { my ($c, $x, $tail, $k) = @_; declare($c, $x->{export}, $k, sub { $c->{sh}{exp}{$_[0]} = 1 }) }
sub x_readonly { my ($c, $x, $tail, $k) = @_; declare($c, $x->{readonly}, $k, sub { $c->{sh}{ro}{$_[0]} = 1 }) }
sub x_local {
  my ($c, $x, $tail, $k) = @_; my $fr = $c->{frame};
  return fail($c, 2, "local: not in a function") unless $fr;   # A5 (reached only dynamically)
  my $sh = $c->{sh}; my %l = @{$x->{local}};
  $fr->{saved}{$_} //= [exists $sh->{vars}{$_}, $sh->{vars}{$_}, $sh->{exp}{$_}] for keys %l;
  declare($c, $x->{local}, $k, sub {}) }

# ------------------------------------------------------------------ exec with redirections only: for the rest of the shell
sub x_exec {
  my ($c, $x, $tail, $k) = @_;
  redirect($c, $x->{redir} // [], sub {
    my ($m, $opened) = @_ or return leave($c, 2);   # a special builtin: a failed redirection ends the shell
    hold($_) for grep defined, values %$m; release($_) for @$opened;
    my $old = $c->{held} && !$c->{released} ? $c->{map} : {};
    $c->{map} = $m; release($_) for grep defined, values %$old;
    push @{$c->{shell}{scope}}, $c unless $c->{held};   # released when the shell ends
    @$c{qw(held released)} = (1, 0); defer($k, 0) }) }

# ------------------------------------------------------------------ builtins
sub b_shift {
  my ($c, $argv, $env, $k) = @_; my $n = $argv->[1] // 1; my $a = $c->{sh}{args};
  return fail($c, 2, "shift: can't shift that many") if $n > @$a;
  splice @$a, 0, $n; defer($k, 0) }

my %OPT = (errexit => 'e', nounset => 'u', noglob => 'f', noclobber => 'C', allexport => 'a');
sub b_set {
  my ($c, $argv, $env, $k) = @_; my @a = @$argv[1 .. $#$argv]; my $o = $c->{sh}{opt}; my $ops;
  while (@a) {
    my $x = $a[0];
    if ($x eq '--') { shift @a; $ops = 1; last }
    last unless $x =~ /^([-+])(.+)/; shift @a; my ($on, $f) = ($1 eq '-', $2);
    for my $l ($f eq 'o' ? $OPT{shift @a // ''} // '' : split //, $f) { $on ? ($o->{$l} = 1) : delete $o->{$l} } }
  $c->{sh}{args} = [@a] if $ops || @a;
  defer($k, 0) }

sub b_eval { my ($c, $argv, $env, $k) = @_; run_text($c, join(' ', @$argv[1 .. $#$argv]), "'eval' text", $k) }
sub b_dot {
  my ($c, $argv, $env, $k) = @_; my $f = $argv->[1] // '';
  my ($p) = $f =~ m{/} ? $f : grep -f, map +($_ eq '' ? '.' : $_) . "/$f", split /:/, var($c, 'PATH'), -1;
  $p = "$c->{sh}{cwd}/$p" if defined $p && $p !~ m{^/};
  open my $fh, '<', $p // '' or return fail($c, 2, ".: cannot open $f: No such file");
  run_text($c, do { local $/; <$fh> }, "the text of '. $f'", $k) }

my %SIGNAME = (0 => 'EXIT', 1 => 'HUP', 2 => 'INT', 3 => 'QUIT', 6 => 'ABRT', 13 => 'PIPE', 14 => 'ALRM', 15 => 'TERM');
sub b_trap {
  my ($c, $argv, $env, $k) = @_; my ($act, @sigs) = @$argv[1 .. $#$argv]; my $sh = $c->{sh};
  for my $s (map $SIGNAME{$_} // $_, @sigs) {
    if ($act eq '-') { delete $sh->{trap}{$s} } else { $sh->{trap}{$s} = $act }
    next if $s eq 'EXIT';
    $Proc::ShellSpawn::TRAPSAVE{$s} //= $SIG{$s} // 'DEFAULT';
    my $w = $c; weaken $w;
    $SIG{$s} = $act eq '-' ? $Proc::ShellSpawn::TRAPSAVE{$s} : $act eq '' ? 'IGNORE'
      : sub { defer(\&run_trap, $w, $s) if $w } }   # deferred: the action runs between two reactions
  defer($k, 0) }
sub run_trap {   # a trap's action; $? is kept
  my ($c, $s, $k) = @_; my $a = $c->{sh}{trap}{$s}; my $q = $c->{sh}{q};
  return $k && $k->(0) unless defined $a && $a ne '';
  run_text({ %$c, loops => [], held => 0 }, $a, "the action of 'trap'", sub { $c->{sh}{q} = $q; $k->(0) if $k }) }

sub b_wait {
  my ($c, $argv, $env, $k) = @_; my @pid = @$argv[1 .. $#$argv]; my @j = @{$c->{sh}{jobl}};
  if (@pid) {
    my $p = $pid[-1]; my ($j) = grep +($_->{first} // '') eq $p, @j;
    return defer($k, 127) unless $j;
    return defer($k, $j->{st}) if defined $j->{st};
    return push @{$j->{waiters}}, sub { defer($k, $j->{st}) } }
  my @left = grep !defined $_->{st}, @j; my $n = @left;
  return defer($k, 0) unless $n;
  push @{$_->{waiters}}, sub { defer($k, 0) unless --$n } for @left }

sub b_umask {
  my ($c, $argv, $env, $k) = @_;
  return put($c, 1, sprintf("%04o\n", $c->{sh}{umask}), sub { $k->(0) }) unless defined(my $m = $argv->[1]);
  $c->{sh}{umask} = oct $m; defer($k, 0) }

my %ASPROG = map +($_ => 1), qw(echo printf test [ kill true false pwd cd);   # command -v prints the name (spec, section 5)
sub b_command {
  my ($c, $argv, $env, $k) = @_; my (undef, @a) = @$argv;
  if (($a[0] // '') eq '-v') {
    my $n = $a[1] // ''; my $sh = $c->{sh};
    return put($c, 1, "$n\n", sub { $k->(0) })
      if $sh->{cmd}{$n} || $Proc::ShellSpawn::CMD{$n} && $Proc::ShellSpawn::CMD{$n}[0] !~ /unsupported/ || $Proc::ShellSpawn::SPECIAL{$n} || $ASPROG{$n} || $Proc::ShellSubset::BI{$n};
    my ($p) = find_cmd($c, $n, var($c, 'PATH')); return defer($k, 127) unless defined $p;
    return put($c, 1, "$p\n", sub { $k->(0) }) }
  return defer($k, 0) unless @a;
  if (my $e = $Proc::ShellSpawn::CMD{$a[0]}) { return handler($e->[0])->($c, \@a, $env, $k, $e->[1]) }   # a builtin, not a function
  spawn($c, $c->{map}, \@a, $env, $k) }

sub b_getopts {   # OPTSTRING NAME [ARGS]: as dash, also OPTIND inside grouped options (A5)
  my ($c, $argv, $env, $k) = @_; my (undef, $os, $name, @a) = @$argv; my $sh = $c->{sh};
  @a = @{$sh->{args}} unless @$argv > 3;
  my $silent = $os =~ s/^://;
  my $ind = var($c, 'OPTIND'); $ind = 1 if $ind !~ /^[1-9][0-9]*\z/;
  my $off = ($sh->{optlast} // 0) eq $ind ? $sh->{optoff} // 0 : 0;
  $ind = 1, $off = 0 if $ind > @a + 1;   # past the end of these arguments: dash starts over (L7)
  my $set = sub { my ($v, $st, @arg) = @_;   # no @arg: OPTARG stays as it was (dash, L8)
    setvar($c, $name, $v) && setvar($c, OPTIND => $ind) or return;
    !@arg ? () : defined $arg[0] ? setvar($c, OPTARG => $arg[0]) || return : delete $sh->{vars}{OPTARG};
    @$sh{qw(optlast optoff)} = ($ind, $off); defer($k, $st) };
  my $cur;
  if ($off) { $cur = $a[$ind - 2] }
  else {
    $cur = $a[$ind - 1];
    return $set->('?', 1) if !defined $cur || $cur !~ /^-./;
    $ind++; return $set->('?', 1) if $cur eq '--';
    $off = 1 }
  my $ch = substr $cur, $off++, 1; my $last = $off >= length $cur; $off = 0 if $last;
  my $i = index $os, $ch;
  if ($ch eq ':' or $i < 0) {
    return $silent ? $set->('?', 0, $ch) : msg($c, "Illegal option -$ch", sub { $set->('?', 0, undef) }) }
  return $set->($ch, 0, '') unless substr($os, $i + 1, 1) eq ':';   # dash: OPTARG empty
  unless ($last) { my $arg = substr $cur, $off; $off = 0; return $set->($ch, 0, $arg) }
  return $set->($ch, 0, $a[$ind++ - 1]) if defined $a[$ind - 1];
  $silent ? $set->(':', 0, $ch) : msg($c, "No arg for -$ch option", sub { $set->('?', 0, undef) }) }

sub b_unset {
  my ($c, $argv, $env, $k) = @_; my (undef, @n) = @$argv; my $sh = $c->{sh};
  my $f = ($n[0] // '') =~ /^-([vf])\z/ && (shift @n, $1)[1] // 'v';
  for (@n) {
    if ($f eq 'f') { delete $sh->{cmd}{$_}; next }
    return fail($c, 2, "unset: $_: is read only") if $sh->{ro}{$_};
    delete $sh->{vars}{$_}; delete $sh->{exp}{$_} }
  defer($k, 0) }

my %SIGNUM; @SIGNUM{split ' ', $Config::Config{sig_name}} = split ' ', $Config::Config{sig_num};
sub b_kill {   # kill ... $$: the shell takes the signal itself (F9); other process IDs go to the program kill
  my ($c, $argv, $env, $k) = @_; my (undef, @a) = @$argv; my $sh = $c->{sh};
  return spawn($c, $c->{map}, $argv, $env, $k) unless grep $_ eq $sh->{pid}, @a;
  my $s = 'TERM';
  if (@a && $a[0] =~ /^-(?:s)?\z/ && @a > 1) { shift @a; $s = shift @a }
  elsif (@a && $a[0] =~ /^-(\w+)\z/) { shift @a; $s = $1 }
  $s = $SIGNAME{$s} // $s if $s =~ /^[0-9]+\z/; $s =~ s/^SIG//;
  my @other = grep $_ ne $sh->{pid}, @a;
  my $m = $sh->{main} // $sh;   # $$ is the main shell, also in a subshell: its trap counts (L6)
  my $self = sub {
    my $t = $m->{trap}{$s};
    return defer($k, 0) if defined $t && $t eq '';            # ignored
    return run_trap($c, $s, sub { defer($k, 0) }) if defined $t && $m == $sh;
    if (defined $t) { $SIG{$s}->($s) if ref $SIG{$s} eq 'CODE'; return defer($k, 0) }   # as a real signal: the trap runs in the main shell
    $m->{trap}{EXIT} = '' if exists $m->{trap}{EXIT};         # a death by the signal runs no EXIT trap
    $Proc::ShellSpawn::SIGNALLED = $s;                                 # the caller may die by it too (try.pl does)
    $sh->{die}->(128 + ($SIGNUM{$s} // 15)) };                 # the whole string ends, as sh -c would
  return $self->() unless @other;
  spawn($c, $c->{map}, ['kill', "-$s", @other], $env, sub { $self->() }) }

1;
