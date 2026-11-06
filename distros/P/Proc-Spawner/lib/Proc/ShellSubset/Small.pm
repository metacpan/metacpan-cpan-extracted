package Proc::ShellSubset::Small;  # Proc::ShellSubset with its options frozen (see doc/parsers/shell-subset-spec.md, section 9)
our $VERSION = '0.06';
use strict; use warnings;

# Proc::ShellSubset::Small::parse($string) returns a List, or { error => '...', pos => N, last => N, tree => List }:
# 'last' is the position after the last top-level ';', '&' or newline, 'tree' the part parsed so far, with
# { ERROR => 1 } where parsing failed (an 'exec' in the wrong place gets ERROR => 1 in its own hash; an 'exec'
# not checked yet when parsing failed has exec => its position, which may be 0: test the key with exists).
# Frozen options, each at the value that leaves the least code: no if, while, until, for, case, read (so no
# break, continue), no brace expansion, no ${x:-w} forms, no commands with only settings, no ~ after NAME=
# in arguments; ^ and $PWD accepted, no checker, an empty string accepted (an empty List), multi-digit fds
# accepted (as bash reads them; dash reads '10>f' as the argument 10 and a redirection).
#
# List     = [ AndOr, ... ]
# AndOr    = [ Pipeline, '&&' | '||', Pipeline, ..., '&' (only if in background) ]
# Pipeline = [ '!' (only if negated), Command, ... ]
# Command  = { argv => [Word, ...], env => [NAME, Word, ...], redir => [Redir, ...], exec => 1 }
#          | { sub => List, redir => [...] } | { group => List, redir => [...] } | { cd => Word | undef }
#            (keys only when non-empty; argv->[0] is a plain string; cd alone has cd => undef)
# Redir    = [ fd, op, Word ]   (for <& and >&: [ fd, op, 'digit or -' ])
# Word     = 'literal text' | [ Part, ... ]
# Part     = 'literal text' | [ '$', NAME or '?' or '!' ] | [ '$((', 'expr' ] | [ '$(', List ]
#          | the same three with '"' in front ('"$' ...) when inside double quotes
#          | [ '~', 'user' or '' ] | [ '*', 'pattern text' ]

our ($M, @OPEN, $ATT, $LAST);   # position map of a backquote's inside; arrays being filled (for the
    # partial tree); how many of them are in the tree; end of the last top-level chain
my %KW = map +($_ => 1), qw(if then else elif fi case esac for while until do done in [[ ]] function select coproc !);
my %BI = map +($_ => 1), qw(. break continue eval export readonly return set shift times trap unset alias
  unalias read wait umask ulimit jobs fg bg command getopts hash type fc chdir local source let declare
  typeset shopt enable builtin caller dirs pushd popd disown mapfile readarray suspend logout help
  history bind compgen complete compopt);
my %SH = map +($_ => 1), qw(IFS PS1 PS2 PS4 OPTIND PPID OLDPWD LINENO _ BASH BASHOPTS BASHPID DIRSTACK
  EPOCHREALTIME EPOCHSECONDS EUID FUNCNAME GROUPS HISTCMD HOSTTYPE MACHTYPE OPTERR OSTYPE PIPESTATUS
  POSIXLY_CORRECT RANDOM SECONDS SHELLOPTS SHLVL SRANDOM UID);
my $NM  = qr/[A-Za-z_][A-Za-z0-9_]*/;
my $END = qr/(?=[ \t\n;&|()<>]|\z)/;
my $B   = qr/(?:[ \t]|\\\n|#.*)*+/;           # blanks, line continuations, a comment
my $BN  = qr/(?:[ \t\n]|\\\n|#.*)*+/;        # the same, and newlines
my $PIECE = qr/\G(?: '(?<sq>[^']*)' | (?<dq>") | \\(?<bs>.) | (?<ex>[\$`]) | (?<gl>[*?]) | (?<br>\[)
  | (?<ti>~) | (?<lit>(?:\{\}|[^ \t\n;&|()<>'"\\\$`*?\[{}~\x00-\x1f\x7f])+) | (?<bad>.) )/sx;   # {} is literal (C2)
my $ARITH = qr{(?(DEFINE)                    # the expression grammar of $((...))
  (?<w>   [ \t\n]* )
  (?<num> (?: 0[xX][0-9a-fA-F]+ | 0[0-7]* | [1-9][0-9]* ) (?![0-9A-Za-z_]) )
  (?<atom> (?&w) (?: [-+!~] (?&w) )* (?: (?&num) | \$? [A-Za-z_][A-Za-z0-9_]* | \$\{[A-Za-z_][A-Za-z0-9_]*\} | \$[?!] | \$\{[?!]\}
            | \( (?&e) (?&w) \) ) )                     # $NAME, ${NAME}: substituted as text first (C9)
  (?<op>  (?&w) (?: << | >> | <= | >= | == | != | && | \|\| | [-+*/%<>&^|] ) )
  (?<e>   (?&atom) (?: (?&op) (?&atom) )* (?: (?&w) \? (?&e) (?&w) : (?&e) )? ) )}x;

my %EX = ('$' => \&dollar, '`' => \&bq);   # the expansion a $ or ` starts: ($q, $p) -> Part

sub P  { my $p = shift; $M ? $$M[$p] // $$M[-1] : $p }   # position in the original
sub E  { push @{$OPEN[$ATT // -1]}, { ERROR => 1 } if @OPEN; die [shift, P(shift)] }
sub U  { /\G$B/gc; E(/\G(.)/s ? 'unexpected ' . ($1 eq "\n" ? 'newline' : "'$1'") : 'unexpected end', pos) }
sub parse {
  my $s = shift; local ($M, @OPEN, $ATT); local $LAST = 0; my @l;
  my $t = eval {
    local $_ = $s;
    E('NUL character', $-[0]) if /\0/;
    E(q{starts with - or +: sh would read it as options}, $-[1]) if /\A[ \t\n\r\f\cK]*([-+])/;   # Perl skips leading white space, then runs sh -c STRING (U1)
    shell('', \@l) };
  $t // (ref $@ eq 'ARRAY' ? { error => $@->[0], pos => $@->[1], last => $LAST, tree => \@l } : die $@) }

sub list {   # up to ')' (subshell, $()), '}' (group) or the end ('')
  my ($t, $l) = @_; local $OPEN[@OPEN] = $l; my $top = !$t && !$M;   # fills @$l in place
  my $e = $t eq ')' ? qr/\G(?=\))/ : $t ? qr/\G(?=\}$END)/ : qr/\G\z/;
  while (/\G$BN/gc, !/$e/) {        # (zero-length /gc matches can't repeat at one place: test with plain //)
    push @$l, my $c = []; andor($c);
    if    (/\G$B&(?!&)/gc)          { push @$c, '&' }
    elsif (!/\G$B(?:;(?!;)|\n)/gc) { /\G$B/gc, /$e/ ? last : U() }
    $LAST = pos if $top }
  $l }

sub shell {   # a list that runs in a shell of its own: exec is checked at its end
  my $l = list(@_); xc($l, 1); $l }

sub andor {
  my $ao = shift; local $OPEN[@OPEN] = $ao;
  do { push @$ao, my $p = []; pipeline($p) } while /\G$B(&&|\|\|)$BN/gc && push @$ao, $1 }

sub pipeline {
  my $p = shift; local $OPEN[@OPEN] = $p;
  push @$p, '!' if /\G!(?=[ \t])$B/gc;
  E("'! !'", pos) if @$p && /\G!$END/;
  do { command($p) } while /\G$B\|(?![|&])$BN/gc }

sub command {   # pushes the command onto the pipeline @{$_[0]}
  my $pl = shift; my $p = pos; my $c;
  E("'((' at the start of a command", $p) if /\G\(\(/;
  if (/\G\(/gc) {
    push @$pl, $c = { sub => my $l = [] };
    shell(')', $l); /\G\)/gc; @$l or E('empty subshell', $p) }
  elsif (/\G\{(?=[ \t\n])/gc) {
    push @$pl, $c = { group => my $l = [] };
    list('}', $l); /\G\}/gc; @$l or E('empty group', $p) }   # xc: by the parent
  else { return simple($pl) }
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
  my $fd = length $n ? 0 + $n : $op =~ /^</ ? 0 : 1;
  return [$fd, $op, /\G([0-9-])$END/gc ? $1 : E("'$op' takes one digit or '-'", pos)] if $op =~ /&/;
  [$fd, $op, word('r')] }

sub simple {
  my $pl = shift; my (@env, @av, @ap, @r, @np, $kw); my $p0 = pos;   # @ap: the position of each word of @av
  push @$pl, my $c = { argv => \@av }; local $OPEN[@OPEN] = \@av;
  while (/\G$B/gc, !/\G(?=[;&|()\n]|\z)/) {
    my $p = pos;
    if (my $r = redir()) { push @r, $r }
    elsif (!@av and /\G($NM)(\+?)=/gc) { E("'$1+='", $p) if $2; push @np, ["$1", $p]; push @env, "$1", word('e') }   # "$1", not $1: word() matches again
    else { push @av, word('a'); push @ap, $p; $kw //= substr $_, $p, pos() - $p } }
  name(@$_) for grep $$_[0] ne 'IFS', @np;                         # bash refuses its own names (UID=5 cmd) (U5)
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
    E("builtin '$n'", $ap[0]) if $BI{$n};
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

sub word {   # $x: a(rgument), e(nv value), r(edirection target)
  my $x = shift; my $p0 = pos; my @s; local $ATT = $ATT // $#OPEN;
  return '[' if $x eq 'a' and /\G\[$END/gc;                   # '[' alone: literal
  my $te = $x eq 'e' ? qr{(?=[/:])|$END} : qr{(?=/)|$END};    # ~ also before ':' in a setting
  my $p;
  my %do = (
    sq  => sub { push @s, [q => shift] },
    dq  => sub { push @s, [q => '']; dq(\@s, $p) },
    bs  => sub { $_[0] eq "\n" ? E('backslash-newline in a word', $p) : push @s, [q => shift] },
    ex  => sub { push @s, [x => $EX{$_[0]}->('', $p)] },   # also in redirection targets (Q1)
    gl  => sub { E('pattern in a redirection target', $p) if $x eq 'r'; push @s, [$x eq 'e' ? 'u' : 'g', shift] },
    br  => sub {
      E('pattern in a redirection target', $p) if $x eq 'r';
      push @s, $x eq 'e' ? [u => '['] : /\G(!?\]?[^\] \t\n;&|()<>'"\\\$`{}^\/,]*\])/gc ? [g => "[$1"]
        : /\G(?:\\.|'[^']*'|"(?:[^"\\]|\\.)*"|[^ \t\n;&|()<>\\'"])*?\]/s   # a ] later in the word, past quotes
          ? E('bracket expression with a quote, expansion or slash', $p) : [g => '['] },
    ti  => sub {   # ~ at the start of the word, or after an unquoted ':' in a setting, is an expansion
      return push @s, [u => '~'] if @s && !($x eq 'e' && $s[-1][0] eq 'u' && $s[-1][1] =~ /:\z/);
      /\G((?:[A-Za-z0-9._][A-Za-z0-9._-]*)?)$te/gc or E('unsupported ~ form', $p);
      E('~ without HOME', $p) if $1 eq '' && !defined $ENV{HOME};
      push @s, [x => ['~', $1]] },
    lit => sub { push @s, [u => shift] },
    bad => sub { E({"'" => 'unterminated quote', '\\' => 'final backslash', '{' => "unquoted '{'", '}' => "unquoted '}'"}->{$_[0]}
                   // sprintf('control character \\x%02x', ord shift), $p) });
  until (/\G$END/) { $p = pos; /$PIECE/gc; my ($k, $v) = %+; $do{$k}($v) }
  @s or $x eq 'e' or E('missing word', $p0);
  my $k = join '', map $$_[0], @s; my @v;    # kinds: u(nquoted) q(uoted) g(lob char) x(pansion)
  push @v, defined $1 ? ['*', join '', map $$_[1], splice @s, 0, length $1] : (shift @s)->[1]
    while $k =~ /([ug]*g[ug]*)|./g;           # unquoted text next to a pattern character joins it
  dots(@v) and E("pattern that may match '.' or '..'", $p0);   # dash: yes, bash 5.2: no (U2)
  mkword(@v) }

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
  E(/\G['"\[]/ ? 'bash-only $ form' : 'unsupported parameter form', $p) }

sub name {
  my ($n, $p) = @_;
  E("shell-set variable '$n'", $p) if $SH{$n} || $n =~ /^(?:BASH|COMP|READLINE)_/
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
      for my $x (@c) {
        xc($x->{group}, $last) if $x->{group};
        if (exists $x->{exec}) { my $xp = $x->{exec}; $x->{exec} = 1;
          $x->{ERROR} = 1, die ["'exec' with something after it", $xp] if !$last } } } } }

1;
__END__

=head1 NAME

Proc::ShellSubset::Small - the Proc::ShellSubset grammar with its options frozen (EXPERIMENTAL)

=head1 SYNOPSIS

  use Proc::ShellSubset::Small;
  my $t = Proc::ShellSubset::Small::parse('grep -c x file >count');

=head1 DESCRIPTION

C<parse($string)> takes no options. It returns the same values as L<Proc::ShellSubset/parse> called with
C<empty> and C<fdmulti> on and every other option off: simple commands, pipelines, C<&&> and C<||>, C<( )>,
C<{ }>, C<$( )>, quoting, redirections. Nothing else. The test C<t/parsers.t> checks that the two agree on every
test string. See F<doc/parsers/shell-subset-spec.md>, section 9.

=head1 SEE ALSO

L<Proc::ShellSubset>, L<Proc::ShellSubset::Large>, L<Proc::ShellSpawn>.

=cut
