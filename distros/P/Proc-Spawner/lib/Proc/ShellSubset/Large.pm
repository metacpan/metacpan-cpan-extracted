package Proc::ShellSubset::Large;  # The large subset (doc/large-subset/large-subset-spec.md): Proc::ShellSubset, and where it rejects, a wider grammar
our $VERSION = '0.02';
use strict; use warnings; use Proc::ShellSubset; use List::Util qw(pairs pairvalues);

# Proc::ShellSubset::Large::parse($string, %opt) returns a List, or { error, pos, last, tree } as Proc::ShellSubset::parse does.
# It first asks Proc::ShellSubset (with if while for case read assign param_ops on); only if that rejects the string does
# it parse it again by the large grammar: Proc::ShellSubset's own code with some of its subs and tables replaced for the
# time of the parse. %opt: as for Proc::ShellSubset, except brace (dropped: brace expansion is bash only).
# Tree, in addition to Proc::ShellSubset's (keys only when non-empty):
# Command  = { func => NAME, body => Command }                    f() { ...; } and the like, with the body's redir
#          | { export => [NAME, Word or undef, ...] } | { readonly => [...] } | { local => [NAME, Word, ...] }
#          | { exec => 1, redir => [Redir, ...] }                  exec with redirections only
#          | { argv => [], redir => [...] }                        redirections alone (> file)
#          | { set => [...], redir => [...] }   settings with redirections (no $ or ` in them): redirect, then set
#          | { argv => [...], ... }: argv->[0] may now be a Word with expansions; exec => 1 may stand anywhere
# Redir    = [ fd, '<<', Word ]   a here-document: the Word is its body (tabs already removed for <<-); no splitting
# Part     = [ '$', N ] and [ '${', N, OP, Word ] also for N = 0-9, @ * # $ (and 10... braced)
#          | [ '${', NAME, OP, Word ]   OP also = := ? :? % %% # ##   (in a % or # Word, ['*', ...] parts are pattern)
#          | [ "'", 'text' ]   quoted text in the Word of an unquoted ${x:-word}: not split
#          $((...)) text may hold assignments (= += ... >>=) and $1, ${10}, $#, $$

my @OPTS = qw(if while for case read assign param_ops);
sub parse {
  my ($s, %o) = @_; delete $o{brace};
  return { error => '/dev/tcp or /dev/udp (bash opens a socket)', pos => $-[0], last => 0, tree => [] }
    if $s =~ m{[<>]&?[ \t]*["']?/dev/(?:tcp|udp)/};   # before Proc::ShellSubset too, which takes it for a file
  my $t = Proc::ShellSubset::parse($s, %o, map +($_ => 1), @OPTS);
  ref $t eq 'HASH' && $t->{error} !~ /^starts with - or \+/ ? Proc::ShellSubset::large($s, %o, map +($_ => 1), @OPTS) : $t }

package Proc::ShellSubset;   # the replacements run inside Proc::ShellSubset, with its variables
our (%O, $M, @OPEN, $ATT, $LAST, $LOOP, $FORALL, %KW, %BI, %SH, $NM, $END, $B, $BN, %EX);
our ($FUNC, @HD, $AP, $NOAT, %LOC, %UNSET) = 0;   # depth of function bodies; here-document bodies not yet used;
    # position of the command; true where "$@" would join with IFS (dash) or blanks (bash); names made local; unset
my ($o_command, $o_word, $o_bq) = (\&command, \&word, \&bq);   # the originals, called by the replacements
my %LBI = map +($_ => 1), qw(alias unalias times ulimit jobs fg bg hash type fc chdir source let declare typeset
  shopt enable builtin caller dirs pushd popd disown mapfile readarray suspend logout help history bind compgen
  complete compopt);                                                   # builtins the large subset still leaves to sh
my %OWN = map +($_ => 1), qw(: . break cd command continue eval exec exit export getopts local read readonly
  return set shift trap umask unset wait);                             # builtins it runs itself
my %NOFN = map +($_ => 1), qw(break continue eval exec exit export readonly return set shift times trap unset
  local source cd);   # no function by these names: special builtins (dash: also local, bash: source); cd: a node
my %TS = map +($_ => 1), qw(0 1 2 3 6 13 14 15 EXIT HUP INT QUIT ABRT PIPE ALRM TERM USR1 USR2);   # trap signals
my %SETO = map +($_ => 1), qw(errexit nounset noglob noclobber allexport);
my $PN = qr/$NM|[0-9]+|[?!#\$@*]/;   # what ${...} may name
my $DELIM = qr/(?:'[^']*'|"(?:[^"\\]|\\.)*"|\\.|[^ \t\n;&|()<>'"\\`])+/s;   # a here-document delimiter as written
my $ARITH = qr{(?(DEFINE)                    # $((...)) with assignments (F10) and positional parameters
  (?<w>   [ \t\n]* )
  (?<num> (?: 0[xX][0-9a-fA-F]+ | 0[0-7]* | [1-9][0-9]* ) (?![0-9A-Za-z_]) )
  (?<v>   \$? [A-Za-z_][A-Za-z0-9_]* | \$\{ (?: [A-Za-z_][A-Za-z0-9_]* | [0-9]+ | [?!#\$] ) \} | \$[0-9?!#\$] )
  (?<atom> (?&w) (?: [-+!~] (?&w) )* (?: (?&num) | (?&v) | \( (?&e) (?&w) \) ) )
  (?<op>  (?&w) (?: << | >> | <= | >= | == | != | && | \|\| | [-+*/%<>&^|] ) )
  (?<c>   (?&atom) (?: (?&op) (?&atom) )* (?: (?&w) \? (?&e) (?&w) : (?&c) )? )
  (?<e>   (?&w) [A-Za-z_][A-Za-z0-9_]* (?&w) (?: << | >> | [-+*/%&^|] )? = (?!=) (?&e) | (?&c) ) )}x;

sub status { @_ > 1 || @_ && !ref $_[0] && ($_[0] !~ /^(?:0|[1-9][0-9]{0,2})\z/ || $_[0] > 255) ? 'unsupported exit status' : '' }
my %CHK = (   # literal arguments of the builtins run by the large subset: (arguments) -> reason to reject, or ''
  '.'     => sub { @_ == 1 ? '' : "'.' with other than one argument" },
  exit    => \&status,
  return  => sub { $FUNC ? &status : "'return' outside a function" },
  shift   => sub { @_ > 1 || @_ && !ref $_[0] && $_[0] !~ /^[0-9]+\z/ ? "unsupported 'shift' form" : '' },
  wait    => sub { (grep !ref && !/^[0-9]+\z/, @_) ? "unsupported 'wait' argument" : '' },
  umask   => sub { @_ > 1 || @_ && !ref $_[0] && $_[0] !~ /^[0-7]{1,4}\z/ ? "unsupported 'umask' form" : '' },
  command => sub { my $f = $_[0] // return q{};   # command alone; command -v NAME; command PROGRAM ...: no builtin
    ref $f || $f eq '-v' && @_ == 2 || $f !~ /^-/ && !$OWN{$f} && !$LBI{$f} ? '' : "unsupported 'command' form" },
  getopts => sub { @_ < 2 ? "'getopts' without a variable name" : ref $_[1] ? ''
    : $_[1] =~ /^$NM\z/ ? vname($_[1], $AP) && '' : "unsupported 'getopts' name" },
  unset   => sub { my $f = ($_[0] // '') =~ /^-[vf]\z/ && shift;
    @_ or return "'unset' without a name";
    for (@_) { next if ref; /^$NM\z/ or return "unsupported 'unset' argument"; $f eq '-f' or $UNSET{vname($_, $AP)} //= $AP } '' },
  set     => sub { @_ or return "'set' without arguments (it lists)";
    while (defined(my $o = shift)) { return '' if ref $o || $o eq '--' || $o !~ /^[-+]/;   # operands follow
      if ($o =~ /^[-+]o\z/) { my $n = shift; return '' if ref $n; $SETO{$n // ''} or return "unsupported 'set -o' form" }
      elsif ($o !~ /^[-+][eufCa]+\z/) { return "unsupported 'set' option '$o'" } } '' },
  trap    => sub { @_ >= 2 or return "'trap' with fewer than two arguments (it lists)";
    my $x = shift; return "unsupported 'trap' form" if !ref $x && $x =~ /^-.|^[0-9]+\z/;   # trap 1 2: a signal
    return 'trap action outside the subset' if !ref $x && $x =~ /\S/ && $x ne '-' && ref large($x, %O) ne 'ARRAY';
    (grep !ref && !$TS{$_}, @_) ? "unsupported signal for 'trap'" : '' });

sub large {   # the large grammar: Proc::ShellSubset::parse with replacements
  my ($s, %o) = @_; no warnings 'redefine'; my $chk = delete $o{check};
  my $why = $s =~ /\0/ ? ['NUL character', $-[0]] : $chk && $chk->($s) ? [$chk->($s), 0] : undef;
  my ($t, $map, @hd) = $why ? () : eval { hdcut($s) }; $why //= $@ if ref $@;
  return { error => $$why[0], pos => $$why[1], last => 0, tree => [] } if $why;
  local (@HD, $FUNC, $NOAT, %LOC, %UNSET, $FORALL) = (@hd); ($FUNC, $FORALL) = (0, 1);
  local %BI = %LBI; local %SH = %SH; delete @SH{qw(IFS OPTIND OLDPWD)};
  local *P = sub { my $p = shift; $M ? $$M[$p] // $$M[-1] : $map ? $$map[$p] // $$map[-1] : $p };
  local *simple = \&l_simple; local *command = \&l_command; local *dollar = \&l_dollar; local *redir = \&l_redir;
  local *arith = \&l_arith; local *vname = \&l_vname; local *word = \&l_word; local *xc = sub {};
  local *bq = sub { local $NOAT; &$o_bq };   # a $( ) or `...` starts afresh
  my $r = parse($t, %o);
  if (ref $r eq 'ARRAY') {   # bodies read for a << that turned out to be text; unset of a name some function made local
    @HD and return { error => 'here-document body not used', pos => $HD[0][2], last => 0, tree => $r };
    my ($n) = grep $LOC{$_}, sort { $UNSET{$a} <=> $UNSET{$b} } keys %UNSET;
    return { error => "unset of '$n', which a function makes local", pos => $UNSET{$n}, last => 0, tree => $r } if $n }
  $r->{last} = $$map[$r->{last}] if ref $r eq 'HASH' && $map;
  $r }

my $HDQ = qr/\G(?: (?<bn>\\\n) | \\. | (?<cq>") | \$\(\((?<ar>(?:[^()]++|\((?&ar)\))*)\)\) | (?<op>\$\() | (?<bq>`) | [^"\\\$`]+ | . )/sx;   # inside "..."
my $HCODE = qr/\G(?: '[^']*' | (?<oq>") | (?<bn>\\\n) | \\. | \$\(\((?<ar>(?:[^()]++|\((?&ar)\))*)\)\)
       | (?<![^ \t\n;&|()<>])\#[^\n]* | <<(?!<)(?<t>-?)[ \t]*(?<d>$DELIM) | (?<nl>\n) | (?<op>\$?\() | (?<cl>\))
       | (?<bq>`) | [^'"\\\$#<\n()`]+ | . )/sx;
sub hdcut {   # cut out the here-document bodies, and each \-newline outside '...' and comments (D2):
  my $s = shift; my (@pend, @hd, $t, @m, $inbq, @st, $cut); my ($at, $depth) = (0, 0);   #   (the rest, its
  my $skip = sub { my ($from, $to) = @_; $t .= substr $s, $at, $from - $at; push @m, $at .. $from - 1;   # position
    ($at, $cut) = ($to, 1) };                                                                     # map or undef, bodies)
  while (@st && $st[-1] eq 'q' ? $s =~ /$HDQ/gc : $s =~ /$HCODE/gc) {   # @st: open "...", as 'q', and the depths of $(
    if (defined $+{bn}) { $skip->($-[0], pos $s) }                       #   opened in them
    elsif (defined $+{ar}) { my ($i, $e) = ($-[0], pos $s);             # \-newline inside $(( ))
      $skip->($i, $i + 2), $i += 2 while ($i = index $s, "\\\n", $i) >= 0 && $i < $e }
    elsif (defined $+{oq}) { push @st, 'q' }
    elsif (defined $+{cq}) { pop @st }
    elsif (defined $+{d}) {   # [delimiter as written, <<-, position, depth in ( and $(]
      die [$inbq ? 'here-document inside backquotes' : 'here-document delimiter with an expansion', $-[0]] if $inbq || $+{d} =~ /\$/;
      push @pend, [$+{d}, $+{t}, $-[0], $depth] }
    elsif (defined $+{op}) { push @st, $depth if @st && $st[-1] eq 'q'; $depth++ }
    elsif (defined $+{cl}) { $depth--; die ["here-document in a '(' or '\$(' that ends on its line", $pend[-1][2]] if @pend && $depth < $pend[-1][3];
                             pop @st if @st && $st[-1] ne 'q' && $st[-1] == $depth }
    elsif (defined $+{bq}) { $inbq = !$inbq }
    elsif (defined $+{nl} && @pend) {
      my $b0 = pos $s; $t .= substr $s, $at, $b0 - $at; push @m, $at .. $b0 - 1;
      for (splice @pend) {   # body: [delimiter as written, Word (string) or [text, map], position]
        my ($raw, $tab, $p) = @$_; my ($body, $cont, @bm) = ('');
        my $lit = $raw =~ /['"\\]/;
        (my $d = $raw) =~ s{'([^']*)'|"((?:[^"\\]|\\.)*)"|\\(.)}{$1 // (defined $2 ? $2 =~ s/\\([\$`"\\])/$1/gr : $3)}gse;
        while (1) {
          $s =~ /\G([^\n]*)(\n?)/gc && ($1 ne '' || $2 ne '') or die ['unterminated here-document', $p];
          my ($line, $nl, $c0) = ($1, $2, $-[1]);
          if ($tab && !$cont) { $line =~ s/^(\t*)//; $c0 += length $1 }
          last if !$cont && $line eq $d;
          $cont = !$lit && $nl && $line =~ /(?<!\\)(?:\\\\)*\\\z/;   # an unquoted body joins a line ending in \
          $body .= $line . $nl; push @bm, $c0 .. $c0 + length($line . $nl) - 1 }
        push @hd, [$raw, $lit ? $body : [$body, [@bm, pos $s]], $p] }
      $at = pos $s } }
  @hd || $cut or return $s;
  $t .= substr $s, $at; push @m, $at .. length($s);
  ($t, \@m, @hd) }

sub l_vname { my ($n, $p) = @_; E("assignment to '$n'", $p) if $n =~ /^(?:HOME|CDPATH)\z/; name($n, $p) }

sub l_word { local $NOAT = $NOAT || $_[0] =~ /[er]/; &$o_word }   # a setting's value, a redirection target

sub at_in { my $w = shift; ref $w and grep ref && $$_[0] =~ /^"?\$\{?\z/ && $$_[1] eq '@', @$w }

sub bqdq {   # after '`' inside "${...}" or a here-document: \" there is " in bash, \" in dash
  my $p = shift; /\G((?:[^`\\]|\\.)*)/s and $1 =~ /\\"/ and E('\\" in backquotes here (dash and bash differ)', $p) }

sub l_command {   # NAME() COMPOUND-COMMAND is a function definition (F1); anything else as in Proc::ShellSubset
  my $pl = shift; my $p = pos;
  unless (/\G($NM)$B\($B\)$BN/gc) {
    my $c = $o_command->($pl);
    E("'\$\@' as the word of 'case'", $p) if ref $c && exists $c->{case} && at_in($c->{case});   # joined: IFS or blank
    return $c }
  my $n = $1; E("function named '$n'", $p) if $KW{$n} || $NOFN{$n};
  /\G(?=[{(]|(?:if|while|until|for|case)$END)/ or E('function body not a compound command', pos);
  my @b; push @$pl, my $c = { func => $n, body => \@b }; local $FUNC = $FUNC + 1; local $LOOP = 0;
  { local $OPEN[@OPEN] = \@b; $o_command->(\@b) } $c->{body} = $b[0];
  $c }

sub l_simple {
  my $pl = shift; my (@env, @np, @av, @ap, @r, $kw, @dv); my $p0 = pos;   # @dv: NAME, Word or undef (declarations)
  push @$pl, my $c = { argv => \@av }; local $OPEN[@OPEN] = \@av;
  while (/\G$B/gc, !/\G(?=[;&|()\n]|\z)/) {
    my $p = pos;
    if (my $r = redir()) { push @r, $r }
    elsif (!@av and /\G($NM)(\+?)=/gc) { E("'$1+='", $p) if $2; my $n = $1; push @np, $n, $p; push @env, $n, word(q{e}) }
    elsif (@av && $kw =~ /^(?:export|readonly|local)\z/) {                 # NAME[=value]: no splitting (F5)
      /\G($NM)(?:(=)|$END)/gc or E("unsupported '$kw' argument", $p);
      my ($n, $eq) = ($1, $2); push @dv, vname($n, $p), $eq ? word(q{e}) : undef }
    else { push @av, word('a'); push @ap, $p; $kw //= substr $_, $p, pos() - $p } }
  vname(@$_) for pairs @np;                                              # settings may outlast special builtins
  if (!@av) {   # settings alone, redirections alone (D2), or both: dash redirects before it expands the values,
    @env || @r or E('missing command', $p0);                             #   bash after; so both only with no $ or `
    E("'&>' (dash: '&', then a redirection; bash: both outputs)", $p0 - 1) if !@env && $p0 && substr($_, $p0 - 1, 2) eq '&>' && substr($_, $p0 - 2, 1) ne '&';
    E("an input redirection without a command (bash: \$(<file) reads the file)", $p0) if !@env && grep $$_[1] =~ /^</, @r;
    E('settings with a redirection, and a $, ` or here-document (dash redirects first, bash expands first)', $p0)
      if @env && @r && (substr($_, $p0, pos() - $p0) =~ /[\$`]/ || grep $$_[1] eq '<<', @r);
    return %$c = (@env ? (set => \@env) : (argv => []), @r ? (redir => \@r) : ()) }
  E("keyword '$kw'", $ap[0]) if $KW{$kw};                                # also when it is a pattern, as [[ is
  E("'NAME[' as a command (bash reads an array)", $ap[0]) if $kw =~ /^$NM\[/;
  if (!ref $av[0] && $av[0] eq 'exec') {                                 # anywhere: it ends the shell (F3)
    shift @av; shift @ap;
    if (!@av) { @r && !@env or E("'exec' without a command", $p0); return %$c = (exec => 1, redir => \@r) }
    E("unsupported 'exec' form", $ap[0]) if !ref $av[0] && ($av[0] =~ /^-/ || $OWN{$av[0]} || $LBI{$av[0]});
    $c->{exec} = 1 }
  elsif (!ref(my $n = $av[0])) {                                          # a literal name; else decided at run time
    local $AP = $ap[0];
    if ($n =~ /^(?:break|continue)\z/) {
      E("'$n' outside a loop", $AP) unless $LOOP;
      E("unsupported '$n' form", $AP) if @env || @r || @av > 2 || @av == 2 && ($av[1] !~ /^[1-9][0-9]*\z/ || $av[1] > $LOOP) }
    elsif ($n eq 'read') {                                                 # read [-r] NAME...
      my $i = ($av[1] // '') eq '-r' ? 2 : 1;
      $i <= $#av or E("'read' without a variable name", $AP);
      for my $j ($i .. $#av) { $av[$j] =~ /^$NM\z/ or E("unsupported 'read' argument", $ap[$j]); vname($av[$j], $ap[$j]) } }
    elsif ($BI{$n}) { E("builtin '$n'", $AP) }
    elsif ($n =~ /^(?:export|readonly|local)\z/) {
      @dv && !@env && !@r or E(@dv ? "settings or redirections on '$n'" : "'$n' without arguments, or quoted", $AP);
      if ($n eq 'local') { $FUNC or E("'local' outside a function", $AP);
        E("'local NAME' without a value", $AP) if grep !defined, pairvalues @dv; $LOC{$_->[0]} = 1 for pairs @dv }
      return %$c = ($n => \@dv) }
    elsif ($n eq 'cd') {
      @av <= 2 && !@env && !@r && !defined $ENV{CDPATH} && (ref $av[1] || ($av[1] // '') !~ /^-./)
        or E('unsupported cd form', $AP);                                  # 'cd -' is allowed (F12)
      return %$c = (cd => $av[1]) }
    if (my $chk = $CHK{$n}) { E($_, $AP) for grep $_, $chk->(@av[1 .. $#av]) } }
  $c->{env} = \@env if @env; $c->{redir} = \@r if @r;
  $c }

sub l_redir {   # Proc::ShellSubset's, plus here-documents (F4)
  my $p = pos;
  E('process substitution (bash)', $p) if /\G[<>]\(/;
  E('here-string (bash)', $p) if /\G[0-9]*<<</;
  /\G([0-9]*)(<<-?|>>|<>|>\||<&|>&|<|>)$B/gc or return;
  E('target followed by a redirection operator (dash: a descriptor)', pos) if /\G[0-9]+[<>]/;   # x >&2>f (U4)
  my ($n, $op) = ($1, $2);
  E('multi-digit descriptor', $p) if length $n > 1 && !$O{fdmulti};
  my $fd = length $n ? 0 + $n : $op =~ /^</ ? 0 : 1;
  return [$fd, $op, /\G([0-9-])$END/gc ? $1 : E("'$op' takes one digit or '-'", pos)] if $op =~ /&/;
  return [$fd, $op, word('r')] if $op !~ /^<</;
  /\G($DELIM)/gc or E('missing here-document delimiter', pos);
  my $h = shift @HD; $h && $$h[0] eq $1 or E('here-document body not found', $p);
  my $bd = $$h[1]; ref $bd or return [$fd, '<<', $bd];                   # quoted delimiter: the body is literal
  my @s; local $_ = $$bd[0]; local $M = $$bd[1]; local $NOAT = 1;        # as inside "...", but " is ordinary
  until (/\G\z/gc) {
    next if /\G\\\n/gc;
    if    (/\G(?:([^\\\$`]+)|\\([\$`\\])|(\\))/gc) { push @s, $+ }
    elsif (/\G([\$`])/gc) { my $x = $1; bqdq(pos() - 1) if $x eq '`'; push @s, $EX{$x}->('"', pos() - 1) } }
  [$fd, '<<', mkword(@s)] }

sub l_dollar {   # after '$': Proc::ShellSubset's forms, plus $1 $# $@ $* $$ and all POSIX ${...} forms (F1, F2, F9)
  my ($q, $p) = @_;
  return '$' unless /\G[A-Za-z_0-9{(@*#?\$!\[-]/ or !$q && /\G['"]/;
  return [$q . '$((', arith($p)] if /\G\(\(/gc;
  if (/\G\(/gc) { local $NOAT; my $l = shell(')', []); /\G\)/gc; return [$q . '$(', $l] }
  if (/\G(?|\{($PN)\}|($NM|[0-9?!#\$@*]))/gc) {
    E("'\$\@' where it is not split (dash joins with IFS, bash with blanks)", $p) if $1 eq '@' && $NOAT;
    return [$q . '$', name("$1", $p)] }
  return [$q . '${#', name("$1", $p)] if /\G\{#($NM|[0-9]+)\}/gc;
  if (!/\G\{#/ && /\G\{($PN)(:?[-+=?]|%%?|##?)/gc) {                    # not ${##} ${#-} ...: lengths in sh
    my ($n, $op) = ($1, $2);
    E("'$op' on '\$$n' (dash: on the joined string, bash: on each)", $p) if $n =~ /[@*]/ && $op =~ /[%#]/;
    E("'\$\@' where it is not split (dash joins with IFS, bash with blanks)", $p) if $n eq '@' && $NOAT;
    $op =~ /=/ ? $n =~ /^$NM\z/ ? vname($n, $p) : E("assignment to '\$$n'", $p) : name($n, $p);
    local $NOAT = $NOAT || $q || $op =~ /=/;
    return [$q . '${', $n, $op, pword($q, $op =~ /[%#]/)] }
  E(/\G['"\[]/ ? 'bash-only $ form' : 'unsupported parameter form', $p) }

sub pword {   # the Word of ${NAME OP word}, up to its '}'; $pat: a % or # form, whose Word is a pattern
  my ($q, $pat) = @_; my @s;   # [kind, text]: u(nquoted) q(uoted) g(lob character) x(pansion)
  until (/\G\}/gc) {
    my $p = pos;
    next if /\G\\\n/gc;
    if    (/\G([^"'\\~*?\[{}\$`\n]+)/gc) { push @s, [u => $1] }
    elsif (/\G([\$`])/gc) { my $x = $1; bqdq($p) if $x eq '`' && $q; push @s, [x => $EX{$x}->($q, $p)] }
    elsif (/\G\\(.)/sgc) { my $c = $1; push @s, $q && !$pat && $c !~ /[\$`"\\}]/ ? [u => "\\$c"] : [q => $c] }
    elsif (/\G'/gc) { push @s, $q && !$pat ? [u => "'"] : /\G([^']*)'/gc ? [q => $1] : E('unterminated quote', $p) }
    elsif (/\G"/gc) { push @s, [q => '']; dq(\@s, $p) }
    elsif ($pat && /\G([*?])/gc) { push @s, [g => $1] }
    elsif ($pat && /\G\[/gc) { push @s, /\G(!?\]?[^\] \t\n;&|()<>'"\\\$`{}^\/,]*\])/gc ? [g => "[$1"] : [u => '['] }
    else  { E(/\G\z/ ? "unterminated '\${'" : 'unsupported character in a ${...} word', $p) } }
  my $k = join '', map $$_[0], @s; my @v;
  if ($pat) { push @v, defined $1 ? ['*', join '', map $$_[1], splice @s, 0, length $1] : (shift @s)->[1]
                while $k =~ /([ug]*g[ug]*)|./g }
  else { while ($k =~ /(q+)|./g) { my $t = join '', map $$_[1], my @x = splice @s, 0, length($1 // 1);
           push @v, !defined $1 ? $x[0][1] : $q ? $t : ["'", $t] } }   # quoted text in an unquoted ${...}: not split
  mkword(@v) }

sub l_arith {   # after '$((': the grammar with assignments; a variable assigned to must be assignable
  my $p = shift;
  /\G((?&e))(?&w)\)\)$ARITH/gc && $1 !~ /\+\+|--/ or E('bad arithmetic expression', $p);
  my $t = $1;
  while ($t =~ /\b($NM)(?=[ \t\n]*(?:<<|>>|[-+*\/%&^|])?=(?!=))|\b($NM)/g) { defined $1 ? vname("$1", $p) : name("$2", $p) }
  $t }

1;
__END__

=head1 NAME

Proc::ShellSubset::Large - parse as much of POSIX sh as dash and bash run alike (EXPERIMENTAL)

=head1 SYNOPSIS

  use Proc::ShellSubset::Large;
  my $t = Proc::ShellSubset::Large::parse('f() { local x=$1; echo "${x%.c}"; }; for a; do f "$a"; done');

=head1 DESCRIPTION

C<parse($string, %options)> returns a tree or an error hash, as L<Proc::ShellSubset/parse> does. It first asks
L<Proc::ShellSubset> (with C<if>, C<while>, C<for>, C<case>, C<read>, C<assign> and C<param_ops> on); only if
that rejects the string does it parse it again by a wider grammar. It adds, among others: function
definitions, C<local>, C<export>, C<readonly>, C<unset>, C<set>, C<shift>, C<eval>, C<.>, C<trap>, C<wait>,
C<umask>, C<command>, C<getopts>, C<return>, C<exec> with redirections only, positional parameters and all
POSIX parameter forms, here-documents, command names from expansions, assignments in arithmetic, redirections
without a command, and backslash-newline anywhere.

Where dash and bash differ, the construct is rejected (rule A3 of the specification), so that the caller
can hand the string to C</bin/sh>. A construct outside the subset that shows up only at run time makes
L<Proc::ShellSpawn> stop that shell with status 248 (rule A4); differences that show up only at run time
follow dash (rule A5).

Options: those of L<Proc::ShellSubset>, except C<brace> (brace expansion is bash only).

The specification, with the tree additions, is F<doc/large-subset/large-subset-spec.md>; the corpus
measurements are in F<doc/large-subset/large-subset-ceiling.md>.

=head1 SEE ALSO

L<Proc::ShellSubset>, L<Proc::ShellSpawn>, F<doc/large-subset/README.md>.

=cut
