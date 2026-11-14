package Proc::ShellSpawn::Builtins;   # builtins run by the large subset: one function per builtin (B1-B3 of "Shell Corpus Gaps")
our $VERSION = '0.12';
use strict; use warnings; use feature 'current_sub';
use Proc::ShellSpawn;
BEGIN { no strict 'refs'; *$_ = \&{"Proc::ShellSpawn::$_"} for qw(defer fail msg put var spawn find_cmd) }

# A builtin counts as implemented when its entry is here; Proc::ShellSpawn looks command names up in
# @Proc::ShellSpawn::CMDS, where this table comes first.  Each handler: NAME->(CONTEXT, ARGV, ENV, K), calls K once.
our %CMD = ((map +($_ => [__PACKAGE__ . "::b_$_"]), qw(alias unalias jobs fg bg hash type times ulimit)),
            (map +($_ => [__PACKAGE__ . '::b_interactive']), qw(history fc bind help compopt logout)));
unshift @Proc::ShellSpawn::CMDS, \%CMD;

sub done { my ($k, $st) = @_; sub { $k->($st) } }
sub sq { my $v = shift; my $o = '';   # as dash quotes values in listings: 'a'"'"'b'; a leading quote gives ''"'"...
  while (1) { $v =~ /\G([^']*)/gc; $o .= "'$1'"; last unless $v =~ /\G('+)/gc; $o .= qq("$1"); last if pos $v == length $v }
  $o }

# ------------------------------------------------------------------ B1: alias, unalias
# The parser expands aliases in the lines after their definition; here the table is kept for eval and '.' texts.
sub b_alias {
  my ($c, $argv, $env, $k) = @_; my $al = $c->{sh}{alias}; my @a = @$argv[1 .. $#$argv];
  return Proc::ShellSpawn::Large::unsupported($c, "'alias' in the text of eval or '.'") if $c->{sh}{intext};
  return put($c, 1, join('', map "$_=" . sq($al->{$_}) . "\n", sort keys %$al), done($k, 0)) unless @a;   # dash: hash order
  my ($out, $err) = ('', '');
  for (@a) { if (/^([^=]+)=(.*)\z/s) { $al->{$1} = $2 } elsif (exists $al->{$_}) { $out .= "$_=" . sq($al->{$_}) . "\n" }
             else { $err .= "alias: $_ not found\n" } }
  put($c, 1, $out, sub { put($c, 2, $err, done($k, $err ne '' ? 1 : 0)) }) }
sub b_unalias {
  my ($c, $argv, $env, $k) = @_; my $al = $c->{sh}{alias}; my @a = @$argv[1 .. $#$argv];
  return Proc::ShellSpawn::Large::unsupported($c, "'unalias' in the text of eval or '.'") if $c->{sh}{intext};
  if ($a[0] eq '-a') { %$al = (); return defer($k, 0) }
  my $err = ''; for (@a) { exists $al->{$_} ? delete $al->{$_} : ($err .= "unalias: $_ not found\n") }
  put($c, 2, $err, done($k, $err ne '' ? 1 : 0)) }

# ------------------------------------------------------------------ B2: interactive-only builtins
sub b_interactive {   # nothing (the default), or as dash, which has none of them: a program by that name, or not found
  my ($c, $argv, $env, $k) = @_;
  $c->{sh}{interactive} eq 'dash' ? spawn($c, $c->{map}, $argv, $env, $k) : defer($k, 0) }

# ------------------------------------------------------------------ B3: as dash
sub b_jobs {   # dash's format in sh -c: "[N] + Running", padded to column 33, without the command's text; -l adds the
  # process ID, -p prints it alone.  In a pipeline element or $( ) the shell's jobs are listed too, as bash does (rule E)
  # Operands %N, %%, %+, %- (post-0.04) list those jobs, in that order; one that does not exist: dash's message, status 2.
  my ($c, $argv, $env, $k) = @_; my @a = @$argv[1 .. $#$argv]; my $f = '';
  $f .= $1 while @a && $a[0] =~ /^-([lp]+)\z/ && shift @a;
  my @j = (@{$c->{sh}{ljobs} // []}, @{$c->{sh}{jobl}}); my $st = 0;
  my $line = sub { my $i = shift; my $pid = $j[$i]{first} // $j[$i]{pids}[0] // 0; return "$pid\n" if $f =~ /p/;
    my $h = sprintf "[%d] %s %s", $i + 1, $i == $#j ? '+' : $i == $#j - 1 ? '-' : ' ', $f =~ /l/ ? "$pid " : '';
    sprintf "%s%-*s\n", $h, 33 - length $h, 'Running' };
  my @out = map +[1, $line->($_)], grep !defined $j[$_]{st}, 0 .. $#j;
  if (@a) { @out = ();
    for (@a) { my $i = /^%([0-9]+)\z/ ? $1 - 1 : $_ eq '%-' ? $#j - 1 : $#j;
      if ($i >= 0 && $i <= $#j && !defined $j[$i]{st}) { push @out, [1, $line->($i)] }
      else { push @out, [2, "jobs: No such job: $_"]; $st = 2 } } }
  sub { my $next = __SUB__; my $o = shift @out or return $k->($st);
    $o->[0] == 1 ? put($c, 1, $o->[1], $next) : msg($c, $o->[1], $next) }->() }
sub b_bg { my ($c, $argv, $env, $k) = @_; my $j = $argv->[1];
  msg($c, defined $j ? "$argv->[0]: job $j not created under job control" : "$argv->[0]: No current job", done($k, 2)) }
*b_fg = \&b_bg;

my %DASHBI = map +($_ => 1), qw(. : [ alias bg break cd chdir command continue echo eval exec exit export false fg getopts hash
  jobs kill local printf pwd read readonly return set shift test times trap true type ulimit umask unalias unset wait);
my %DASHKW = map +($_ => 1), qw(! { } case do done elif else esac fi for if in then until while);
sub b_hash {
  my ($c, $argv, $env, $k) = @_; my $h = $c->{sh}{hash}; my @a = @$argv[1 .. $#$argv];
  return put($c, 1, join('', map "$h->{$_}\n", sort keys %$h), done($k, 0)) unless @a;
  if ($a[0] eq '-r') { %$h = (); return defer($k, 0) }
  my @bad;
  for (@a) { next if $DASHBI{$_} || $c->{sh}{cmd}{$_}; my ($p) = find_cmd($c, $_, var($c, 'PATH'));
    if (defined $p) { $h->{$_} = $p unless Proc::ShellSpawn::has_dir($_) } else { push @bad, $_ } }
  my $st = @bad ? 1 : 0;   # one message per name not found, each after the one before
  sub { my $next = __SUB__; @bad ? msg($c, "hash: " . shift(@bad) . ": not found", $next) : $k->($st) }->() }
sub b_type {
  my ($c, $argv, $env, $k) = @_; my $sh = $c->{sh}; my ($t, $st) = ('', 0);
  for my $n (@$argv[1 .. $#$argv]) {
    if ($DASHKW{$n}) { $t .= "$n is a shell keyword\n" }
    elsif (exists $sh->{alias}{$n}) { $t .= "$n is an alias for $sh->{alias}{$n}\n" }
    elsif ($sh->{cmd}{$n}) { $t .= "$n is a shell function\n" }
    elsif ($Proc::ShellSpawn::SPECIAL{$n}) { $t .= "$n is a special shell builtin\n" }
    elsif ($DASHBI{$n}) { $t .= "$n is a shell builtin\n" }
    elsif (!Proc::ShellSpawn::has_dir($n) && $sh->{hash}{$n}) { $t .= "$n is a tracked alias for $sh->{hash}{$n}\n" }
    else { my ($p) = Proc::ShellSpawn::has_dir($n) ? (-x Proc::ShellSpawn::path_in($c, $n) && !-d _ ? $n : undef) : find_cmd($c, $n, var($c, 'PATH'));
      if (defined $p) { $t .= "$n is $p\n" } else { $t .= "$n: not found\n"; $st = 127 } } }
  put($c, 1, $t, done($k, $st)) }
sub b_times {   # the shell's own and its children's user and system time
  my ($c, $argv, $env, $k) = @_; my @t = times;
  my $f = sub { my $s = shift; sprintf '%dm%.6fs', int($s / 60), $s - 60 * int($s / 60) };
  put($c, 1, join(' ', map $f->($_), @t[0, 1]) . "\n" . join(' ', map $f->($_), @t[2, 3]) . "\n", done($k, 0)) }

# ulimit, reading only: dash's letters and units; the limits of this Perl process, from getrlimit (Proc::Spawner's
# XSUB; post-0.08: before, /proc/self/limits or a shell's ulimit).  POSIX units: blocks of 512 bytes for -f and -c,
# KiB for -s -d -m -l -v.
my %UL = (t => ['CPU', 1], f => ['FSIZE', 512], d => ['DATA', 1024], s => ['STACK', 1024], c => ['CORE', 512],
          m => ['RSS', 1024], l => ['MEMLOCK', 1024], n => ['NOFILE', 1], v => ['AS', 1024]);
sub b_ulimit {
  my ($c, $argv, $env, $k) = @_; my ($hard, $r) = (0, 'f');
  for (@$argv[1 .. $#$argv]) { $hard = 1 if /H[a-zA-Z]*\z/ && !/S[^H]*\z/; $r = $1 if /([nsctvlmdf])/ }
  my ($name, $div) = @{$UL{$r}};
  my %res = defined &Proc::Spawner::__rlimits ? Proc::Spawner::__rlimits() : ();   # (none on Windows)
  my @v = defined $res{$name} ? Proc::Spawner::__getrlimit($res{$name}) : ();
  require Proc::ShellSpawn::Large;   # (unsupported lives there; this module may run without it)
  return Proc::ShellSpawn::Large::unsupported($c, "'ulimit -$r'") unless @v;
  my $v = $v[$hard ? 1 : 0];
  put($c, 1, ($v eq 'unlimited' ? $v : int($v / $div)) . "\n", done($k, 0)) }

1;
__END__

=head1 NAME

Proc::ShellSpawn::Builtins - builtins of the large shell subset: alias, the job builtins, and the interactive ones (EXPERIMENTAL)

=head1 DESCRIPTION

Loaded by L<Proc::ShellSpawn>. Each builtin is one function; it counts as implemented when this module's
table C<%Proc::ShellSpawn::Builtins::CMD> has an entry for it. The table is put first in
C<@Proc::ShellSpawn::CMDS>, the list of tables in which the executor looks command names up; another module
can add its own table the same way (C<unshift @Proc::ShellSpawn::CMDS, \%mine>).

=over 4

=item C<alias>, C<unalias>

Kept for the text of C<eval> and C<.>; the parser L<Proc::ShellSubset::Large> expands aliases in the lines
after a definition, as dash and bash do. The listing is sorted by name (dash lists in the order of its hash
table, bash sorted). Defining or removing an alias inside C<eval> or C<.> text stops with status 248.

=item C<jobs>, C<bg>, C<fg>, C<hash>, C<type>, C<times>, C<ulimit> (reading only)

As dash 0.5.12 does in C<sh -c>, texts and statuses included. C<ulimit> asks getrlimit (through L<Proc::Spawner>).

=item C<history>, C<fc>, C<bind>, C<help>, C<compopt>, C<logout>

Only meaningful in an interactive shell. By default they do nothing and return 0, as bash mostly does; with
the option C<< interactive => 'dash' >> of L<Proc::ShellSpawn/run> they run as dash would (it has none of them:
a program of that name, or "not found", 127). The parser takes the same option (C<reject> rejects them).

=back

=cut
