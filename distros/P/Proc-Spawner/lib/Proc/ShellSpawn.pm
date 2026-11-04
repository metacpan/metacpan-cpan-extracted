package Proc::ShellSpawn;
# Runs Proc::ShellSubset parse trees with posix_spawn(3), in the simplest scenario:
# this module is the only code that starts child processes, and it owns
# SIGCHLD while it runs.  No fork in Perl: compound commands, pipelines of
# them, subshells, $( ), loops and background chains run in this process as
# continuations driven by one event loop.  This is the shell layer only: the
# loop and the starting of children are Proc::Spawner's, the ends and the
# process nodes (with the continuation each runs when it ends) Proc::Spawner::Graph's.
# Aim: what dash and bash do alike (the parsers reject what they do differently); where the two differ only at
# run time, as dash does (rule A5, doc/large-subset/large-subset-spec.md).  Every program started is a child of this
# Perl process, never a grandchild.
#
# Process-wide state flipped for a while, so bullet-proof only in non-threaded execution: Perl's umask,
# set to the shell's while a redirection's file is opened (open_end); SIGINT, SIGQUIT and SIGPIPE,
# ignored while run() runs (ignoring_int); traps, set in %SIG while run() runs and put back after it
# (Proc::ShellSpawn::Large, b_trap); and Proc::Spawner's own (umask in start, SIGCHLD in wait_until).
use strict; use warnings; use feature 'current_sub';
use POSIX ();
use File::Glob ();
use Cwd ();
use Proc::Spawner;
use Proc::Spawner::Graph;
use Scalar::Util qw(weaken);

our $VERSION = '0.04';
our $TRACE; *TRACE = \$Proc::Spawner::TRACE;   # undef, or a code ref given one line per fd or process operation
our %PARSE = map +($_ => 1), qw(assign param_ops if while for case read);   # options for Proc::ShellSubset and Proc::ShellSubset::Large
# The parser for run(STRING): run(STRING, parser => CODE), CODE->(TEXT) returning a tree or an error hash.
# Default (EXPERIMENTAL, awaiting approval): the largest of Proc::ShellSubset::Large, Proc::ShellSubset, Proc::ShellSubset::Small that the
# caller has loaded; if none is, Proc::ShellSubset is loaded.  The executor itself loads no parser otherwise.
sub default_parser {
  defined &Proc::ShellSubset::Large::parse ? sub { Proc::ShellSubset::Large::parse($_[0], %PARSE, @_[1 .. $#_]) }
  : defined &Proc::ShellSubset::parse ? sub { Proc::ShellSubset::parse($_[0], %PARSE) }
  : defined &Proc::ShellSubset::Small::parse ? \&Proc::ShellSubset::Small::parse
  : do { require Proc::ShellSubset; sub { Proc::ShellSubset::parse($_[0], %PARSE) } } }
our $NAME = 'sh';           # prefix of error messages, as sh's "$0"
# EXPERIMENTAL (item N9): with TRACE=dot, one Graphviz picture per event (a start, an exit, an end
# closed) as trace-001.dot, ... in the directory TRACE_DIR (default: the current one).
our $DOT = ($ENV{TRACE} // '') eq 'dot' ? $ENV{TRACE_DIR} // '.' : undef;

sub tr_ { $TRACE->(join '', @_) if $TRACE }
our $G = Proc::Spawner::Graph->new(dot => $DOT);   # our children and our own reads and writes, now

# ------------------------------------------------------------------ extension points (EXPERIMENTAL, awaiting approval)
# Handlers are named by fully qualified sub names, resolved (and their module loaded) at first use:
#   a command node { ext => NAME, ... }, or one with a key of %KIND:  NAME->(CONTEXT, NODE, TAIL, K)
#   a command name in %CMD (or the shell's own table, for functions):  NAME->(CONTEXT, ARGV, ENV, K, DATA)
#   a Part [ext => NAME, ...] of a Word:                                  NAME->(CONTEXT, PART, K) with K->(TEXT)
# Each calls K exactly once (or ends the shell with leave), maybe later, and never waits (D2).
our %KIND = map +($_ => "Proc::ShellSpawn::Large::x_$_"), qw(func export readonly local exec);
our %CMD = ((map +($_ => ['Proc::ShellSpawn::builtin']), ':', qw(exit break continue read)),
            (map +($_ => ["Proc::ShellSpawn::Large::b_$_"]), qw(return shift set eval trap wait umask command getopts unset kill pwd)),
            '.' => ['Proc::ShellSpawn::Large::b_dot']);
our %A4;   # builtins left to sh: A4 (status 248) when one is named at run time
# B2 of "Shell Corpus Gaps": the tables of command names, searched in order; a module adds its own with
# unshift @Proc::ShellSpawn::CMDS, \%MINE (Proc::ShellSpawn::Builtins does).  %A4 stays last.
our @CMDS = (\%CMD, \%A4);
sub cmd_of { my $n = shift; for (@CMDS) { return $_->{$n} if exists $_->{$n} } undef }
sub a4 { $A4{$_} //= ['Proc::ShellSpawn::Large::b_unsupported'] for keys %Proc::ShellSubset::BI }
our $SIGNALLED;   # after run(): the signal of 'kill ... $$' that ended the string, if any
our %TRAPSAVE;   # signals the trap builtin changed during run(), with their old settings
our %SPECIAL = map +($_ => 1), qw(: break continue . eval exec exit export readonly return set shift times trap unset);
BEGIN { *handler = \&Proc::Spawner::Graph::handler }
sub fail {   # stop this shell with $st, after the message $text if given
  my ($c, $st, $text) = @_; defined $text ? msg($c, $text, sub { leave($c, $st) }) : defer(\&leave, $c, $st); return }

# ------------------------------------------------------------------ ends
# The ends (Proc::Spawner::Graph) are what a context maps its fds to; each context holds the ends of
# its map, and the last release closes one.
sub own_fd { $G->parent_end(shift) }
sub is_open { my $d = POSIX::dup($_[0]) // return 0; POSIX::close($d); 1 }   # without touching its flags
sub visible {   # open and not close-on-exec: an fd sh would have inherited (not ours, nor the caller's handles)
  my $n = shift; is_open($n) or return 0;
  open my $i, '<', "/proc/self/fdinfo/$n" or return 1;
  my ($f) = map /^flags:\s*([0-7]+)/ ? oct $1 : (), <$i>;
  !(($f // 0) & 02000000) }   # O_CLOEXEC as /proc shows it (Linux)
sub new_pipe { $G->new_pipe }

sub open_end {  # an end on a file, or undef with $!
  my ($c, $name, $op) = @_;
  my $path = $name =~ m{^/} ? $name : "$c->{sh}{cwd}/$name";
  return $! = POSIX::EEXIST(), undef if $op eq '>' && $c->{sh}{opt}{C} && -f $path;   # set -C
  my $um = umask $c->{sh}{umask};
  my $ok = sysopen my $fh, $path, $Proc::Spawner::Graph::OPEN{$op}, 0666; my $err = $!; umask $um;
  $! = $err, return unless $ok;
  $G->file_end($fh, $op, $name) }

# ------------------------------------------------------------------ contexts
# A context: what the commands run in it get.
#   map   => { CHILD_FD => end, or undef for closed }; fds not listed are ours, inherited as they are
#   sh    => the shell state: vars, exp(orted names), cwd, q ($?), bang ($!), qsub
#   loops => [ { brk => K, cont => K, scope => [contexts] }, ... ] of the enclosing loops
#   shell => { exit => K, scope => [contexts] } for exit
#   held  => 1 if this context holds its map's ends; released by release_ctx, once
sub derive {    # a context with its own map, which it holds
  my ($c, $map, %o) = @_;
  my $d = { %$c, map => $map, held => 1, released => 0, root => !!$o{shell}, late => 0 };
  if (my $k = $o{shell}) {   # a new shell: copies of the state; exit and loops start afresh;
    my $sh = $c->{sh};        # leaving it releases every context made in it
    $d->{sh} = { %$sh, main => $sh->{main} // $sh, vars => { %{$sh->{vars}} }, exp => { %{$sh->{exp}} }, args => [@{$sh->{args}}],
                 opt => { %{$sh->{opt}} }, cmd => { %{$sh->{cmd}} }, ro => { %{$sh->{ro}} }, jobl => [],
                 ljobs => $o{jobs} ? [@{$sh->{ljobs} // []}, @{$sh->{jobl}}] : [],   # jobs listed in a pipeline or $( ) (rule E)
                 pend => [], twait => [], tbusy => 0,   # the caught signals belong to the shell whose trap caught them (X19)
                 trap => { map +($_ => ''), grep $sh->{trap}{$_} eq '', keys %{$sh->{trap}} } };   # sh: only ignored traps stay
    my $scope = [];
    $d->{loops} = []; delete @$d{qw(frame cond)}; $d->{shell} = { scope => $scope, exit => shell_exit($d, $scope, $k) } }
  hold($_) for values %$map;
  push @{ @{$d->{loops}} ? $d->{loops}[-1]{scope} : $d->{shell}{scope} }, $d;
  $d }
sub leave { my ($c, $st) = @_; release_all(map $_->{scope}, @{$c->{loops}}); $c->{shell}{exit}->($st) }   # exit
sub shell_exit {   # the end of a shell: its EXIT trap first (once; an exit inside the trap ends it there)
  my ($c, $scope, $k) = @_; weaken($c); my $state = 0;
  sub { my $st = shift;
    return if $state == 2;
    my $a = $state == 0 && $c && delete $c->{sh}{trap}{EXIT};
    if (defined $a && $a ne '' and ref(my $t = $c->{sh}{parse}->($a)) eq 'ARRAY') {
      $state = 1; my $tc = { %$c, loops => [], held => 0, cond => undef, frame => undef };
      return x_list($tc, $t, undef, sub { return if $state == 2; $state = 2; late($c); release_all($scope); $k->($st) }) }
    $state = 2; late($c); release_all($scope); $k->($st) } }
sub late { my $c = shift; release_ctx($c) if $c && $c->{late} }   # the release a trap postponed (the trap is gone by now)
sub release_ctx {
  my $c = shift; return if !$c->{held} or $c->{released};
  return $c->{late} = 1 if $c->{root} && ($c->{sh}{trap}{EXIT} // '') ne '';   # its EXIT trap still needs them (L5)
  $c->{released} = 1; release($_) for values %{$c->{map}} }
sub release_all { for my $s (@_) { release_ctx($_) for @$s; @$s = () } }   # also breaks the cycles through the scopes

# ------------------------------------------------------------------ the loop and the graph
# Proc::Spawner runs the loop; every continuation runs from its queue, one at a time, and never waits.
# Our children and our own reads and writes are nodes of the graph $G (Proc::Spawner::Graph); a
# child's node carries its continuation as on_exit ['Proc::ShellSpawn::resume', K].
BEGIN { *defer = \&Proc::Spawner::defer; *hold = \&Proc::Spawner::Graph::hold; *release = \&Proc::Spawner::Graph::release }
sub loop_until { Proc::Spawner::wait_until(@_) }
sub on_read { my ($e, $n, $cb) = @_; $G->perl_read($e, $n, sub { $cb->($_[1]) }) }   # one read of end $e: $cb->(BYTES), or undef at end of file
sub on_write { my ($e, $bytes, $cb) = @_; $G->perl_write($e, $bytes, $cb) }   # Perl writes BYTES to end $e without blocking

sub status_of {   # a wait status as sh's $?
  my $w = shift;
  POSIX::WIFSIGNALED($w) ? 128 + POSIX::WTERMSIG($w) : POSIX::WEXITSTATUS($w) }

# Background jobs left running when run() returns go on in later calls; at exit we finish them.
my %JOBS;
# As Perl's system: SIGINT and SIGQUIT are ignored here while commands run (a foreground child gets
# them back by sigdefault; a background child keeps them ignored, as POSIX asks of an asynchronous list).
sub ignoring_int { local @SIG{qw(INT QUIT PIPE)} = ('IGNORE') x 3; $_[0]->() }   # PIPE: a here-document's reader may go away
sub wait_all { ignoring_int(sub { loop_until(sub { !%JOBS }) }) if %JOBS }
END { local $?; wait_all() }

# ------------------------------------------------------------------ spawning
# Signals ignored when we were loaded stay ignored in children, as sh keeps the ones ignored on entry.
# SIGFPE as Perl's own exec would pass it: Perl may ignore it for itself at startup, and puts back
# the disposition it found then (PERL_FPU_PRE_EXEC, PL_sigfpe_saved; fpe_at_exec() reads it).
my $FPE = Proc::Spawner::fpe_at_exec();
my %IGN0 = map +($_ => 1), grep +($SIG{$_} // '') eq 'IGNORE' && ($_ ne 'FPE' || $FPE == 1), keys %SIG;

sub put {   # Perl writes $t to the context's fd $fd, then $then->(); never waits (L10).  Callers go on only
  # in $then, so nothing started later overtakes the text.
  my ($c, $fd, $t, $then) = @_; $then //= sub {};
  my $e = $c->{map}{$fd};
  $e ? do { hold($e); on_write($e, $t, sub { release($e); $then->() }) } : defer($then); return }
sub msg { my ($c, $text, $then) = @_; put($c, 2, "$NAME: $text\n", $then) }   # an error message, to fd 2

sub find_cmd {   # the path to run for $name, or undef and the status (127, 126)
  my ($c, $name, $path) = @_;
  my $abs = sub { $_[0] =~ m{^/} ? $_[0] : "$c->{sh}{cwd}/$_[0]" };
  return $name if $name =~ m{/};
  my $denied;
  for my $d (split /:/, $path // '', -1) {
    my $p = ($d eq '' ? '.' : $d) . "/$name";
    next unless -f $abs->($p);
    return $p if -x _;
    $denied //= $p }
  defined $denied ? (undef, 126, $denied) : (undef, 127) }

sub spawn {   # starts @$argv with $map; $k->(STATUS) when it has ended; returns its process node or undef
  my ($c, $map, $argv, $env, $k, $search) = @_;   # $search: the PATH to look in, if not the command's own (command -p)
  my %e = (%{$c->{sh}{vars}}{grep $c->{sh}{exp}{$_} && /^[A-Za-z_][A-Za-z_0-9]*\z/, keys %{$c->{sh}{vars}}}, %$env);   # as dash: names only
  my ($path, $st, $what) = find_cmd($c, $argv->[0], $search // $e{PATH});
  $c->{sh}{hash}{$argv->[0]} = $path if defined $path && !defined $search && $argv->[0] !~ m{/};   # remembered, as dash (hash, type)
  if (!defined $path) {
    return msg($c, $st == 127 ? "$argv->[0]: not found" : "$argv->[0]: Permission denied", sub { $k->($st) }) }
  my @envp = map "$_=$e{$_}", sort keys %e;
  my %def = map +($_ => 1), grep !$IGN0{$_} && ($SIG{$_} // '') eq 'IGNORE' && ($c->{sh}{trap}{$_} // 1) ne '',   # trap '' SIG: stays ignored
    keys %SIG, $FPE ? () : 'FPE';
  delete @def{qw(INT QUIT)} if $c->{sh}{job};   # in the background: left ignored
  my @o = (sigdefault => [sort keys %def], umask => $c->{sh}{umask}, on_exit => ['Proc::ShellSpawn::resume', $k],
           $c->{sh}{cwd} ne Cwd::getcwd() ? (chdir => $c->{sh}{cwd}) : ());
  my $node = $G->start($path, $argv, \@envp, $map, @o);
  if (!$node && $! == POSIX::ENOEXEC()) {   # a script without #!: sh runs it with sh
    $node = $G->start('/bin/sh', ['sh', $path, @$argv[1 .. $#$argv]], \@envp, $map, @o) }
  return $node if $node;
  my $err = "$!";   # an fd of ours that is not open: the first one the child should have got
  my ($bad) = grep !is_open($_), map $map->{$_} ? $map->{$_}{fd} : (), sort { $a <=> $b } keys %$map;
  $st = $! == POSIX::ENOENT() ? 127 : 126;
  msg($c, defined $bad ? "$bad: Bad file descriptor" : $st == 127 ? "$argv->[0]: not found" : "$argv->[0]: $err", sub { $k->($st) }) }
sub resume { my ($g, $node, $w, $k) = @_; $k->(defined $w ? status_of($w) : 1) }   # on_exit of our children

# ------------------------------------------------------------------ redirections
# Applies @$redirs to a copy of $c's map: $k->(MAP, [opened ends]), or $k->() after a message.
sub redirect {
  my ($c, $redirs, $k) = @_;
  my %m = %{$c->{map}}; my @opened;
  my $fail = sub { msg({ map => \%m }, shift, sub { release($_) for @opened; $k->() }) };   # through the redirections so far
  my $i = 0;
  sub {
    return $k->(\%m, \@opened) if $i > $#$redirs;
    my ($fd, $op, $w) = @{$redirs->[$i++]};
    if ($op eq '<<') {   # a here-document: Perl writes the expanded body into a pipe the command reads
      my $next = __SUB__;
      return expand_str($c, $w, sub { my $body = shift;
        my ($r, $wr) = new_pipe() or return $fail->("pipe: $!");
        push @opened, $m{$fd} = $r; on_write($wr, $body, sub { release($wr) }); $next->() }) }
    if ($op eq '<&' or $op eq '>&') {
      if ($w eq '-') { $m{$fd} = undef }
      elsif (exists $m{$w}) { defined $m{$w} ? ($m{$fd} = $m{$w}) : return $fail->("$w: Bad file descriptor") }
      elsif (visible($w)) { $m{$fd} = own_fd($w) }
      else { return $fail->("$w: Bad file descriptor") }
      return __SUB__->() }
    my $next = __SUB__;
    expand_str($c, $w, sub {
      my $name = shift;
      my $e = $name ne '' && open_end($c, $name, $op);
      if (!$e) {   # dash's wording
        my $err = $name eq '' || $!{ENOENT} ? ($op eq '<' ? 'No such file' : 'Directory nonexistent') : "$!";
        return $fail->(($op eq '<' ? 'cannot open' : 'cannot create') . " $name: $err") }
      push @opened, $m{$fd} = $e; $next->() }) }->() }

# Runs $body->(CONTEXT, K2) with @$redirs applied, then $k->(STATUS); status 2 if they fail.
sub with_redirs {
  my ($c, $redirs, $tail, $k, $body) = @_;
  return $body->($c, $tail, $k) unless $redirs && @$redirs;
  redirect($c, $redirs, sub {
    my ($m, $opened) = @_ or return defer($k, 2);
    my $d = derive($c, $m); release($_) for @$opened;
    $body->($d, [$d, @{$tail // []}], sub { release_ctx($d); $k->(@_) }) }) }

# ------------------------------------------------------------------ expansion
sub var {   # also $0-$9 ${10}..., $#, $$, $@ and $* (joined by the first character of IFS)
  my ($c, $n) = @_; my $sh = $c->{sh};
  return $n ? $sh->{args}[$n - 1] // '' : 'sh' if $n =~ /^[0-9]+\z/;
  $n eq '?' ? $sh->{q} : $n eq '!' ? ($sh->{bang} // {})->{first} // '' : $n eq '#' ? scalar @{$sh->{args}}
    : $n eq '$' ? $sh->{pid} : $n eq '@' || $n eq '*' ? join(ifs1($c), @{$sh->{args}}) : $sh->{vars}{$n} // '' }
sub ifs1 { my $i = $_[0]{sh}{vars}{IFS}; defined $i ? substr($i, 0, 1) : ' ' }
sub isset {
  my ($c, $n) = @_; my $sh = $c->{sh};
  $n =~ /^[1-9][0-9]*\z/ ? $n <= @{$sh->{args}} : $n =~ /^[@*]\z/ ? !!@{$sh->{args}}
    : $n eq '!' ? defined $sh->{bang} : $n =~ /^[?#\$0]\z/ || defined $sh->{vars}{$n} }
sub getvar {   # a value for $NAME, or undef after ending the shell (set -u)
  my ($c, $n) = @_;
  return fail($c, 2, "$n: parameter not set") if $c->{sh}{opt}{u} && $n !~ /^[@*!]\z/ && !isset($c, $n);
  var($c, $n) }

sub glob_quote { (my $s = shift) =~ s/([\\*?\[\]{}~])/\\$1/g; $s }

# A Word into fields: $k->([FIELD, ...]).  $how: 'argv' splits and globs; 'str' gives one string.
# A field under construction is [TEXT, PATTERN, KEEP]: PATTERN is the text for globbing, with
# quoted characters escaped, or undef if nothing in it may glob.
sub expand {
  my ($c, $word, $how, $k) = @_;
  return $k->([$word]) unless ref $word;
  # a field: [TEXT, GLOB PATTERN (quoted characters escaped), KEEP even if empty, HAS ACTIVE GLOB CHARS]
  my @f; my $cur = ['', '', 0, 0];
  my $add = sub {   # text; $pat: its glob characters are active; $split: an unquoted expansion
    my ($t, $pat, $split) = @_;
    my $ifs = $c->{sh}{vars}{IFS} // " \t\n";
    if ($split && $how eq 'argv' && $ifs ne '') {   # split at IFS characters (L2); the pieces may glob
      my ($ws, $nw) = map quotemeta, join('', $ifs =~ /[ \t\n]/g), join('', $ifs =~ /[^ \t\n]/g);
      my $d = $nw eq '' ? qr/[$ws]+/ : $ws eq '' ? qr/[$nw]/ : qr/[$ws]*[$nw][$ws]*|[$ws]+/;
      my @p = split /($d)/, $t, -1;
      for my $j (0 .. $#p) {
        if ($j % 2) {   # a delimiter: one with a non-blank IFS character ends a field even if it is empty
          push @f, $cur if length $cur->[0] or $cur->[2] or $nw ne '' && $p[$j] =~ /[$nw]/; $cur = ['', '', 0, 0]; next }
        $cur->[0] .= $p[$j]; $cur->[1] .= $p[$j]; $cur->[3] ||= $p[$j] =~ /[*?\[]/ } }
    elsif ($split && $how eq 'argv') { $cur->[0] .= $t; $cur->[1] .= $t; $cur->[3] ||= $t =~ /[*?\[]/ }   # IFS empty: no splitting
    else { $cur->[0] .= $t; $cur->[1] .= $pat ? $t : glob_quote($t); $cur->[3] ||= $pat && $t =~ /[*?\[]/;
           $cur->[2] = 1 unless $pat } };
  my @parts = @$word; my $i = 0;
  sub {
    if ($i > $#parts) {
      push @f, $cur if length $cur->[0] or $cur->[2] && !$cur->[4] or $how ne 'argv';
      return $k->([map $_->[0], @f]) if $how ne 'argv';
      return $k->([map {   # a pattern that matches nothing stays as it is
        my ($t, $p, undef, $g) = @$_;
        my $base = !$g || $p =~ m{^/} || $c->{sh}{cwd} eq Cwd::getcwd() ? '' : glob_quote($c->{sh}{cwd}) . '/';
        my @m = $g && !$c->{sh}{opt}{f} ? sort { $a cmp $b } grep !m{(?:^|/)\.\.?\z}, File::Glob::bsd_glob($base . $p, File::Glob::GLOB_QUOTE()) : ();   # never . or .. (rule E, as bash)
        s{^\Q$c->{sh}{cwd}\E/}{} for $base ? @m : ();
        @m ? @m : $t } @f]) }
    my $x = $parts[$i++]; my $next = __SUB__;
    return $add->($x, 0), $next->() unless ref $x;
    my ($kind, @a) = @$x; (my $q = $kind) =~ s/^"//; my $split = $kind !~ /^"/;
    if    ($kind eq '*')   { $add->($a[0], 1) }
    elsif ($kind eq '~')   { $add->($a[0] eq '' ? var($c, 'HOME') : (getpwnam $a[0])[7] // "~$a[0]", 0) }
    elsif ($kind eq '"$' && $a[0] eq '@' && $how eq 'argv') {   # "$@": one field per parameter
      my @p = @{$c->{sh}{args}}; $cur->[4] = 1 unless @p;   # none: the field goes, quotes or not (L1)
      for my $j (0 .. $#p) { if ($j) { push @f, $cur; $cur = ['', '', 0, 0] } $add->($p[$j], 0) } }
    elsif ($q eq '$')      { my $v = getvar($c, $a[0]) // return; $add->($v, 0, $split) }
    elsif ($q eq '${#')    { my $v = getvar($c, $a[0]) // return; $add->(length $v, 0, $split) }
    elsif ($q eq '${')     {   # the word is expanded only if it is used, as in sh
      my ($n, $op, $w) = @a; my $v = var($c, $n);
      my $set = isset($c, $n) && ($op !~ /:/ || $v ne '');
      if ($op =~ /^[%#]/) {   # remove the smallest or largest matching suffix or prefix
        getvar($c, $n) // return;   # set -u (L4)
        return pattern_re($c, $w, sub { my $re = shift; my @i = 0 .. length $v; @i = reverse @i if $op =~ /^(?:%|##)\z/;
          for my $i (@i) { my ($cut, $keep) = $op =~ /%/ ? (substr($v, $i), substr($v, 0, $i)) : (substr($v, 0, $i), substr($v, $i));
                           if ($cut =~ $re) { $v = $keep; last } }
          $add->($v, 0, $split); $next->() }) }
      my $word = $op =~ /[-=?]/ ? !$set : $set;
      unless ($word) { $add->($op =~ /[-=?]/ ? $v : '', 0, $split); return $next->() }
      return expand($c, $w, 'str', sub { my $t = $_[0][0];
        return fail($c, 2, "$n: " . ($t ne '' ? $t : $op =~ /:/ ? 'parameter not set or null' : 'parameter not set')) if $op =~ /\?/;
        if ($op =~ /=/) { setvar($c, $n, $t) or return }
        $add->($t, 0, $split); $next->() }) if !$split || $op =~ /[=?]/;
      return each_async(ref $w ? $w : [$w], sub { my ($p, $more) = @_;   # unquoted: strings are split, ["'", text] is not
        return $add->($p, 0, 1), $more->() unless ref $p;
        return $add->($p->[1], 0), $more->() if $p->[0] eq "'";
        expand($c, [$p], 'str', sub { $add->($_[0][0], 0, $p->[0] !~ /^"/); $more->() }) }, $next) }
    elsif ($kind eq "'")   { $add->($a[0], 0) }
    elsif ($kind eq 'ext') { return handler($a[0])->($c, $x, sub { $add->(shift, 0, $split); $next->() }) }
    elsif ($q eq '$((' && ref $a[0]) {   # with $( ), `...` or ${#NAME} inside (parser item P2): those first, then the text
      return expand_str($c, $a[0], sub { my $v = arith($c, shift); return unless defined $v; $add->($v, 0, $split); $next->() }) }
    elsif ($q eq '$((')    { my $v = arith($c, $a[0]); return unless defined $v; $add->($v, 0, $split) }
    elsif ($q eq '$(')     { return subst($c, $a[0], sub { $add->(shift, 0, $split); $next->() }) }
    elsif ($kind eq '{' || $kind eq '{..') { die "Proc::ShellSpawn: brace expansion is not implemented" }
    else { die "Proc::ShellSpawn: unknown part '$kind'" }
    $next->() }->() }
sub each_async {   # $body->(ITEM, NEXT) for each item in turn (each may finish later), then $done->()
  my ($items, $body, $done) = @_; my $i = 0;
  sub { my $next = __SUB__; return $done->() if $i > $#$items; $body->($items->[$i++], $next) }->() }
sub expand_str  { my ($c, $w, $k) = @_; expand($c, $w, 'str', sub { $k->($_[0][0]) }) }
sub expand_list {   # several words, one after another (each may see the effect of the one before)
  my ($c, $ws, $how, $k) = @_; my @out; my $i = 0;
  sub { my $next = __SUB__;   # a loop while words expand at once (no deep recursion); a $( ) resumes it later
    while ($i <= $#$ws) {
      my ($now, $done) = 1;
      expand($c, $ws->[$i++], $how, sub { push @out, @{$_[0]}; $now ? $done = 1 : $next->() });
      $now = 0; $done or return }
    $k->(\@out) }->() }

sub subst {   # $( list ): $k->(OUTPUT without trailing newlines)
  my ($c, $list, $k) = @_;
  my ($r, $w) = new_pipe() or return msg($c, "pipe: $!", sub { $k->('') });
  my ($out, $st, $eof) = ('');
  my $done = sub { return unless $eof && defined $st; $c->{sh}{qsub} = $st; $k->($out =~ tr/\0//dr =~ s/\n+\z//r) };
  my $d = derive($c, { %{$c->{map}}, 1 => $w }, jobs => 1, shell => sub { $st = shift; $done->() }); release($w);
  on_read($r, 65536, sub {
    return $eof = 1, release($r), $done->() unless defined $_[0];
    $out .= $_[0]; on_read($r, 65536, __SUB__) });
  x_list($d, $list, [$d], $d->{shell}{exit}) }

# $(( )): sh's integer arithmetic.  undef (after a message, and leaving the shell) on error.
sub arith {
  my ($c, $e) = @_; my $src = $e;
  my $unset; $e =~ s/\$\{?([A-Za-z_][A-Za-z_0-9]*|[0-9]+|[?!#\$])\}?/getvar($c, $1) \/\/ ($unset = '0')/ge;
  return if $unset;
  my @t = $e =~ /\G\s*(0[xX][0-9a-fA-F]+|[0-9]+|[A-Za-z_][A-Za-z_0-9]*|<<=|>>=|<<|>>|<=|>=|==|!=|&&|\|\||[-+*\/%&^|]=|[-+*\/%<>&^|!~?:()=])/gc;
  my $err = sub { fail($c, 2, "arithmetic expression: $_[0]: \"$src\""); undef };
  return $err->('syntax error') if $e !~ /\G\s*\z/gc;
  my $p = 0; my $bad; local our $skip = 0;   # $skip: inside the side of && || ?: that is not taken
  use integer;
  my %bin = ('*' => 9, '/' => 9, '%' => 9, '+' => 8, '-' => 8, '<<' => 7, '>>' => 7, '<' => 6, '<=' => 6,
             '>' => 6, '>=' => 6, '==' => 5, '!=' => 5, '&' => 4, '^' => 3, '|' => 2, '&&' => 1, '||' => 0);
  my ($expr, $unary);   # weak (below): the two parsers call each other, and strong references would form a cycle
  my $unary_s = $unary = sub {
    my $x = $t[$p++] // return +($bad //= 'syntax error') && 0;
    return -$unary->() if $x eq '-'; return +$unary->() if $x eq '+';
    return !$unary->() ? 1 : 0 if $x eq '!'; return ~$unary->() if $x eq '~';
    if ($x eq '(') { my $v = $expr->(0); ($t[$p++] // '') eq ')' or $bad //= 'syntax error'; return $v }
    return do { no warnings 'portable'; $x =~ /^0[xX]/ ? hex $x : $x =~ /^0/ ? oct $x : $x } if $x =~ /^[0-9]/;   # 64-bit, as dash
    if ($x =~ /^[A-Za-z_]/) { my $v = var($c, $x); $v = 0 if $v =~ /^\s*\z/;
      $v =~ /^\s*[-+]?[0-9]+\s*\z/ or $skip or $bad //= "$x: not a number"; return $v + 0 }
    $bad //= 'syntax error'; 0 };
  my $dead;
  my $expr_s = $expr = sub {
    my $min = shift;
    if (!$min && ($t[$p] // '') =~ /^[A-Za-z_]/ && ($t[$p + 1] // '') =~ /^(?:<<|>>|[-+*\/%&^|])?=\z/) {   # NAME op= EXPR, right to left
      my ($n, $op) = @t[$p, $p + 1]; $p += 2; my $r = $expr->(0); $op =~ s/=\z//;
      my $o = var($c, $n); $o = 0 if $o =~ /^\s*\z/;
      ($op =~ m{^[/%]\z} && !$r) ? ($bad //= 'division by zero') : $op ne '' and $r = eval "\$o $op \$r";
      $skip or $dead or setvar($c, $n, $r) or $dead = 1; return $r }
    my $l = $unary->();
    while (defined(my $op = $t[$p])) {
      if ($op eq '?' && $min <= 0) {
        $p++; my $a = do { local $skip = $skip || !$l; $expr->(0) };
        ($t[$p++] // '') eq ':' or $bad //= 'syntax error';
        my $b = do { local $skip = $skip || $l; $expr->(0) }; $l = $l ? $a : $b; next }
      my $pr = $bin{$op}; last unless defined $pr && $pr >= $min; $p++;
      my $r = do { local $skip = $skip || ($op eq '&&' ? !$l : $op eq '||' ? $l : 0); $expr->($pr + 1) };
      if    ($op eq '&&') { $l = $l && $r ? 1 : 0 } elsif ($op eq '||') { $l = $l || $r ? 1 : 0 }
      elsif ($op =~ m{^[/%]\z} && !$r) { $bad //= 'division by zero' unless $skip; $l = 0 }
      else { $l = eval "\$l $op \$r" ; $l = $l ? 1 : 0 if $op =~ /^[<>=!]=?\z|^[<>]\z/ } }
    $l };
  no integer;
  weaken($expr); weaken($unary);   # $expr_s and $unary_s keep them alive until arith returns
  my $v = $expr->(0); $bad //= 'syntax error' if $p <= $#t;
  return if $dead;   # a readonly variable: the shell is already ending
  defined $bad ? $err->($bad) : $v }

# ------------------------------------------------------------------ the tree
# x_*($c, NODE, $tail, $k): run NODE in context $c, then $k->(STATUS).  $tail: the contexts to
# release as soon as the last process NODE can start has started (undef: something may follow).
sub after_start { release_ctx($_) for @{$_[0] // []} }

sub x_list {
  my ($c, $l, $tail, $k) = @_; my $i = 0;
  sub { my $st = shift; my $p = $c->{sh}{pend}; my $me = __SUB__;
        return Proc::ShellSpawn::Large::run_pending($c, sub { $c->{sh}{q} = $st; $me->($st) }) if !$c->{intrap} && ($p && @$p || $c->{sh}{tbusy});   # X19
        return defer($k, $st) if $i > $#$l;
        x_andor($c, $l->[$i++], $i > $#$l ? $tail : undef, $me) }->(0) }

sub x_andor {
  my ($c, $ao, $tail, $k) = @_;
  return x_bg($c, [@$ao[0 .. $#$ao - 1]], $k) if $ao->[-1] eq '&';
  my ($i, $ran) = (0, -1); my $cc = cond($c);
  sub { my $st = shift;
    $i += 2 while $i > 0 && $i <= $#$ao && ($ao->[$i - 1] eq '&&') != ($st == 0);
    if ($i > $#$ao) {   # set -e: the last pipeline failed, not negated, not in a condition
      return leave($c, $st) if $st && $c->{sh}{opt}{e} && !$c->{cond} && $ran == $#$ao && ref $ao->[-1][0];
      return defer($k, $st) }
    my $p = $ao->[$ran = $i]; $i += 2;
    x_pipeline($i > $#$ao ? $c : $cc, $p, $i > $#$ao ? $tail : undef, __SUB__) }->(0) }
sub cond { +{ %{$_[0]}, cond => 1, held => 0 } }   # a context whose commands do not trigger set -e

sub x_bg {   # chain & : its own shell and job, fd 0 from /dev/null
  my ($c, $ao, $k) = @_;
  my $null = open_end($c, '/dev/null', '<') or return msg($c, "/dev/null: $!", sub { $k->(2) });
  my $job = { pids => [] }; $JOBS{$job} = $job; push @{$c->{sh}{jobl}}, $job;
  $job->{id} = ++$c->{sh}{jobs};
  my $d = derive($c, { %{$c->{map}}, 0 => $null }, shell => sub {
    tr_("background job $job->{id}: done, status $_[0]"); delete $JOBS{$job};
    $job->{st} = shift; $_->() for splice @{$job->{waiters} // []} });   # for the wait builtin
  release($null);
  $d->{sh}{job} = $job;         # shared by the job's shells: its first process becomes $!
  x_andor($d, $ao, [$d], $d->{shell}{exit});
  $c->{sh}{bang} = $job;
  $c->{sh}{q} = 0; defer($k, 0) }

sub x_pipeline {
  my ($c, $p, $tail, $k) = @_;
  my @cmd = @$p; my $neg = !ref $cmd[0] && shift @cmd; $c = cond($c) if $neg;
  my $kk = sub { my $st = $neg ? ($_[0] ? 0 : 1) : $_[0]; $c->{sh}{q} = $st; $k->($st) };
  return x_cmd($c, $cmd[0], $tail, $kk) if @cmd == 1;
  my (@ends, @d, @st); my $left = @cmd;
  for (1 .. $#cmd) { push @ends, [new_pipe()]; @{$ends[-1]} or return msg($c, "pipe: $!", sub { $kk->(2) }) }
  for my $j (0 .. $#cmd) {   # each element: a shell of its own, fds 0 and 1 on the pipes
    my %m = %{$c->{map}};
    $m{0} = $ends[$j - 1][0] if $j; $m{1} = $ends[$j][1] if $j < $#cmd;
    my $done = sub { $st[$j] = shift; defer($kk, $st[-1]) unless --$left };
    $d[$j] = derive($c, \%m, jobs => 1, shell => $done) }
  release($_) for map @$_, @ends;           # the creator's holds: only the elements' remain
  x_cmd($d[$_], $cmd[$_], [$d[$_]], $d[$_]{shell}{exit}) for 0 .. $#cmd;
  after_start($tail) }

sub x_cmd {
  my ($c, $x, $tail, $k) = @_;
  return x_simple($c, $x, $tail, $k) if $x->{argv};
  return with_redirs($c, $x->{redir}, undef, $k, sub { x_cd($_[0], $x, $_[2]) }) if exists $x->{cd};   # cd with redirections (post4-0.03)
  return x_set($c, $x, $k) if $x->{set};
  if (my ($h) = $x->{ext} // map $KIND{$_}, grep exists $x->{$_}, sort keys %KIND) { return handler($h)->($c, $x, $tail, $k) }
  with_redirs($c, $x->{redir}, $tail, $k, sub {
    my ($c, $tail, $k) = @_;
    if (my $l = $x->{group}) { return x_list($c, $l, $tail, $k) }
    if (my $l = $x->{sub}) {
      my $d = derive($c, { %{$c->{map}} }, shell => $k);
      return x_list($d, $l, [$d, @{$tail // []}], $d->{shell}{exit}) }
    return x_if($c, $x->{if}, $tail, $k) if $x->{if};
    return x_while($c, $x, $k) if $x->{while} || $x->{until};
    return x_for($c, $x, $k) if exists $x->{for};
    return x_case($c, $x, $tail, $k) if exists $x->{case};
    die "Proc::ShellSpawn: unknown command node" }) }

sub x_if {
  my ($c, $arms, $tail, $k) = @_; my $i = 0;
  sub {
    return defer($k, 0) if $i > $#$arms;
    return x_list($c, $arms->[$i], $tail, $k) if $i == $#$arms;       # else
    my $then = $arms->[$i + 1]; $i += 2; my $next = __SUB__;
    x_list(cond($c), $arms->[$i - 2], undef, sub { $_[0] ? $next->() : x_list($c, $then, $tail, $k) }) }->() }

sub loop {   # runs $iter->(CONTEXT, NEXT, END) per iteration, with break and continue
  my ($c, $k, $iter) = @_; my $st = 0;
  my $rec = { scope => [] };
  my $lc = { %$c, loops => [@{$c->{loops}}, $rec] };
  my $end = sub { release_all($rec->{scope}); delete @$rec{qw(brk cont)}; defer($k, @_ ? shift : $st) };
  $rec->{brk} = sub { $end->(0) };
  sub { my $next = __SUB__; release_all($rec->{scope}); $rec->{scope} = [];
        $rec->{cont} = sub { $st = 0; $next->() }; $iter->($lc, sub { $st = shift; defer($next) }, $end) }->() }

sub x_while {
  my ($c, $x, $k) = @_; my $until = exists $x->{until};
  loop($c, $k, sub { my ($c, $next, $end) = @_;
    x_list(cond($c), $x->{while} // $x->{until}, undef, sub {
      ($_[0] == 0) != $until ? x_list($c, $x->{do}, undef, $next) : $end->() }) }) }

sub x_for {
  my ($c, $x, $k) = @_;
  expand_list($c, $x->{in} // [[['"$', '@']]], 'argv', sub {
    my @w = @{$_[0]};
    loop($c, $k, sub { my ($c, $next, $end) = @_;
      return $end->() unless @w;
      setvar($c, $x->{for}, shift @w) or return; x_list($c, $x->{do}, undef, $next) }) }) }

sub x_case {
  my ($c, $x, $tail, $k) = @_; my @in = @{$x->{in}};
  expand_str($c, $x->{case}, sub { my $s = shift;
    sub { return defer($k, 0) unless @in;
      my ($pats, $l) = splice @in, 0, 2; my $next = __SUB__; my @p = @$pats;
      sub { return $next->() unless @p;
        my $again = __SUB__;
        pattern_re($c, shift @p, sub { $s =~ $_[0] ? x_list($c, $l, $tail, $k) : $again->() }) }->() }->() }) }

sub pattern_re {   # a case (or ${N%p}) pattern as a regex anchored at both ends: quoted parts literal
  my ($c, $w, $k) = @_;
  my @parts = ref $w ? @$w : ($w); my $re = ''; my $i = 0;
  sub {
    return $k->(eval { qr/\A$re\z/s } // qr/\A\Q$re\E\z/s) if $i > $#parts;
    my $x = $parts[$i++]; my $next = __SUB__;
    return $re .= quotemeta($x), $next->() unless ref $x;
    if ($x->[0] eq '*') { $re .= glob_re($x->[1]); return $next->() }
    expand($c, [$x], 'str', sub { $re .= $x->[0] =~ /^"/ ? quotemeta $_[0][0] : glob_re($_[0][0]); $next->() }) }->() }
sub glob_re {
  my $g = shift; my $re = '';
  while ($g =~ /\G(?:(\*)|(\?)|(\[!?\]?(?:\[:[a-z]+:\]|[^\]])*\])|\\(.)|(.))/gcs) {
    $re .= defined $1 ? '.*' : defined $2 ? '.' : defined $3 ? do { (my $b = $3) =~ s/^\[!/[^/; $b }
         : quotemeta($4 // $5) }
  $re }

sub setvar {   # 1, or 0 after ending the shell (a readonly variable, as dash)
  my ($c, $n, $v) = @_; my $sh = $c->{sh};
  return do { fail($c, 2, "$n: is read only"); 0 } if $sh->{ro}{$n};
  $sh->{exp}{$n} = 1 if $sh->{opt}{a}; $sh->{vars}{$n} = $v; 1 }

sub x_set {   # NAME=value ... alone, or with redirections (D2: as dash, redirect first; failed: no setting, status 2)
  my ($c, $x, $k) = @_; my @s = @{$x->{set}};
  return redirect($c, $x->{redir}, sub { my ($m, $opened) = @_ or return defer($k, 2);   # the values are expanded with
    my $d = derive($c, $m); release($_) for @$opened;                                      # the redirections in force
    x_set($d, { set => $x->{set} }, sub { release_ctx($d); $k->(@_) }) }) if $x->{redir};   # (rule E: category effect)
  delete $c->{sh}{qsub};
  sub { return defer($k, $c->{sh}{qsub} // 0) unless @s;
        my ($n, $w) = splice @s, 0, 2; my $next = __SUB__;
        expand_str($c, $w, sub { setvar($c, $n, shift) or return; $next->() }) }->() }

sub x_cd {
  my ($c, $x, $k) = @_;
  my $go = sub {
    my @f = @_; my $d = @f ? $f[0] : var($c, 'HOME');
    my $dash = @f == 1 && $d eq '-' and $d = var($c, 'OLDPWD');   # cd -: back, and print where
    return defer($k, 0) if @f == 1 && $d eq '';
    return msg($c, "cd: too many arguments", sub { $k->(1) }) if $x->{cd_extra};   # as bash (rule E)
    return msg($c, "cd: HOME not set", sub { $k->(1) }) if !@f && ($d // '') eq '';   # as bash (rule E; N4)
    if (@f > 1 or $d =~ /^-/ && !$dash) { return msg($c, "cd: bad argument", sub { $k->(2) }) }
    my $new = $d =~ m{^/} ? $d : "$c->{sh}{cwd}/$d";
    if ($x->{cd_p}) { $new = -d $new && Cwd::realpath($new) }   # cd -P: symbolic links resolved, '..' physical (P6)
    else { my @p; for (split m{/+}, $new) { next if $_ eq '' or $_ eq '.'; $_ eq '..' ? pop @p : push @p, $_ }
      $new = '/' . join '/', @p }
    $new && -d $new or return msg($c, "cd: can't cd to $d", sub { $k->(2) });
    setvar($c, OLDPWD => $c->{sh}{cwd}) && setvar($c, PWD => $new) or return; $c->{sh}{cwd} = $new;
    $dash ? put($c, 1, "$new\n", sub { $k->(0) }) : defer($k, 0) };
  defined $x->{cd} ? expand($c, $x->{cd}, 'argv', sub { $go->(@{$_[0]}) }) : $go->() }

sub x_simple {
  my ($c, $x, $tail, $k) = @_;
  $k = sub { leave($c, shift) } if $x->{exec};   # exec cmd: then the shell ends
  my @env = @{$x->{env} // []}; my %env;
  delete $c->{sh}{qsub};
  my $settings = sub {   # NAME=value before the command, left to right, each seeing the ones before
    my $next = shift;
    sub { return $next->() unless @env;
          my ($n, $w) = splice @env, 0, 2; my $again = __SUB__;
          my $v = { %$c, sh => { %{$c->{sh}}, vars => { %{$c->{sh}{vars}}, %env } } };
          expand_str($v, $w, sub { $env{$n} = shift; $c->{sh}{qsub} = $v->{sh}{qsub} if exists $v->{sh}{qsub}; $again->() }) }->() };
  $settings->(sub { expand_list($c, $x->{argv}, 'argv', sub {
    my @argv = @{$_[0]};
    return redirect($c, $x->{redir} // [], sub {   # every word expanded to nothing: the redirections are still done
      my ($m, $opened) = @_ or return defer($k, 2); release($_) for @$opened; defer($k, $c->{sh}{qsub} // 0) }) unless @argv;
    redirect($c, $x->{redir} // [], sub {
      my ($m, $opened) = @_;
      if (!$m) { return $SPECIAL{$argv[0]} ? leave($c, 2) : defer($k, 2) }
      if (my $e = $c->{sh}{cmd}{$argv[0]} // cmd_of($argv[0])) {   # a function or a builtin, in this process
        my $d = derive($c, $m); release($_) for @$opened;          # a context holds its fds until it is done
        if ($SPECIAL{$argv[0]}) { setvar($c, $_, $env{$_}) or return for sort keys %env; %env = () }   # these settings stay
        return handler($e->[0])->($d, \@argv, \%env, sub { release_ctx($d); $k->(@_) }, $e->[1]) }
      my $node = spawn($c, $m, \@argv, \%env, $k);
      $c->{sh}{job}{first} //= $node->{pid} if $node && $c->{sh}{job};
      release($_) for @$opened; after_start($tail) }) }) }) }

sub builtin {   # : exit break continue read
  my ($c, $argv, $env, $k) = @_; my $m = $c->{map};
  my ($n, @a) = @$argv;
  return defer($k, 0) if $n eq ':';
  return leave($c, @a ? $a[0] % 256 : $c->{sh}{q}) if $n eq 'exit';   # exit 1000: 232, as both shells (parser item P4)
  if ($n eq 'break' || $n eq 'continue') {
    my $l = $c->{loops}; my $j = @a ? $a[0] : 1;
    release_all(map $_->{scope}, @$l[$#$l - $j + 1 .. $#$l]);
    return defer($l->[-$j]{$n eq 'break' ? 'brk' : 'cont'}) }
  if ($n eq 'read') { return read_line($c, $m, $env, \@a, $k) }
  die "Proc::ShellSpawn: builtin $n" }

# read [-r] [-p PROMPT] NAME...: one line from fd 0, one byte at a time (later commands get the rest), split
# as sh does: IFS blanks around fields are dropped, one other IFS character ends a field, the last
# NAME gets the rest of the line; without -r a backslash protects the next character, and a
# backslash before the newline continues the line.  Status 1 at end of file.  The prompt of -p goes to fd 2,
# and only when fd 0 is a terminal, as in both shells (P6).
sub read_line {
  my ($c, $m, $env, $names, $k) = @_; my @a = @$names; my ($raw, $prompt);
  while (@a && $a[0] =~ /^-(r*)(p?)\z/ && "$1$2" ne '') { shift @a; $raw ||= $1 ne ''; $prompt = shift @a if $2 }
  my $e = $m->{0} or return defer($k, 1);
  my $ifs = $env->{IFS} // $c->{sh}{vars}{IFS} // " \t\n";
  my %ws = map +($_ => 1), grep /[ \t\n]/, split //, $ifs;
  my %nw = map +($_ => 1), grep !/[ \t\n]/, split //, $ifs;
  my $line = '';
  my $got = sub {
    my $eof = shift;
    my @ch;   # [character, protected by a backslash]
    if ($raw) { @ch = map [$_, 0], split //, $line }
    else { push @ch, defined $1 ? [$1, 1] : [$2, 0] while $line =~ /\G(?:\\(.)|([^\\]))/gs }
    my $isws = sub { !$_[0][1] && $ws{$_[0][0]} }; my $isnw = sub { !$_[0][1] && $nw{$_[0][0]} };
    my $i = 0; $i++ while $i < @ch && $isws->($ch[$i]);
    for my $j (0 .. $#a) {
      if ($j == $#a) {   # the rest; a single trailing delimiter after the only field is dropped, as in dash
        my @r = @ch[$i .. $#ch]; pop @r while @r && $isws->($r[-1]);
        if (@r && $isnw->($r[-1]) && !grep $isws->($_) || $isnw->($_), @r[0 .. $#r - 1]) { pop @r; pop @r while @r && $isws->($r[-1]) }
        setvar($c, $a[$j], join '', map $_->[0], @r); last }
      my $f = ''; $f .= $ch[$i++][0] while $i < @ch && !$isws->($ch[$i]) && !$isnw->($ch[$i]);
      setvar($c, $a[$j], $f);
      $i++ while $i < @ch && $isws->($ch[$i]);
      if ($i < @ch && $isnw->($ch[$i])) { $i++; $i++ while $i < @ch && $isws->($ch[$i]) } }
    defer($k, $eof ? 1 : 0) };
  my $go = sub { on_read($e, 1, sub {
    my $b = shift;
    return $got->(1) unless defined $b;
    if ($b eq "\n") {   # continued if the line ends in an odd number of backslashes
      return $got->(0) if $raw or ($line =~ /(\\*)\z/)[0] =~ tr/\\// % 2 == 0;
      chop $line; return on_read($e, 1, __SUB__) }
    $line .= $b; on_read($e, 1, __SUB__) }) };
  defined $prompt && $e->{fh} && -t $e->{fh} ? put($c, 2, $prompt, $go) : $go->() }

# ------------------------------------------------------------------ entry points
sub start_pwd {
  my $phys = Cwd::getcwd();
  my $p = $ENV{PWD};
  return $p if defined $p && $p =~ m{^/} && (stat $p)[1] && join(':', (stat $p)[0, 1]) eq join(':', (stat '.')[0, 1]);
  $phys }

# run(STRING or TREE, parser => CODE, interactive => 'nop' or 'dash'): sh's status, or (undef, ERROR) if STRING is
# outside the subset.  The parser also reads the text of eval, . and trap actions (with the aliases defined so far:
# parser->(TEXT, aliases => {NAME => VALUE})).  interactive: what history, fc, bind, help, compopt, logout and
# set -o history do (B2): nothing (nop, the default; give the parser the same option) or as in dash (not found).
require Proc::ShellSpawn::Builtins;
sub run {
  my ($s, %o) = @_; my $parse = $o{parser} // default_parser(); a4();
  my $tree = ref $s ? $s : $parse->($s);
  return (undef, $tree) if ref $tree eq 'HASH';
  my $cwd = start_pwd();
  # dash sets OPTIND and IFS when it starts (L3)
  my $sh = { vars => { %ENV, PWD => $cwd, OPTIND => 1, IFS => " \t\n", PPID => getppid() }, exp => { map +($_ => 1), keys %ENV, 'PWD' }, cwd => $cwd, q => 0,
             parse => $parse, args => [], pid => $$, opt => {}, cmd => {}, ro => {}, trap => {}, jobl => [], umask => umask,
             alias => {}, hash => {}, intext => 0, interactive => $o{interactive} // 'nop' };
  my $st;
  my $c = { sh => $sh, loops => [], map => { map +($_ => is_open($_) ? own_fd($_) : undef), 0 .. 2 } };
  my $scope = []; $c->{shell} = { scope => $scope, exit => shell_exit($c, $scope, sub { $st //= shift }) };
  $sh->{die} = sub { $st //= shift };   # kill ... $$ (Proc::ShellSpawn::Large::b_kill): the whole string ends
  local %TRAPSAVE = (); $SIGNALLED = undef;   # signals the trap builtin changed: put back afterwards
  ignoring_int(sub { x_list($c, $tree, undef, $c->{shell}{exit}); loop_until(sub { defined $st }) });
  $SIG{$_} = $TRAPSAVE{$_} for keys %TRAPSAVE;
  %$c = ();
  $st }

1;
