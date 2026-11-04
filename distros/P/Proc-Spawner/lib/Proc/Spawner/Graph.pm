package Proc::Spawner::Graph;
our $VERSION = '0.04';
# EXPERIMENTAL.  The companion of Proc::Spawner: the spawn graph, which is what gets executed.  It says,
# for the current moment, which of our children and which of our own reads and writes use which open
# file, and carries on each process what to do when it ends.  That reaction may start new processes,
# each with its own reaction, close ends, read and write; so the graph grows and shrinks as it runs.
#
#   end   an open file the parent keeps for its children or for its own reads and writes:
#         { kind => 'r' | 'w' | 'file' | 'parent', fd => N, fh => HANDLE while open, n => HOLDS, what => TEXT,
#           pipe => NAME, peer => the other half (weak)    r and w
#           mode => '<' '>' '>>' '<>' '>|', path => PATH   file; parent: its access
#           forgotten => 1 once the parent has closed it,  g => the graph (weak) }
#         'parent': the parent's own fd N, which it never closes.  The others are close-on-exec, so a
#         child gets only what its fd table gives it.  Whoever needs an end holds it (hold); the last
#         release closes it.
#   proc  a child: { name, pid, argv => TEXT, edges => [[CHILD_FD, OP, END, KEEP], ...], on_exit => HANDLER,
#           st => 'pending' | 'running' | 'exited N' | 'signal N' | 'lost' | 'never', after => [PROC (weak), WORD] }
#         'after': the process whose end led to this start (for the pictures).
#   io    Perl's own reads and writes, $g->{io} = { ID => [END, '<' or '>'] }; drawn as the process 'Perl'.
#
# HANDLER: a code ref, or [NAME, DATA...] with NAME a fully qualified sub name (its module is loaded at
# first use).  Called from Proc::Spawner's queue, one at a time, never waiting:
#   on_exit                HANDLER->(GRAPH, PROC, WAIT STATUS or undef, DATA...)
#   perl_read, perl_write  HANDLER->(GRAPH, BYTES or undef at end of file, DATA...), HANDLER->(GRAPH, DATA...)
# No strong reference cycles: the graph holds its processes, a process its ends and its HANDLER (with
# its DATA); ends refer back only weakly.  So DATA must not hold the graph: a handler gets it as an argument.
use strict; use warnings; use feature 'current_sub';
use Scalar::Util qw(refaddr weaken);
use Fcntl qw(F_SETFD FD_CLOEXEC F_GETFL O_RDONLY O_WRONLY O_RDWR O_CREAT O_TRUNC O_APPEND O_NONBLOCK S_ISFIFO);
use POSIX ();
use Proc::Spawner;

sub tr_ { &Proc::Spawner::tr_ }
our %OPEN = ('<' => O_RDONLY, '>' => O_WRONLY|O_CREAT|O_TRUNC, '>|' => O_WRONLY|O_CREAT|O_TRUNC,
             '>>' => O_WRONLY|O_CREAT|O_APPEND, '<>' => O_RDWR|O_CREAT);
my %RD = ('<' => 1, '<>' => 1);
my %WR = ('>' => 1, '>>' => 1, '>|' => 1, '<>' => 1);

sub new { my ($class, %o) = @_; bless { procs => [], io => {}, own => {}, pipes => 0, dot => $o{dot}, pics => 0 }, $class }

my %HANDLER;
sub handler {
  my $n = shift;
  $HANDLER{$n} //= do { no strict 'refs';
    unless (defined &$n) { (my $m = $n) =~ s/::[^:]+\z//; $m =~ s{::}{/}g; require "$m.pm" }
    \&$n } }
sub call { my ($h, @a) = @_; ref $h eq 'CODE' ? $h->(@a) : handler($h->[0])->(@a, @$h[1 .. $#$h]) }

# ------------------------------------------------------------------ ends
sub adopt {   # end $e gets the handle $fh, with one hold
  my ($g, $e, $fh, $what) = @_;
  fcntl($fh, F_SETFD, FD_CLOEXEC);   # also when Perl gave it an fd <= $^F
  @$e{qw(fd fh n what)} = (fileno $fh, $fh, 1, $what); delete $e->{forgotten}; weaken($e->{g} = $g); $e }
sub peers { my @e = @_; $e[0]{peer} = $e[1]; $e[1]{peer} = $e[0]; weaken($_->{peer}) for @e; @e }
sub new_pipe {   # (read end, write end)
  my $g = shift; pipe my $r, my $w or return; my $n = ++$g->{pipes};
  my @e = peers(map +{ kind => $_, pipe => $n }, qw(r w));
  adopt($g, $e[0], $r, "pipe $n read end"); adopt($g, $e[1], $w, "pipe $n write end");
  tr_("pipe $n: read end fd $e[0]{fd}, write end fd $e[1]{fd}"); @e }
sub file_end {   # the end for a file the caller opened as $fh
  my ($g, $fh, $mode, $path) = @_;
  my $e = adopt($g, { kind => 'file', mode => $mode, path => $path }, $fh, "file '$path' ($mode)");
  tr_("open fd $e->{fd} = '$path' ($mode)"); $e }
sub parent_end {   # the parent's own fd N
  my ($g, $n) = @_;
  $g->{own}{$n} //= { kind => 'parent', fd => $n, n => 0, what => "our fd $n", mode => access($n) } }
sub access {   # '<', '>' or '<>': how fd N was opened (read through a copy, so N stays untouched)
  my $d = POSIX::dup(shift) // return '<>';
  open my $h, '<&=', $d or return POSIX::close($d), '<>';
  (qw(< > <>))[fcntl($h, F_GETFL, 0) & 3] // '<>' }
sub hold { $_[0]{n}++ if $_[0] }
sub release {
  my $e = shift or return;
  return if !$e->{fh} or --$e->{n} > 0;
  tr_("close fd $e->{fd} ($e->{what})"); close delete $e->{fh}; $e->{forgotten} = 1;
  $e->{g}->event("close $e->{what}") if $e->{g} }
sub op_of { my $e = shift; { r => '<', w => '>' }->{$e->{kind}} // ($e->{mode} =~ /^(<>|<)\z/ ? "$1" : '>') }

# ------------------------------------------------------------------ processes
# start(PATH, ARGV, ENVP, MAP, %opt): the started process node, or undef with $!.  MAP: { CHILD_FD => end,
# or undef for closed }; other fds are inherited as they are.  %opt: on_exit => HANDLER, node => a
# pending node to start (a hand-written graph's), and Proc::Spawner::start's chdir, umask, sigdefault.
sub start {
  my ($g, $path, $argv, $envp, $map, %o) = @_;
  my $node = delete $o{node};
  my %fds = map +($_ => $map->{$_} && $map->{$_}{fd}),   # an fd of ours under its own number: inherited
    grep { my $e = $map->{$_}; !($e && $e->{kind} eq 'parent' && $e->{fd} == $_) } keys %$map;
  my $n = $node // { argv => "@$argv",
    edges => [map [$_, op_of($map->{$_}), $map->{$_}], grep defined $map->{$_}, sort { $a <=> $b } keys %$map] };
  my $pid = Proc::Spawner::start($path, $argv, $envp, \%fds, %o, on_exit => sub { exited($g, $n, shift) }) or return;
  @$n{qw(pid st on_exit)} = ($pid, 'running', $o{on_exit});
  $n->{name} //= "p$pid";
  if (ref(my $c = $Proc::Spawner::CAUSE) eq 'ARRAY') { $n->{after} = [@$c]; weaken($n->{after}[0]) }
  push @{$g->{procs}}, $n unless $node;
  $g->event("start $n->{argv}"); $n }
sub exited {
  my ($g, $n, $w) = @_;
  $n->{wait} = $w;
  $n->{st} = !defined $w ? 'lost' : POSIX::WIFSIGNALED($w) ? 'signal ' . POSIX::WTERMSIG($w) : 'exited ' . POSIX::WEXITSTATUS($w);
  $g->event("exit $n->{argv} ($n->{st})"); $g->prune;
  local $Proc::Spawner::CAUSE = [$n, $n->{st}];   # processes started by the reaction are drawn after this one
  call($_, $g, $n, $w) for delete $n->{on_exit} // () }

# Perl's own reads and writes of an end
sub perl_read {   # one read of at most $len bytes
  my ($g, $e, $len, $h) = @_; my $id;
  $id = Proc::Spawner::on_read($e->{fd}, $len, sub { delete $g->{io}{$id}; call($h, $g, @_) });
  $g->{io}{$id} = [$e, '<']; $id }
sub perl_write {   # to a pipe or FIFO through an open file of our own, made non-blocking: the flag on the
  # shared one would reach the children writing to it too (L10).  Linux: /proc/self/fd/N opens anew.
  my ($g, $e, $bytes, $h) = @_; my ($id, $nb);
  my $to = S_ISFIFO((POSIX::fstat($e->{fd}))[2] // 0)
           && (sysopen($nb, "/proc/self/fd/$e->{fd}", O_WRONLY|O_NONBLOCK) ? $nb : $e->{fh}) || $e->{fd};
  $id = Proc::Spawner::on_write($to, $bytes, sub { undef $nb; delete $g->{io}{$id}; call($h, $g) });
  $g->{io}{$id} = [$e, '>']; $id }

# An ended process stays while it shares an end, or a pipe, with a process still to run or with one of
# our own reads and writes; then it is dropped, so a long loop does not grow the graph.
sub ends_of { map +($_->[2], $_->[2]{peer} // ()), @{$_[0]{edges}} }
sub prune {
  my $g = shift; my $live = qr/^(?:pending|running)/;
  my %live = map +(refaddr $_ => 1), (map ends_of($_), grep $_->{st} =~ $live, @{$g->{procs}}),
                                     map +($_->[0], $_->[0]{peer} // ()), values %{$g->{io}};
  @{$g->{procs}} = grep $_->{st} =~ $live || grep($live{refaddr $_}, ends_of($_)), @{$g->{procs}} }

sub event {   # with dot => DIR: the graph now, as DIR/trace-001.dot, ...
  my $g = shift; defined(my $dir = $g->{dot}) or return;
  my %seen; my @io = grep !$seen{refaddr $_->[0]}++, values %{$g->{io}};
  my $what = join ' and ', ('reading') x !!grep($_->[1] eq '<', @io), ('writing') x !!grep($_->[1] eq '>', @io);
  my @p = (@{$g->{procs}}, @io ? { name => 'Perl', argv => $what, edges => [map ['', $_->[1], $_->[0]], @io] } : ());
  my $f = sprintf '%s/trace-%03d.dot', $dir, ++$g->{pics};
  open my $o, '>', $f or return warn "$f: $!\n";
  print $o to_dot({ procs => \@p }, sprintf '%03d: %s', $g->{pics}, "@_") }

# ------------------------------------------------------------------ the notation
#   pipe NAME [r:forgotten] [w:forgotten]     the ends NAME.r and NAME.w
#   file NAME MODE PATH [forgotten]           MODE: < > >> <> >|
#   PROC: ARGV ... | EDGES | after PROC WORD | STATE
#       EDGES: FD<END FD>END FD<>END, a '+' after END: drawn as 'keep'; END: NAME.r NAME.w NAME, or @N (the parent's fd N)
#       STATE: running, exited N (drawing only); none: not started
#       after PROC WORD: started when PROC has ended; WORD fail: if non-zero, ok: if zero, else always
#   Perl: WHAT | <END                         the parent itself reading (or >END writing) an end
# Arguments are split at blanks; quoting is not done yet.
sub parse {
  my (%end, @procs, @after); my $ln = 0;
  my $bad = sub { die "$_[0] at line $ln\n" };
  for (split /\n/, shift) {
    $ln++; s/#.*//; s/^\s+|\s+$//g; next unless length;
    if (/^pipe (\w+)(.*)/) {
      my ($n, %st) = ("$1", map /^([rw]):forgotten\z/ ? ("$1", 1) : $bad->("bad pipe state '$_'"), split ' ', "$2");
      @end{"$n.r", "$n.w"} = peers(map +{ kind => $_, pipe => $n }, qw(r w));
      $end{"$n.$_"}{forgotten} = 1 for keys %st }
    elsif (/^file (\w+) (<>|>>|>\||<|>) (\S+)(?: (forgotten))?\z/) {
      $end{$1} = { kind => 'file', mode => "$2", path => "$3", $4 ? (forgotten => 1) : () } }
    elsif (/^(\w+): (.*)/) {
      my ($n, $argv, $edges, @rest) = ("$1", split /\s*\|\s*/, "$2");
      my $p = { name => $n, argv => $argv, edges => [], st => 'pending' };
      for (split ' ', $edges // '') {
        my ($fd, $op, $e, $keep) = /^(\d*)(<>|>>|>\||<|>)([\w.@]+)(\+?)\z/ or $bad->("bad edge '$_'");
        push @{$p->{edges}}, [$fd, $op, $end{$e} //= $e =~ /^@(\d+)\z/ ? { kind => 'parent', fd => "$1" }
                                                                      : $bad->("unknown end '$e'"), $keep] }
      for (@rest) { /^after (\w+)\s*(.*)/ ? push @after, [$p, "$1", "$2"] : ($p->{st} = $_) }
      push @procs, $p }
    else { $bad->("cannot read '$_'") } }
  my %byname = map +($_->{name} => $_), @procs;
  for (@after) { $_->[0]{after} = [$byname{$_->[1]} // die("after: no process $_->[1]\n"), $_->[2] || 'then']; weaken($_->[0]{after}[0]) }
  bless { procs => \@procs, ends => \%end, io => {}, own => {}, pipes => 0, pics => 0 } }

# ------------------------------------------------------------------ running a hand-written graph
# run($g, bin => DIR): runs the parsed graph $g on the engine.  Each process is started as DIR/ARGV0
# with its arguments and exactly its edges; one with 'after' is started by the reaction of that one,
# or never ('never') if WORD does not match.  The parent closes its copy of an end when no process
# still to start uses it.  Returns { PROC_NAME => status, ... } and, for 'Perl', what it read from each end.
sub run {
  my ($g, %o) = @_;
  my ($perl) = grep $_->{name} eq 'Perl', @{$g->{procs}};
  @{$g->{procs}} = grep $_->{name} ne 'Perl', @{$g->{procs}};
  my @procs = @{$g->{procs}}; $_->{st} = 'pending' for @procs;   # a state written in the notation is for drawing
  my %ends = map +(refaddr $_->[2] => $_->[2]), map @{$_->{edges}}, @procs, $perl // ();
  for my $e (grep $_->{kind} ne 'parent', values %ends) {
    next if $e->{fh};
    if ($e->{kind} eq 'file') { sysopen my $fh, $e->{path}, $OPEN{$e->{mode}}, 0666 or die "$e->{path}: $!\n"; adopt($g, $e, $fh, "file $e->{path}") }
    else { my ($r, $w) = $e->{kind} eq 'r' ? ($e, $e->{peer}) : ($e->{peer}, $e);
           pipe my $rh, my $wh or die "pipe: $!\n"; adopt($g, $r, $rh, "pipe $r->{pipe} read end"); adopt($g, $w, $wh, "pipe $w->{pipe} write end") } }
  hold($_->[2]) for map @{$_->{edges}}, @procs, $perl // ();   # each user holds its ends; the creator lets go
  my %all = map +(refaddr $_ => $_), map +($_, $_->{peer} // ()), values %ends;
  release($_) for grep $_->{kind} ne 'parent', values %all;
  my %got;
  for my $e (map $_->[2], @{$perl ? $perl->{edges} : []}) { $got{refaddr $e} = ''; $g->perl_read($e, 65536, [__PACKAGE__ . '::collect', $e, \%got]) }
  launch($g, $_, $o{bin}) for grep !$_->{after}, @procs;
  Proc::Spawner::wait_until(sub { !grep($_->{st} eq 'running', @procs) && !%{$g->{io}} });
  my %res = map +($_->{name} => ($_->{wait} >> 8 || $_->{wait} & 127)), grep defined $_->{wait}, @procs;
  $res{Perl} = { map +($_->[2]{pipe} // $_->[2]{path} => $got{refaddr $_->[2]}), @{$perl->{edges}} } if $perl;
  \%res }
sub launch {
  my ($g, $p, $bin) = @_; my ($name, @args) = split ' ', $p->{argv};
  $g->start("$bin/$name", [$name, @args], undef, { map +($_->[0] => $_->[2]), @{$p->{edges}} },
            node => $p, on_exit => [__PACKAGE__ . '::then', $bin]) or die "spawn $name: $!\n";
  release($_->[2]) for @{$p->{edges}} }
sub then {   # on_exit of a hand-written graph's process: the processes after it
  my ($g, $p, $w, $bin) = @_; my $st = ($w // 0) >> 8 || ($w // 0) & 127;
  for my $q (grep $_->{st} eq 'pending' && $_->{after} && $_->{after}[0] == $p, @{$g->{procs}}) {
    my $word = $q->{after}[1];
    if ($word eq 'fail' ? $st : $word eq 'ok' ? !$st : 1) { launch($g, $q, $bin) }
    else { $q->{st} = 'never'; release($_->[2]) for @{$q->{edges}} } } }
sub collect {   # Perl's read of a hand-written graph's end: all of it
  my ($g, $b, $e, $got) = @_;
  return release($e) unless defined $b;
  $got->{refaddr $e} .= $b; $g->perl_read($e, 65536, [__PACKAGE__ . '::collect', $e, $got]) }

# ------------------------------------------------------------------ drawing
sub q_ { (my $s = "@_") =~ s/([&<>"])/'&#'.ord($1).';'/ge; $s }
sub id { 'e' . refaddr shift }

sub to_dot {   # Graphviz source for $g; $caption under the picture
  my ($g, $caption) = @_;
  my @procs = @{$g->{procs}};
  my %shown = map +(refaddr $_ => 1), @procs;
  my @edges = map { my $p = $_;   # an fd a child inherits unchanged from the parent is not drawn
    [$p, grep !($_->[2]{kind} eq 'parent' && $_->[0] eq $_->[2]{fd}), @{$p->{edges}}] } @procs;
  my (%end, %pipe, %first);
  for my $i (reverse 0 .. $#edges) { my ($p, @e) = @{$edges[$i]};
    for (@e) { $end{refaddr $_->[2]} = $_->[2]; $first{refaddr $_->[2]} = $i if $RD{$_->[1]} } }
  for my $e (values %end) { push @{$pipe{$e->{pipe}}}, $e if defined $e->{pipe} }
  my $dotted = sub { $_[0]{forgotten} ? 'dotted' : 'solid' };
  my @L = ('digraph G {', ' rankdir=' . ($ENV{RANKDIR} || 'LR') . '; nodesep=0.25; ranksep=0.45; bgcolor="transparent"; fontname="Helvetica";',
    ' node [fontname="Helvetica", fontsize=11, color="black", fontcolor="black"];',
    ' edge [fontname="Helvetica", fontsize=10, color="black", fontcolor="black", arrowsize=0.7];',
    defined $caption ? (sprintf ' label="%s"; labelloc=b; fontsize=10;', q_($caption)) : ());
  for my $e (sort { refaddr $a <=> refaddr $b } grep !defined $_->{pipe}, values %end) {
    push @L, sprintf ' %s [shape=%s, label="%s", style=%s];', id($e),
      $e->{kind} eq 'parent' ? ('cds', "Perl's fd $e->{fd}") : ('note', q_("$e->{mode} $e->{path}")), $dotted->($e) }
  for my $n (sort keys %pipe) {
    my %h = map +($_->{kind} => $_), map +($_, $_->{peer} // ()), @{$pipe{$n}};
    my ($r, $w) = map $h{$_} // { kind => $_, forgotten => 1 }, qw(r w);   # a half nobody holds any more
    my $cid = $n =~ s/\W/_/gr;
    push @L, " subgraph cluster_$cid {", qq(  label="pipe $n"; style="rounded,dashed"; color="#888888"; fontcolor="#888888"; fontsize=10;);
    push @L, sprintf '  %s [shape=circle, width=0.32, fixedsize=true, label="%s", style=%s];', id($_), $_->{kind}, $dotted->($_) for $w, $r;
    push @L, sprintf('  %s -> %s [penwidth=2.2, arrowhead=none];', id($w), id($r)), ' }' }
  for my $i (0 .. $#edges) {
    my ($p, @e) = @{$edges[$i]}; my $pn = 'P_' . ($p->{name} =~ s/\W/_/gr); my $st = $p->{st} // 'pending';
    if ($p->{name} eq 'Perl') { push @L, sprintf ' %s [shape=box, style="rounded,filled", fillcolor="#88888822", label="Perl: %s"];', $pn, q_($p->{argv}) }
    else {
      my @in = grep $RD{$_->[1]} && !$WR{$_->[1]}, @e; my @o = grep $WR{$_->[1]}, @e;
      my $rows = (@in > @o ? @in : @o) || 1;
      my $cell = sub { my ($side, $x) = @_; $x ? qq{<TD PORT="$side$x->[0]" BORDER="1" CELLPADDING="2">$x->[0]</TD>} : '<TD></TD>' };
      my $ended = $st !~ /^(pending|running|never)/;
      my $mid = q_($p->{argv}) . ($st ne 'pending' ? '<BR/><FONT POINT-SIZE="9">' . q_($st) . '</FONT>' : '');
      my $html = '<TABLE BORDER="0" CELLBORDER="0" CELLSPACING="0"' . ($ended ? ' BGCOLOR="#88888833"' : '') . '>';
      $html .= '<TR>' . $cell->(i => $in[$_]) . ($_ ? '' : qq{<TD ROWSPAN="$rows" CELLPADDING="5">$mid</TD>}) . $cell->(o => $o[$_]) . '</TR>' for 0 .. $rows - 1;
      push @L, sprintf ' %s [shape=box, style=%s, margin=0, label=<%s</TABLE>>];', $pn,
        { pending => 'dashed', never => 'dashed', running => 'bold' }->{$st} // 'solid', $html }
    for (@e) {
      my ($fd, $op, $e, $keep) = @$_;
      my $k = $keep ? ', color="#2b7bb9", penwidth=2.2, label="keep", fontcolor="#2b7bb9"' : '';
      # a write into a pipe read by an earlier process closes a loop: drawn without pulling the layout
      $k .= ', constraint=false' if $e->{kind} eq 'w' && $e->{peer} && ($first{refaddr $e->{peer}} // 1e9) < $i;
      my $id = id($e);
      push @L, $fd eq '' ? ($RD{$op} ? " $id -> $pn [style=bold$k];" : " $pn -> $id [style=bold$k];")
        : !$WR{$op} ? " $id -> $pn:i$fd:w [arrowhead=normal$k];"
        : " $pn:o$fd:e -> $id [" . ($RD{$op} ? 'dir=both' : 'arrowhead=normal') . "$k];" }
    if (my ($q, $word) = @{$p->{after} // []}) {
      push @L, sprintf ' P_%s -> %s [style=dashed, color="#c07000", fontcolor="#c07000", label="%s", constraint=false];',
        $q->{name} =~ s/\W/_/gr, $pn, q_($word) if $q && $shown{refaddr $q} } }
  join '', map "$_\n", @L, '}' }

1;
