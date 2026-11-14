package Proc::ShellSubset;  # Parser for the Bourne-shell subset of doc/parsers/shell-subset-spec.md
our $VERSION = '0.12';
use strict; use warnings; use List::Util qw(pairs pairvalues);

# Proc::ShellSubset::parse($string, %opt) returns a List, or { error => '...', pos => N, last => N, tree => List }:
# 'last' is the position after the last top-level ';', '&' or newline, 'tree' the part parsed so far, with
# { ERROR => 1 } where parsing failed (an 'exec' in the wrong place gets ERROR => 1 in its own hash; an 'exec'
# not checked yet when parsing failed has exec => its position, which may be 0: test the key with exists).
# %opt: nocaret (reject ^, as the Bourne shell reads it as |), nopwd (reject $PWD), check (sub: returns a reason to reject), empty (accept
# an empty string), fdmulti (multi-digit fds), tilde_args (~ after NAME= in arguments),
# brace (parse brace expansion), assign (commands with only settings), param_ops (${x:-w} ${x-w} ${x:+w} ${x+w} ${#x}),
# if (if/elif/else), while (while, until; break and continue inside), for (for NAME in ...; break, continue), case, read.
#
# List     = [ AndOr, ... ]
# AndOr    = [ Pipeline, '&&' | '||', Pipeline, ..., '&' (only if in background) ]
# Pipeline = [ '!' (only if negated), Command, ... ]
# Command  = { argv => [Word, ...], env => [NAME, Word, ...], redir => [Redir, ...], exec => 1 }
#          | { sub => List, redir => [...] } | { group => List, redir => [...] } | { cd => Word | undef }
#          (Proc::ShellSubset::Large adds cd_p => 1 for 'cd -P')
#          | { set => [NAME, Word, NAME, Word, ...] }   (option assign)
#          | { if => [Cond, Then, Cond, Then, ..., Else (if present)] }   (Cond, Then, Else: Lists; option if)
#          | { while => Cond, do => List } | { until => Cond, do => List }   (option while)
#          | { for => NAME, in => [Word, ...], do => List }   (option for)
#          | { case => Word, in => [[Word, ...], List, [Word, ...], List, ...] }   (patterns, body; option case)
#            (all compound commands may also have redir => [...]; break, continue and read are simple commands)
#            (keys only when non-empty; argv->[0] is a plain string; cd alone has cd => undef)
# Redir    = [ fd, op, Word ]   (for <& and >&: [ fd, op, 'digit or -' ])
# Word     = 'literal text' | [ Part, ... ]
# Part     = 'literal text' | [ '$', NAME or '?' or '!' ] | [ '$((', 'expr' ] | [ '$(', List ]
#          | [ '${', NAME, ':-' | '-' | ':+' | '+', Word ] | [ '${#', NAME ]   (option param_ops)
#          | the same five with '"' in front ('"$' ...) when inside double quotes
#          | [ '~', 'user' or '' ] | [ '*', 'pattern text' ]
#          | [ '{', Word, Word, ... ] | [ '{..', from, to ]

our ($CUT, $SRC, $LOFF, @ASH) = (0, '', 0);   # P1, set by Proc::ShellSubset::Large: stop after this line; the text; lines before
sub opos { my $q = shift; $q -= $$_[1] for grep $$_[0] <= $q, @ASH; P($q) }   #   it; [where, how much] alias values moved the rest (B1)
our (%O, $M, @OPEN, $ATT, $LAST, $LOOP, $FORALL, $RLIT);   # options; position map of a backquote's inside;
    # arrays being filled (for the partial tree); how many of them are in the tree; end of the last top-level chain;
    # depth of the loops around the current command in its shell; Proc::ShellSubset::Large: 'for NAME' loops over "$@",
    # and a pattern in a redirection target is literal text (P6: dash, and bash in POSIX mode, do not expand it)
our %KW = map +($_ => 1), qw(if then else elif fi case esac for while until do done in [[ ]] function select coproc !);
our %BI = map +($_ => 1), qw(. break continue eval export readonly return set shift times trap unset alias
  unalias read wait umask ulimit jobs fg bg command getopts hash type fc chdir local source let declare
  typeset shopt enable builtin caller dirs pushd popd disown mapfile readarray suspend logout help
  history bind compgen complete compopt);
our %SH = map +($_ => 1), qw(IFS PS1 PS2 PS4 OPTIND PPID OLDPWD LINENO _ BASH BASHOPTS BASHPID DIRSTACK
  EPOCHREALTIME EPOCHSECONDS EUID FUNCNAME GROUPS HISTCMD HOSTTYPE MACHTYPE OPTERR OSTYPE PIPESTATUS
  POSIXLY_CORRECT RANDOM SECONDS SHELLOPTS SHLVL SRANDOM UID);
our $NM  = qr/[A-Za-z_][A-Za-z0-9_]*/;
our $END = qr/(?=[ \t\n;&|()<>]|\z)/;
our $B   = qr/(?:[ \t]|\\\n|#.*)*+/;           # blanks, line continuations, a comment
our $BN  = qr/(?:[ \t\n]|\\\n|#.*)*+/;        # the same, and newlines
our %STOP = (b => qr/\G(?:(?=[,}])|$END)/, map +($_ => qr/\G$END/), qw(a e r));
our $PIECE = qr/\G(?: '(?<sq>[^']*)' | (?<dq>") | \\(?<bs>.) | (?<ex>[\$`]) | (?<gl>[*?]) | (?<br>\[)
  | (?<cb>\{(?!\})) | (?<ti>~) | (?<ca>\^) | (?<lit>(?:\{\}|[^ \t\n;&|()<>'"\\\$`*?\[{}^~,\x00-\x1f\x7f])+|,) | (?<bad>.) )/sx;   # {} is literal (C2)
our $ARITH = qr{(?(DEFINE)                    # the expression grammar of $((...))
  (?<w>   [ \t\n]* )
  (?<num> (?: 0[xX][0-9a-fA-F]+ | 0[0-7]* | [1-9][0-9]* ) (?![0-9A-Za-z_]) )
  (?<atom> (?&w) (?: [-+!~] (?&w) )* (?: (?&num) | \$? [A-Za-z_][A-Za-z0-9_]* | \$\{[A-Za-z_][A-Za-z0-9_]*\} | \$[?!] | \$\{[?!]\}
            | \( (?&e) (?&w) \) ) )                     # $NAME, ${NAME}: substituted as text first (C9)
  (?<op>  (?&w) (?: << | >> | <= | >= | == | != | && | \|\| | [-+*/%<>&^|] ) )
  (?<e>   (?&atom) (?: (?&op) (?&atom) )* (?: (?&w) \? (?&e) (?&w) : (?&e) )? ) )}x;

our %EX = (q{$} => sub { dollar(@_) }, q{`} => sub { bq(@_) });   # the expansion a $ or ` starts: ($q, $p) -> Part; by name, so Proc::ShellSubset::Large can replace them

sub P  { my $p = shift; $M ? $$M[$p] // $$M[-1] : $p }   # position in the original
sub E  { push @{$OPEN[$ATT // -1]}, { ERROR => 1 } if @OPEN; die [shift, P(shift)] }
sub U  { /\G$B/gc; E(/\G(.)/s ? 'unexpected ' . ($1 eq "\n" ? 'newline' : "'$1'") : 'unexpected end', pos) }
sub parse {
  my $s = shift; local %O = @_; local ($M, @OPEN, $ATT); local $LAST = 0; my @l;
  my $t = eval {
    local $_ = $s;
    E('NUL character', $-[0]) if /\0/;
    E(q{starts with - or +: sh would read it as options}, $-[1]) if /\A[ \t\n\r\f\cK]*([-+])/;   # Perl skips leading white space, then runs sh -c STRING (U1)
    if ($O{check} and my $why = $O{check}->($s)) { E($why, 0) }
    shell('', \@l);
    @l or $O{empty} or E('empty command', 0); \@l };
  $t // (ref $@ eq 'ARRAY' ? { error => $@->[0], pos => $@->[1], last => $LAST, tree => \@l } : die $@) }

sub list {   # up to ')' (subshell, $()), a word in $t ('\}', 'then', 'elif|else|fi', ...), or the end ('')
  my ($t, $l) = @_; local $OPEN[@OPEN] = $l; my $top = !$t && !$M;   # fills @$l in place
  my $e = ref $t ? $t : $t eq ')' ? qr/\G(?=\))/ : $t ? qr/\G(?=(?:$t)$END)/ : qr/\G\z/;   # or a ready regex
  while (/\G$BN/gc, !/$e/) {        # (zero-length /gc matches can't repeat at one place: test with plain //)
    push @$l, my $c = []; andor($c);
    if    (/\G$B&(?!&)/gc)          { push @$c, '&' }
    elsif (!/\G$B(?:;(?!;)|\n)/gc) { /\G$B/gc, /$e/ ? last : U() }
    $LAST = pos if $top;
    if ($top && $CUT && substr($_, pos() - 1, 1) eq "\n" and /\G$BN/gc, !/$e/) {   # P1 (Proc::ShellSubset::Large): an alias
      my $p = opos(pos);                                                      #   definition known only when it runs: the rest
      push @$l, [[{ rest => substr($SRC, $p), lineoff => $LOFF + (substr($SRC, 0, $p) =~ tr/\n//) }]]; last } }   #   of the text, parsed then
  $l }

sub shell {   # a list that runs in a shell of its own: the loops around it don't count, and exec is checked at its end
  local $LOOP = 0; my $l = list(@_); xc($l, 1); $l }

sub andor {
  my $ao = shift; local $OPEN[@OPEN] = $ao;
  do { push @$ao, my $p = []; pipeline($p) } while /\G$B(&&|\|\|)$BN/gc && push @$ao, $1 }

sub pipeline {
  my $p = shift; local $OPEN[@OPEN] = $p;
  push @$p, '!' if /\G!(?=[ \t])$B/gc;
  E("'! !'", pos) if @$p && /\G!$END/;
  do { command($p) } while /\G$B\|(?![|&])$BN/gc;
  my ($q, @c) = (pos, grep ref, @$p);   # each element of a longer pipeline is a subshell: break/continue can't reach the loop
  @c > 1 and ($_->{argv} && $_->{argv}[0] // q{}) =~ /^(?:break|continue)\z/ and E("'$_->{argv}[0]' in a pipeline", $q) for @c }

sub kw { /\G$BN/gc; /\G$_[0]$END/gc }   # a reserved word, after blanks and newlines
sub part {   # a list up to one of the words in $t, into a new array pushed onto @$to; must not be empty
  my ($to, $t, $what, $p) = @_; push @$to, my $l = []; list($t, $l); @$l or E("empty $what", $p); $l }
sub body {   # a loop's 'do' list up to 'done', one loop deeper for break and continue
  my ($c, $p) = @_; local $LOOP = $LOOP + 1;
  list('done', $c->{do}); @{$c->{do}} or E('empty loop body', $p); kw('done') }
sub vname {   # a variable the string sets: by assignment (C5), for or read
  my ($n, $p) = @_; E("assignment to '$n'", $p) if $n =~ /^(?:HOME|CDPATH|PPID)\z/; name($n, $p) }   # PPID: read-only in bash

sub compound {   # if, while, until, for, case (each with its option); pushes the node onto @$pl
  my ($pl, $p) = @_; my $c;
  if ($O{if} && /\Gif$END/gc) {
    push @$pl, $c = { if => my $arms = [] };
    do { part($arms, 'then', 'condition', $p); kw('then'); part($arms, 'elif|else|fi', "'then' part", $p) } while kw('elif');
    part($arms, 'fi', "'else' part", $p) if kw('else');
    kw('fi') }
  elsif ($O{while} && /\G(while|until)$END/gc) {
    push @$pl, $c = { $1 => my $cond = [], do => [] };
    list('do', $cond); @$cond or E('empty condition', $p); kw('do'); body($c, $p) }
  elsif ($O{for} && /\Gfor$END/gc) {
    /\G$B/gc; my $q = pos; /\G($NM)$END/gc or E("'for' needs a variable name", $q);
    push @$pl, $c = { for => vname("$1", $q), in => my $in = [], do => [] };
    if (kw('in')) { { local $OPEN[@OPEN] = $in; push @$in, word('a') while /\G$B/gc, !/\G(?=[;\n]|\z)/ }
                    /\G$B[;\n]/gc or U() }
    else { $FORALL or E("'for' without 'in' (it would loop over \$@)", pos);   # for NAME: as for NAME in "$@"
           push @$in, ['', ['"$', '@']]; /\G$B[;\n]/gc }
    kw('do') or U(); body($c, $p) }
  elsif ($O{case} && /\Gcase$END/gc) {
    push @$pl, $c = { case => '', in => my $in = [] }; local $OPEN[@OPEN] = $in;
    /\G$B/gc; $c->{case} = word('a'); kw('in') or U();
    until (kw('esac')) {
      /\G\(/gc; push @$in, my $pat = [];
      { local $OPEN[@OPEN] = $pat; do { /\G$B/gc; push @$pat, word('a') } while /\G$B\|/gc }
      /\G$B\)/gc or U(); push @$in, my $l = []; list(qr/\G(?=;;|esac$END)/, $l); /\G;;/gc } }
  $c }

sub command {   # pushes the command onto the pipeline @{$_[0]}
  my $pl = shift; my $p = pos; my $c;
  E("'((' at the start of a command", $p) if /\G\(\(/;
  if (/\G\(/gc) {
    push @$pl, $c = { sub => my $l = [] };
    shell(')', $l); /\G\)/gc; @$l or E('empty subshell', $p) }
  elsif (/\G\{(?=[ \t\n])/gc) {
    push @$pl, $c = { group => my $l = [] };
    list('\}', $l); /\G\}/gc; @$l or E('empty group', $p) }   # xc: by the parent
  else { $c = compound($pl, $p) or return simple($pl) }
  my ($r, @r); push @r, $r while /\G$B/gc, $r = redir();
  $c->{redir} = \@r if @r;
  $c }

sub redir {   # a redirection, or nothing (pos unchanged) if none starts here
  my $p = pos;
  E('process substitution (bash)', $p) if /\G[<>]\(/;
  /\G([0-9]*)(<<|>>|<>|>\||<&|>&|<|>)$B/gc or return;
  E('target followed by a redirection operator (dash: a descriptor)', pos) if /\G[0-9]+[<>]/;   # x >&2>f (U4)
  my ($n, $op) = ($1, $2);
  E('here-document', $p) if $op eq '<<';
  E('multi-digit descriptor', $p) if length $n > 1 && !$O{fdmulti};
  my $fd = length $n ? 0 + $n : $op =~ /^</ ? 0 : 1;
  return [$fd, $op, /\G([0-9-])$END/gc ? $1 : E("'$op' takes one digit or '-'", pos)] if $op =~ /&/;
  [$fd, $op, word('r')] }

sub simple {
  my $pl = shift; my (@env, @np, @av, @ap, @r, $kw); my $p0 = pos;   # @np: NAME, position, ... of the settings
  push @$pl, my $c = { argv => \@av }; local $OPEN[@OPEN] = \@av;
  while (/\G$B/gc, !/\G(?=[;&|()\n]|\z)/) {
    my $p = pos;
    if (my $r = redir()) { push @r, $r }
    elsif (!@av and /\G($NM)(\+?)=/gc) { E("'$1+='", $p) if $2; push @np, "$1", $p; push @env, "$1", word('e') }   # "$1", not $1: word() matches again
    else { push @av, word('a'); push @ap, $p; $kw //= substr $_, $p, pos() - $p } }
  if (!@av && @env && !@r && $O{assign}) {                              # only settings (C5)
    vname(splice @np, 0, 2) while @np;
    return %$c = (set => \@env) }
  name(@$_) for grep $$_[0] ne q{IFS}, pairs @np;                    # bash refuses its own names (UID=5 cmd)
  @av or E(@env || @r ? 'no command name' : 'missing command', $p0);
  E('command name not literal', $ap[0]) if ref $av[0];
  my $n = $av[0];
  if ($n eq 'exec') {
    shift @av; my $xp = shift @ap;
    @av or E("'exec' without a command", $p0);
    E("unsupported 'exec' form", $ap[0]) if ref($av[0]) || $av[0] =~ /^-|^(?:cd|:|exit)\z/;
    $c->{exec} = P($xp) }   # its position, until xc() has checked it and made it 1
  else {
    E("keyword '$n'", $ap[0]) if $KW{$n} && $kw eq $n;
    if ($n =~ /^(?:break|continue)\z/ && $LOOP) {                     # inside a loop (options while, for)
      E("unsupported '$n' form", $ap[0]) if @env || @r || @av > 2
        || @av == 2 && ($av[1] !~ /^[1-9][0-9]*\z/ || $av[1] > $LOOP) }
    elsif ($n eq 'read' && $O{read}) {                                  # read [-r] NAME... (option read)
      my $i = ($av[1] // '') eq '-r' ? 2 : 1;
      $i <= $#av or E("'read' without a variable name", $ap[0]);
      for my $j ($i .. $#av) { $av[$j] =~ /^$NM\z/ or E("unsupported 'read' argument", $ap[$j]); vname($av[$j], $ap[$j]) } }
    elsif ($BI{$n}) { E("builtin '$n'", $ap[0]) }
    if ($n eq 'cd') {
      @av <= 2 && !@env && !@r && !defined $ENV{CDPATH} && ($av[1] // '') !~ /^-/
        or E('unsupported cd form', $ap[0]);   # C8: the argument may have expansions; cd alone goes home
      E('cd to $HOME without HOME', $ap[0]) if !defined $ENV{HOME}
        && (@av == 1 || ref $av[1] && grep { ref && $$_[0] =~ /^\$/ } @{$av[1]});
      return %$c = (cd => $av[1]) }
    if ($n =~ /^(?::|exit)\z/) {
      E("settings before '$n'", $p0) if @env;
      E('unsupported exit status', $ap[0]) if $n eq 'exit' && (@av > 2 || @av == 2
        && ($av[1] !~ /^(?:0|[1-9][0-9]{0,2})\z/ || $av[1] > 255)) } }
  $c->{env} = \@env if @env; $c->{redir} = \@r if @r;
  $c }

sub word {   # $x: a(rgument), e(nv value), r(edirection target), b(race alternative)
  my $x = shift; my $p0 = pos; my @s; local $ATT = $ATT // $#OPEN;
  return '[' if $x eq 'a' and /\G\[$END/gc;                   # '[' alone: literal
  my $ta = $x eq 'e' || $x eq 'a' && $O{tilde_args} && /\G($NM=)/gc && push @s, [u => $1];   # ~ also after '=' and ':'
  my $te = $ta ? qr{(?=[/:])|$END} : qr{(?=/)|$END};
  my $p;
  my %do = (
    sq  => sub { push @s, [q => shift] },
    dq  => sub { push @s, [q => '']; dq(\@s, $p) },
    bs  => sub { $_[0] eq "\n" ? E('backslash-newline in a word', $p) : push @s, [q => shift] },
    ex  => sub { push @s, [x => $EX{$_[0]}->('', $p)] },   # also in redirection targets (Q1)
    gl  => sub { $x eq 'r' and return $RLIT ? push(@s, [q => shift]) : E('pattern in a redirection target', $p);
      push @s, [$x eq 'e' ? 'u' : 'g', shift] },
    br  => sub {
      $x eq 'r' and return $RLIT ? push(@s, [q => '[']) : E('pattern in a redirection target', $p);
      push @s, $x eq 'e' ? [u => '['] : /\G(!?\]?[^\] \t\n;&|()<>'"\\\$`{}^\/,]*\])/gc ? [g => "[$1"]
        : $RLIT && /\G\^(\]?[^\] \t\n;&|()<>'"\\\$`{}^\/,]*\])/gc ? [g => "[^$1"]   # Large: [^...] negates (rule E; the executor reads it)
        : $RLIT && bracket(\@s, $p) ? ()                     # Large: quotes, expansions, '/' inside (post4-0.04)
        : /\G(?:\\.|'[^']*'|"(?:[^"\\]|\\.)*"|[^ \t\n;&|()<>\\'"])*?\]/s   # a ] later in the word, past quotes
          ? E('bracket expression with a quote, expansion or slash', $p) : [g => '['] },
    cb  => sub {   # a '{' not followed by '}'
      $O{brace} && $x eq 'a' or E("unquoted '{'", $p);
      if (/\G(-?[0-9]+|[A-Za-z])\.\.(-?[0-9]+|[A-Za-z])\}/gc) {
        my ($f, $t) = ($1, $2);
        E('mixed brace sequence', $p) if $f =~ /[0-9]/ xor $t =~ /[0-9]/;
        return push @s, [x => ['{..', $f, $t]] }
      my @alt; do { push @alt, word('b') } while /\G,/gc;
      /\G\}/gc && @alt > 1 or E('unsupported brace form', $p);
      push @s, [x => ['{', @alt]] },
    ti  => sub {   # ~ at the start of the word, and with $ta after the NAME= of an argument or an unquoted ':'
      return push @s, [u => '~'] if @s && !($ta && $s[-1][0] eq 'u' && ($s[-1][1] =~ /:\z/ || @s == 1 && $x eq 'a'));
      E('~ in a brace alternative', $p) if $x eq 'b';
      /\G((?:[A-Za-z0-9._][A-Za-z0-9._-]*)?)$te/gc or E('unsupported ~ form', $p);
      E('~ without HOME', $p) if $1 eq '' && !defined $ENV{HOME} && !$Proc::ShellSubset::TILDEPW;
      push @s, [x => ['~', $1]] },
    ca  => sub { E("unquoted '^'", $p) if $O{nocaret}; push @s, [u => '^'] },   # ordinary unless nocaret (C3)
    lit => sub { push @s, [u => shift] },
    bad => sub { E({"'" => 'unterminated quote', '\\' => 'final backslash', '}' => "unquoted '}'"}->{$_[0]}
                   // sprintf('control character \\x%02x', ord shift), $p) });
  until (/$STOP{$x}/) { $p = pos; /$PIECE/gc; my ($k, $v) = %+; $do{$k}($v) }
  @s or $x =~ /[eb]/ or E('missing word', $p0);
  my $k = join '', map $$_[0], @s; my @v;    # kinds: u(nquoted) q(uoted) g(lob char) x(pansion)
  push @v, defined $1 ? ['*', join '', map $$_[1], splice @s, 0, length $1] : (shift @s)->[1]
    while $k =~ /([ug]*g[ug]*)|./g;           # unquoted text next to a pattern character joins it
  dots(@v) and E("pattern that may match '.' or '..'", $p0) unless $RLIT;   # dash: yes, bash 5.2: no (U2); Large: never (rule E)
  mkword(@v) }

sub bracket {   # Large, after '[' (post4-0.04): a bracket expression with quoted members, expansions or '/', as both
  my ($s, $p, $xq) = @_; my $p0 = pos; my @b = [g => '['];   # shells: quoted characters are members, not operators;
  push @b, [g => $1] if /\G([!^])/gc;                           # an unquoted expansion's characters are active.  Pushes its
  push @b, [g => ']'] if /\G\]/gc;                        # Parts on @$s and returns 1; or 0 with pos unchanged, if
  until (/\G\]/gc) {                                      # the word ends first (then the '[' is literal)
    my $q = pos;
    if    (/\G(\[:[a-z]+:\])/gc) { push @b, [g => $1] }
    elsif (/\G([^\] \t\n;&|()<>'"\\\$`{}^,\[\x00-\x1f\x7f]+|\[)/gc) { push @b, [g => $1] }
    elsif (/\G'([^']*)'/gc) { push @b, [q => $1] }
    elsif (/\G\\([^\n])/gc) { push @b, [q => $1] }
    elsif (/\G"/gc) { push @b, [q => '']; dq(\@b, $q) }
    elsif (/\G([\$`])/gc) { push @b, [x => $EX{$1}->($xq // '', $q)] }   # $xq: inside "${...}"
    elsif (/\G[{}^,]/) { E('bracket expression with a quote, expansion or slash', $p) }
    else { pos = $p0; return 0 } }
  push @$s, @b, [g => ']']; 1 }

sub dots {   # can a pattern in these Parts match a whole file name component '.' or '..'? (U2)
  my ($re, $g) = ('', 0);   # the component so far as a regex (only the character '.' matters); has it a pattern?
  for my $x (@_, '/') {      # literal text and patterns, split at '/'; an expansion is taken to match no '.'
    for (ref $x ? $$x[0] eq '*' ? map [g => $_], split m{(/)}, $$x[1] : [x => ''] : map [l => $_], split m{(/)}, $x) {
      my ($k, $v) = @$_;
      if ($v eq '/') { return 1 if $g && $re =~ /^\\\./ && grep /^$re\z/, '.', '..'; ($re, $g) = ('', 0) }   # only a written '.' matches a leading one
      elsif ($k eq 'l') { $re .= quotemeta $v }
      elsif ($k eq 'x') { $re .= '(?!)' }
      else { $g ||= $v =~ /[*?[]/; $re .= $v =~ s{\[(!?)(\]?[^\]]*)\]|([*?])|(.)}{   # a bracket expression: can it match '.'?
        defined $2 ? (($1 ? $2 !~ /\./ : $2 =~ /[.\-]|\[:/) ? q{[.]} : q{(?!)}) : defined $3 ? ($3 eq '*' ? '.*' : '.') : quotemeta $4}gesr } } }
  0 }

sub mkword {   # a Word from Parts: adjacent strings joined, a lone string bare, nothing ''
  my @w; !ref && @w && !ref $w[-1] ? $w[-1] .= $_ : push @w, $_ for @_;
  @w == 1 && !ref $w[0] ? $w[0] : @w ? \@w : '' }

sub dq {   # after '"', up to the closing '"'
  my ($s, $p) = @_;
  until (/\G"/gc) {
    next if /\G\\\n/gc;
    if    (/\G(?:([^"\\\$`]+)|\\([\$`"\\])|(\\))/gc) { push @$s, [q => $+] }
    elsif (/\G([\$`])/gc) { push @$s, [x => $EX{$1}->('"', pos() - 1)] }
    else  { E('unterminated double quote', $p) } } }

sub dollar {   # after '$'; $q is '"' inside double quotes
  my ($q, $p) = @_;
  return '$' unless /\G[A-Za-z_0-9{(@*#?\$!\[-]/ or !$q && /\G['"]/;   # starts nothing: literal (C1)
  return [$q . '$((', arith($p)] if /\G\(\(/gc;
  if (/\G\(/gc) { my $l = shell(')', []); /\G\)/gc; return [$q . '$(', $l] }
  return [$q . '$', name("$1", $p)] if /\G(?|\{($NM|[?!])\}|($NM|[?!]))/gc;   # $? and $! (corpus-round C6)
  if ($O{param_ops}) {                                                    # (C7)
    return [$q . '${#', name("$1", $p)] if /\G\{#($NM)\}/gc;
    if (/\G\{($NM)(:?[-+])/gc) {
      my ($n, $op, @w) = ($1, $2); name($n, $p);
      until (/\G\}/gc) {
        if    (/\G([^"'\\~*?\[{}\$`\n]+)/gc) { push @w, $1 }
        elsif (/\G([\$`])/gc) { my $x = $1;   # \" in `...` inside "${...}": " in bash, \" in dash (U3)
          E('\\" in backquotes inside "${...}"', pos() - 1) if $x eq '`' && $q && /\G((?:[^`\\]|\\.)*)/s && $1 =~ /\\"/;
          push @w, $EX{$x}->($q, pos() - 1) }
        else  { E(/\G\z/ ? "unterminated '\${'" : "unsupported character in '\${$n$op...}'", pos) } }
      return [$q . '${', $n, $op, mkword(@w)] } }
  E(/\G['"\[]/ ? 'bash-only $ form' : 'unsupported parameter form', $p) }

sub name {
  my ($n, $p) = @_;
  E("shell-set variable '$n'", $p) if $SH{$n} || $n eq 'PWD' && $O{nopwd} || $n =~ /^(?:BASH|COMP|READLINE)_/
    || $n =~ /^(?:PATH|SHELL|TERM|HOSTNAME)\z/ && !defined $ENV{$n};
  $n }

sub arith {   # after '$((': check the expression by its grammar, return its text
  my $p = shift;
  /\G((?&e))(?&w)\)\)$ARITH/gc && $1 !~ /\+\+|--/ or E('bad arithmetic expression', $p);
  my $t = $1; name("$1", $p) while $t =~ /\b($NM)/g;
  $t }

sub bq {   # after '`': find the closing '`', undo its escapes, parse the result as its own string
  my ($q, $p) = @_; my $s = pos;
  /\G((?:[^`\\]|\\.)*)`/sgc or E('unterminated backquote', $p);
  my ($raw, $in, @m) = ($1, '');
  while ($raw =~ /\\([\$`\\$q])|(\\\n)|(.)/sg) {   # a backslash escapes $ ` \ and, inside double quotes, "
    E('backslash-newline inside backquotes', $s + $-[0]) if defined $2;
    $in .= $+; push @m, P($s + $-[$#-]) }
  push @m, P(pos() - 1);
  [$q . '$(', do { local $_ = $in; local $M = \@m; shell('', []) }] }

sub xc {   # B3: 'exec' only where nothing can follow it in the shell (or subshell) it replaces
  my ($l, $ok) = @_;                         # $ok: nothing follows this list in its shell
  for my $ch (@$l) { my @p = grep ref, @$ch;
    for my $pl (@p) { my @c = grep ref, @$pl;
      my $last = @c > 1                      # each element of a longer pipeline is a subshell
        || $pl == $p[-1] && $pl->[0] ne '!' && ($ch->[-1] eq '&' || $ok && $ch == $l->[-1]);
      for my $x (@c) {   # a loop's condition and body, and an if's conditions, are followed by more of the loop or if
        xc($x->{group}, $last) if $x->{group};
        if (my $arms = $x->{if}) { xc($arms->[$_], $_ % 2 || @$arms % 2 && $_ == $#$arms ? $last : 0) for 0 .. $#$arms }
        xc($x->{$_}, 0) for grep $x->{$_}, qw(while until do);
        if (exists $x->{case}) { xc($_, $last) for pairvalues @{$x->{in}} }
        if (exists $x->{exec}) { my $xp = $x->{exec}; $x->{exec} = 1;
          $x->{ERROR} = 1, die ["'exec' with something after it", $xp] if !$last } } } } }

1;
__END__

=head1 NAME

Proc::ShellSubset - parse a Bourne-shell subset into a tree (EXPERIMENTAL)

=head1 SYNOPSIS

  use Proc::ShellSubset;
  my $t = Proc::ShellSubset::parse('ls -l | wc -l > out', if => 1, while => 1);
  if (ref $t eq 'ARRAY') { ... }                         # the tree
  else { warn "$t->{error} at $t->{pos}\n" }            # outside the subset

=head1 DESCRIPTION

C<parse($string, %options)> returns the parse tree of a shell one-liner (an array reference), or, when the
string is outside the subset, a hash C<{ error, pos, last, tree }>: the reason, the position where parsing
failed, the position after the last top-level C<;>, C<&> or newline, and the part parsed so far.
L<Proc::ShellSpawn> runs the trees.

Options, each off by default: C<if>, C<while> (also C<until>, C<break>, C<continue>), C<for>, C<case>,
C<read>, C<assign> (commands with settings only), C<param_ops> (C<${x:-w}> and the like), C<brace> (brace
expansion), C<tilde_args> (C<~> after C<NAME=> in arguments), C<fdmulti> (descriptor numbers of two or more
digits), C<empty> (accept an empty string), C<nocaret> (reject C<^>), C<nopwd> (reject C<$PWD>), and C<check>
(a code reference returning a reason to reject).

The tree format and the grammar are described in the comments at the top of the module and in
F<doc/parsers/shell-subset-spec.md>. L<Proc::ShellSubset::Small> is the same grammar with the options frozen;
L<Proc::ShellSubset::Large> accepts much more.

=head1 SEE ALSO

L<Proc::ShellSubset::Small>, L<Proc::ShellSubset::Large>, L<Proc::ShellSpawn>, F<doc/README.md>.

=cut
