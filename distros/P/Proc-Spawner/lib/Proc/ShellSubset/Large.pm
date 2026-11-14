package Proc::ShellSubset::Large;  # The large subset (doc/large-subset/large-subset-spec.md): Proc::ShellSubset, and where it rejects, a wider grammar
our $VERSION = '0.12';
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
  my $al = $s =~ /(?:^|[\s;&|(])alias\s/ || %{$o{aliases} // {}};   # B1: aliases are expanded by the large grammar only
  my $t = $al ? { error => '' } : Proc::ShellSubset::parse($s, %o, map +($_ => 1), @OPTS);
  $t = Proc::ShellSubset::large($s, %o, map +($_ => 1), @OPTS) if ref $t eq 'HASH' && $t->{error} !~ /^starts with - or \+/;
  my $why = ref $t eq 'ARRAY' && treecheck($t, \%o);
  $why ? { error => $why, pos => 0, last => 0, tree => [] } : $t }
sub treecheck {   # rules for commands the base grammar accepts too: each argv with a literal name and a check (Q1: kill)
  my @todo = (shift); local %Proc::ShellSubset::O = %{shift // {}};
  while (@todo) { my $x = shift @todo;
    if (ref $x eq 'ARRAY') { push @todo, @$x }
    elsif (ref $x eq 'HASH') {
      if (ref $x->{argv} eq 'ARRAY' && @{$x->{argv}} && !ref $x->{argv}[0] && !$x->{fn} and my $c = $Proc::ShellSubset::TREECHK{$x->{argv}[0]}) {
        my $why = $c->(@{$x->{argv}}[1 .. $#{$x->{argv}}]); return $why if $why }
      push @todo, values %$x } }
  '' }

package    # hidden from the PAUSE indexer: the module Proc::ShellSubset lives in lib/Proc/ShellSubset.pm
  Proc::ShellSubset;   # the replacements run inside Proc::ShellSubset, with its variables
our (%O, $M, @OPEN, $ATT, $LAST, $LOOP, $FORALL, $RLIT, %KW, %BI, %SH, $NM, $END, $B, $BN, %EX, $PIECE);
our ($FUNC, @HD, $AP, $NOAT, %LOC, %UNSET) = 0;
our ($SUBLOOP, $LN, $SRC, $LOFF, $CUT, @ASH) = (0, 0, '', 0, 0);   # loops around the subshell we are in (they end it: break, continue as dash, rule E);
             #   whether $LINENO is used here, and the text, for line numbers (G8, rule E)
sub lineof { $LOFF + 1 + (substr($SRC, 0, opos(shift)) =~ tr/\n//) }   # LOFF: lines before this text (the rest of a text, P1)
our %FDEF;   # 3A (post-0.04): names this text defines as functions somewhere; commands by these names are left
             #   to run time, where a function defined by then comes before the builtin (POSIX order)
our (%ALIAS, @AEXP, $ANEXT);   # B1: alias name -> [[position from which it holds, value or undef], ...] in this text;
    # aliases being expanded [name, end position]; where the word after an alias whose value ends in a blank starts   # depth of function bodies; here-document bodies not yet used;
    # position of the command; true where "$@" would join with IFS (dash) or blanks (bash); names made local; unset
my ($o_command, $o_word, $o_bq, $o_shell) = (\&command, \&word, \&bq, \&shell);   # the originals, called by the replacements
our $TILDEPW;   # G16: true while the large grammar parses
my @INTER = qw(history fc bind help compopt logout);   # B2: interactive only; caller's option interactive => reject|nop|dash
my %LBI = map +($_ => 1), qw(chdir source let declare typeset shopt enable builtin caller dirs pushd popd disown
  mapfile readarray suspend compgen complete), @INTER;                 # builtins the large subset still leaves to sh
my %OWN = map +($_ => 1), qw(: . break cd command continue eval exec exit export getopts local read readonly
  return set shift trap umask unset wait alias unalias jobs fg bg hash type times ulimit), @INTER;   # builtins it runs itself
my %NOFN = map +($_ => 1), qw(break continue eval exec exit export readonly return set shift times trap unset
  local source alias unalias);   # no function by these names: special builtins (dash: also local, bash: source);
             #   alias, unalias: aliases are a parse-time matter here (B1), so a call must be known to be the builtin
our %REGBI = map +($_ => 1), qw(cd getopts read umask wait jobs fg bg hash type ulimit);   # regular builtins we run, which
             #   'command NAME' and a not-yet-defined function by that name reach at run time (3A, post-0.04)
my %TS = map +($_ => 1), qw(0 EXIT HUP INT QUIT ABRT FPE KILL PIPE ALRM TERM USR1 USR2 STOP);   # trap signals: names in
my %SIGN; { require Config; my @n = split ' ', $Config::Config{sig_name}; my @v = split ' ', $Config::Config{sig_num};
  @SIGN{@v} = @n; $SIGN{0} = 'EXIT' }   # any case, or their numbers here (P6); KILL and STOP: nothing to do
sub trapsig { my $s = shift; $TS{$s =~ /^[0-9]+\z/ ? $SIGN{$s} // '' : uc $s} }
my %SETO = map +($_ => 1), qw(errexit nounset noglob noclobber allexport ignoreeof notify nolog);   # the last three do nothing (P6)
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

my $LPIECE = do {   # Proc::ShellSubset's $PIECE, with '{' and '}' literal where no brace expansion can start (P1):
  my $x = "$PIECE";   #   '}' always; '{' when its '}' has no ',' and no '..' inside, or when no '}' follows in the word
  my ($lb, $def) = split /^----\n/m, <<'RE';
(?<lit> \\ \z | \x7b (?= (?&bal) \x7d ) | \x7b (?! [^ \t\n;&|()<>]* \x7d ) | \x7d ) |
----
 (?(DEFINE) (?<bal> (?: [^\x7b\x7d,. \t\n;&|()<>'"\\`\$] | \.(?!\.) | \\. | '[^']*' | "(?:[^"\\]|\\.)*"
    | \$(?![\x7b(]) | \x7b (?&bal) \x7d )* ) )
RE
  my $i = index $x, '(?<cb>'; $i > 0 && $x =~ /\)\z/ or die 'P1: $PIECE changed';
  substr($x, -1, 0) = $def; substr($x, $i, 0) = $lb;
  qr/$x/ };
my %SETOK = map +($_ => 1), qw(PS1 PS4 HOSTNAME PIPESTATUS BASH);   # shell-set names both shells let a string set (P3)

our %TREECHK;   # checks applied to the whole tree, also where the base grammar accepted the string (see Large::treecheck)
# P5: [ and test are the program (coreutils), which decides every form; R1: except a literal < or > argument, which both
# shells take as a string comparison and the program refuses.  Rule F (the user, 2026-11-03; post2-0.04): where the program
# is wrong, we may do better: 's1 < s2' and 's1 > s2' alone (also after '!') are compared by the executor itself, by bytes as
# both shells (POSIX 2024 adds them); other forms with < or > stay rejected unless the caller sets the option test_lt_gt.
my $TOP = qr/^(?:!?=|==|<|>|-(?:eq|ne|lt|le|gt|ge|nt|ot|ef|a|o)|!|\()\z/;   # what may stand before an operand
$TREECHK{$_} = sub { my @a = @_; pop @a if @a && !ref $a[-1] && $a[-1] eq ']';
  return '' if $O{test_lt_gt};
  my @o = $a[0] && !ref $a[0] && $a[0] eq '!' ? @a[1 .. $#a] : @a;
  return '' if @o == 3 && !ref $o[1] && $o[1] =~ /^[<>]\z/;   # rule F: the executor compares (Proc::ShellSpawn::Large::b_test)
  for my $i (1 .. $#a - 1) { next if ref $a[$i] || $a[$i] !~ /^[<>]\z/ || !ref $a[$i - 1] && $a[$i - 1] =~ $TOP;
    return "'$a[$i]' between two operands in '[' or 'test' (both shells compare strings, the program [ refuses; option test_lt_gt)" }
  '' } for '[', 'test';
sub status { @_ > 1 || @_ && !ref $_[0] && ($_[0] !~ /^(?:0|[1-9][0-9]{0,2})\z/ || $_[0] > 255) ? 'unsupported exit status' : '' }
sub xstatus { @_ > 1 || @_ && !ref $_[0] && $_[0] !~ /^(?:0|[1-9][0-9]{0,8})\z/ ? 'unsupported exit status' : '' }   # exit: modulo 256 (P4)
my %CHK = (   # literal arguments of the builtins run by the large subset: (arguments) -> reason to reject, or ''
  '.'     => sub { @_ == 1 ? '' : "'.' with other than one argument" },
  exit    => \&xstatus,
  alias   => sub { (grep !ref && /=/ && !/^[A-Za-z0-9_.\-]+=/, @_) ? "unsupported 'alias' argument" : '' },   # B1; a word with an
                                                                                                             #   expansion: P1
  unalias => sub { @_ == 1 && !ref $_[0] && $_[0] eq '-a' || @_ && !grep(ref || /^-|=/, @_) ? '' : "unsupported 'unalias' form" },
  jobs    => sub { my @a = @_; shift @a while @a && !ref $a[0] && $a[0] =~ /^-[lp]+\z/;   # B3: as dash; -p, -l (rule E);
    (grep ref || !/^%(?:[1-9][0-9]*|[%+-])\z/, @a) ? "unsupported 'jobs' form" : '' },  #   then %N, %%, %+, %- (post-0.04)
  times   => sub { @_ ? "unsupported 'times' form" : '' },
  hash    => sub { (grep ref || /^-/ && $_ ne '-r', @_) ? "unsupported 'hash' form" : '' },
  type    => sub { @_ && !grep(ref || /^-/, @_) ? '' : "unsupported 'type' form" },
  ulimit  => sub { my $r = 0;                                           # reading one limit only: [-H|-S] [-nsctvlmdf]
    for (@_) { return "unsupported 'ulimit' form (only reading a limit)" if ref || !/^-[HS]*[nsctvlmdf]?[HS]*\z/ || /^-\z/; $r += () = /[nsctvlmdf]/g }
    $r > 1 ? "unsupported 'ulimit' form (only reading a limit)" : '' },
  kill    => ($TREECHK{kill} = sub { my $p = '';   # a signal name with SIG, also -sig...: both shells refuse it, so we do too (Q1)
    for (@_) { next if ref; return "a 'SIG' signal name for 'kill' (both shells refuse it)" if /^-[Ss][Ii][Gg]/ || $p =~ /^-[sl]\z/ && /^SIG/i; $p = $_ } '' }),
  pwd     => ($TREECHK{pwd} = sub {   # options both shells refuse: we refuse them too (Q1); also where the base grammar accepts it
    for (@_) { last if ref($_) || !/^-/ || $_ eq '--'; /^-[LP]+\z/ or return "unsupported 'pwd' option (both shells refuse it)" } '' }),
  return  => sub { &status },   # outside a function: an error, as bash (rule E)
  shift   => sub { @_ > 1 || @_ && !ref $_[0] && $_[0] !~ /^[0-9]+\z/ ? "unsupported 'shift' form" : '' },
  wait    => sub { (grep !ref && !/^[0-9]+\z/, @_) ? "unsupported 'wait' argument" : '' },
  umask   => sub { @_ > 1 || @_ && !ref $_[0] && $_[0] !~ /^(?:[0-7]{1,4}|-S|[ugoa]*[-+=][rwx]*(?:,[ugoa]*[-+=][rwx]*)*)\z/ ? "unsupported 'umask' form" : '' },   # -S alone (P4); symbolic (post4-0.03)
  command => sub { my $f = $_[0] // return q{};   # command alone; command -v NAME; command [-p] PROGRAM ...: no builtin
    my $dp = $f eq '-p' and shift, $f = $_[0] // return "unsupported 'command' form";            # -p (P4)
    ref $f || $f eq '-v' && @_ == 2 || $f !~ /^-/ && (!$OWN{$f} || $REGBI{$f} && !$dp) && !$LBI{$f} ? '' : "unsupported 'command' form" },
  getopts => sub { @_ < 2 ? "'getopts' without a variable name" : ref $_[1] ? ''
    : $_[1] =~ /^$NM\z/ ? vname($_[1], $AP) && '' : "unsupported 'getopts' name" },
  unset   => sub { my $f = ($_[0] // '') =~ /^-[vf]\z/ && shift;
    @_ or return "'unset' without a name";
    for (@_) { if (ref) { return "unsupported 'unset' argument" if grep +(ref ? $$_[0] eq '*' && $$_[1] : $_) =~ /[\[\]]/, @$_; next }   # foo[$i]: bash's array
               /^$NM\z/ or return "unsupported 'unset' argument"; $f eq '-f' or $UNSET{vname($_, $AP)} //= $AP } '' },
  set     => sub { @_ or return "'set' without arguments (it lists)";
    while (defined(my $o = shift)) { return '' if ref $o || $o eq '--' || $o !~ /^[-+]/;   # operands follow
      if ($o =~ /^[-+]o\z/) { my $n = shift; return '' if ref $n;
        $SETO{$n // ''} || ($n // '') =~ /^(?:vi|emacs)\z/ || ($n // '') eq 'history' && ($O{interactive} // 'nop') ne 'reject'
          or return "unsupported 'set -o' form" }                            # B2: vi, emacs, history do nothing here
      elsif ($o !~ /^[-+][eufCab]+\z/ && $o ne '+m') { return "unsupported 'set' option '$o'" } } '' },   # -b, +m: nothing (P6)
  trap    => sub { @_ >= 2 or return "'trap' with fewer than two arguments (it lists)";
    my $x = shift; return "unsupported 'trap' form" if !ref $x && $x =~ /^-.|^[0-9]+\z/;   # trap 1 2: a signal
    return 'trap action outside the subset' if !ref $x && $x =~ /\S/ && $x ne '-' && ref large($x, %O, nolineno => 1) ne 'ARRAY';
    (grep !ref && !trapsig($_), @_) ? "unsupported signal for 'trap'" : '' });

sub large {   # the large grammar: Proc::ShellSubset::parse with replacements
  my ($s, %o) = @_; no warnings 'redefine'; my $chk = delete $o{check}; $o{fdmulti} //= 1;   # rule E: as bash
  my $why = $s =~ /\0/ ? ['NUL character', $-[0]] : $chk && $chk->($s) ? [$chk->($s), 0] : undef;
  my ($t, $map, @hd) = $why ? () : eval { hdcut($s) }; $why //= $@ if ref $@;
  return { error => $$why[0], pos => $$why[1], last => 0, tree => [] } if $why;
  local (@HD, $FUNC, $NOAT, %LOC, %UNSET, $FORALL, $RLIT) = (@hd); ($FUNC, $FORALL, $RLIT) = (0, 1, 1);
  local %FDEF = map +($_ => 1), grep $OWN{$_} || $LBI{$_} || $CHK{$_} || $TREECHK{$_},   # 3A: names with checks of their own;
    $s =~ /(?:^|[\s;&|(){}])($NM)[ \t]*\([ \t]*\)/g;                       #   a loose scan: a false hit only defers checks
  local %BI = %LBI; local %SH = %SH; delete @SH{qw(IFS OPTIND OLDPWD PPID)};   # PPID: both shells set it (post4-0.03)
  local ($SUBLOOP, $LN, $SRC, $LOFF, $CUT, @ASH) = (0, $s =~ /LINENO/ && !$o{nolineno}, $s, $o{lineoff} // 0, 0); $LN ? delete $SH{LINENO} : ($SH{LINENO} = 1);   # G8: not in eval or trap text
  delete $SH{UID} if $s =~ /(?:^|[\s;&|(){}])UID=/;   # G15 (rule E, as dash): an ordinary variable where the text sets it
  local $TILDEPW = 1;   # G16 (rule E, as bash): ~ without HOME is the home in the password file
  local *shell = sub { local $SUBLOOP = $SUBLOOP + ($LOOP // 0); $o_shell->(@_) };
  delete @BI{@INTER} unless ($o{interactive} // 'nop') eq 'reject';
  local %ALIAS = map +($_ => [[0, $o{aliases}{$_}]]), keys %{$o{aliases} // {}}; local (@AEXP, $ANEXT);
  local *P = sub { my $p = shift; $M ? $$M[$p] // $$M[-1] : $map ? $$map[$p] // $$map[-1] : $p };
  local *simple = \&l_simple; local *command = \&l_command; local *dollar = \&l_dollar; local *redir = \&l_redir;
  local *arith = \&l_arith; local *vname = \&l_vname; local *word = \&l_word; local *xc = sub {};
  local *bq = sub { local $NOAT; &$o_bq };   # a $( ) or `...` starts afresh
  local $PIECE = $LPIECE;
  my $r = parse($t, %o);
  if (ref $r eq 'ARRAY') {   # bodies read for a << that turned out to be text; unset of a name some function made local
    @HD && !$CUT and return { error => 'here-document body not used', pos => $HD[0][2], last => 0, tree => $r };
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

sub settable {   # post-0.04: a name known only at run time (read $v, export "$v"): may the large subset set it?
  my $n = shift; return 0 unless $n =~ /^$NM\z/ && $n !~ /^(?:CDPATH|PPID|LINENO)\z/;
  return 1 if $SETOK{$n};
  local %SH = %SH; delete @SH{qw(IFS OPTIND OLDPWD PPID UID)};   # as large() does (UID: G15, where a string sets it)
  local %O; eval { name($n, 0); 1 } }
sub l_vname { my ($n, $p) = @_; E("assignment to '$n'", $p) if $n =~ /^(?:CDPATH|PPID|LINENO)\z/; $SETOK{$n} ? $n : name($n, $p) }   # HOME: post-0.04

sub l_word { local $NOAT = $NOAT || $_[0] =~ /[er]/; &$o_word }   # a setting's value, a redirection target

sub at_in { my $w = shift; ref $w and grep ref && $$_[0] =~ /^"?\$\{?\z/ && $$_[1] eq '@', @$w }

sub bqdq {   # after '`' inside "${...}" or a here-document: \" there is " in bash, \" in dash
  my $p = shift; /\G((?:[^`\\]|\\.)*)/s and $1 =~ /\\"/ and E('\\" in backquotes here (dash and bash differ)', $p) }

sub l_command {   # NAME() COMPOUND-COMMAND is a function definition (F1); anything else as in Proc::ShellSubset
  my $pl = shift; my $p = pos;
  unless (/\G($NM)$B\($B\)$BN/gc) {
    my $i = @$pl; my $c = $o_command->($pl);
    $pl->[$i]{line} = lineof($p) if $LN && ref $pl->[$i] eq 'HASH';   # G8: the line where the command starts
    E("'\$\@' as the word of 'case'", $p) if ref $c && exists $c->{case} && at_in($c->{case});   # joined: IFS or blank
    return $c }
  my $n = $1; E("function named '$n'", $p) if $KW{$n} || $NOFN{$n};
  /\G(?=[{(]|(?:if|while|until|for|case)$END)/ or E('function body not a compound command', pos);
  my @b; push @$pl, my $c = { func => $n, body => \@b }; local $FUNC = $FUNC + 1; local ($LOOP, $SUBLOOP) = (0, 0);
  { local $OPEN[@OPEN] = \@b; $o_command->(\@b) } $c->{body} = $b[0];
  $c }

sub l_simple {
  my $pl = shift; my (@env, @np, @av, @ap, @r, $kw, @dv); my $p0 = pos;   # @dv: NAME, Word or undef (declarations)
  if (%ALIAS) { /\G[ \t]*/gc; alias_expand(); $p0 = pos }                 # B1: an alias as the command name
  push @$pl, my $c = { argv => \@av }; local $OPEN[@OPEN] = \@av;
  while (/\G$B/gc, !/\G(?=[;&|()\n]|\z)/) {
    my $p = pos;
    if (defined $ANEXT && $p >= $ANEXT) { undef $ANEXT; next if alias_expand() }   # the word after an alias ending in a blank
    E("unexpected '$1'", $p) if !@av && /\G([{}])$END/;   # '{' or '}' as a command name: a reserved word, not text (P1)
    E("'{NAME}' before a redirection (bash: a named descriptor)", $p) if /\G\{$NM\}[<>]/;   # exec {fd}>f (P1)
    if (my $r = redir()) { push @r, $r }
    elsif (!@av and /\G($NM)(\+?)=/gc) { E("'$1+='", $p) if $2; my $n = $1; push @np, $n, $p; push @env, $n, word(q{e}) }
    elsif (@av && $kw =~ /^(?:export|readonly|local)\z/) {                 # NAME[=value]: no splitting (F5)
      if ($kw eq 'export' && /\G(?|"\$(?|\{($NM)\}|($NM))"()$END|\$(?|\{($NM)\}|($NM))(?:(=)|$END))/gc) {   # export $v[=value], "$v": the name at run time (P4)
        my ($v, $eq) = ($1, $2); my $w = $eq ? word(q{a}) : undef;      #   the shells split an unquoted value, and
        E("unsupported 'export' value (not an assignment: split, no ~)", $p)   #   do not expand ~ in it
          if ref $w && grep ref && ($$_[0] !~ /^"/ || $$_[0] eq '~'), @$w;
        push @dv, [['"$', name($v, $p)]], $w; next }
      /\G($NM)(?:(=)|$END)/gc or E("unsupported '$kw' argument", $p);
      my ($n, $eq) = ($1, $2);
      E("'$kw $n' without a value (dash sets it, bash does not)", $p) if $SETOK{$n} && !$eq;
      push @dv, vname($n, $p), $eq ? word(q{e}) : undef }
    else { push @av, word('a'); push @ap, $p; $kw //= substr $_, $p, pos() - $p } }
  vname(@$_) for pairs @np;                                              # settings may outlast special builtins
  if (!@av) {   # settings alone, redirections alone (D2), or both: dash redirects before it expands the values,
    @env || @r or E('missing command', $p0);                             #   bash after; so both only with no $ or `
    E("'&>' (dash: '&', then a redirection; bash: both outputs)", $p0 - 1) if !@env && $p0 && substr($_, $p0 - 1, 2) eq '&>' && substr($_, $p0 - 2, 1) ne '&';
    E("an input redirection without a command (bash: \$(<file) reads the file)", $p0) if !@env && grep $$_[1] =~ /^</, @r;
    # settings with redirections and a $, ` or here-document: redirected first, as dash and POSIX (rule E)
    return %$c = (@env ? (set => \@env) : (argv => []), @r ? (redir => \@r) : ()) }
  E("keyword '$kw'", $ap[0]) if $KW{$kw};                                # also when it is a pattern, as [[ is
  E("'NAME[' as a command (bash reads an array)", $ap[0]) if $kw =~ /^$NM\[/;
  if (!ref $av[0] && $av[0] eq 'exec') {                                 # anywhere: it ends the shell (F3)
    shift @av; shift @ap;
    if (!@av) { @r && !@env or E("'exec' without a command", $p0); return %$c = (exec => 1, redir => \@r) }
    E("unsupported 'exec' form", $ap[0]) if !ref $av[0] && ($av[0] =~ /^-/ || $OWN{$av[0]} || $LBI{$av[0]});
    $c->{exec} = 1 }
  elsif (!ref($av[0]) && $FDEF{$av[0]}) { $c->{fn} = 1 }                # 3A: maybe a function; else the builtin's checks at run time
  elsif (!ref(my $n = $av[0])) {                                          # a literal name; else decided at run time
    local $AP = $ap[0];
    if ($n =~ /^(?:break|continue)\z/) {
      E("'$n' outside a loop", $AP) unless $LOOP + $SUBLOOP;   # in a subshell inside a loop: it ends the subshell (as dash)
      E("unsupported '$n' form", $AP) if @env || @r || @av > 2 || @av == 2 && ($av[1] !~ /^[1-9][0-9]*\z/ || $av[1] > $LOOP + $SUBLOOP) }
    elsif ($n eq 'read') {                                                 # read [-r] [-p PROMPT] NAME... (-p: P6)
      my $i = 1; while (!ref $av[$i] && ($av[$i] // '') =~ /^-(r*)(p?)\z/ && "$1$2" ne '') { $i += $2 ? 2 : 1 }
      $i <= $#av or E("'read' without a variable name", $AP);
      for my $j ($i .. $#av) {
        if (ref $av[$j]) { E("unsupported 'read' argument", $ap[$j]) if grep +(ref ? $$_[0] eq '*' && $$_[1] : $_) =~ /[\[\]]/, @{$av[$j]}; next }   # a name from an
        $av[$j] =~ /^$NM\z/ or E("unsupported 'read' argument", $ap[$j]); vname($av[$j], $ap[$j]) } }       #   expansion: checked at run time (post-0.04)
    elsif ($BI{$n}) { E("builtin '$n'", $AP) }
    elsif ($n =~ /^(?:export|readonly|local)\z/) {
      @dv && !@env && !@r or E(@dv ? "settings or redirections on '$n'" : "'$n' without arguments, or quoted", $AP);
      if ($n eq 'local') { $FUNC or E("'local' outside a function", $AP);
        E("'local NAME' without a value", $AP) if grep !defined, pairvalues @dv; $LOC{$_->[0]} = 1 for pairs @dv }
      return %$c = ($n => \@dv) }
    elsif ($n eq 'cd') {                                                   # cd [-L|-P]... [--] [DIR] (P6: the last of -L, -P counts)
      my ($i, $phys) = (1, 0); while (!ref $av[$i] && ($av[$i] // '') =~ /^-[LP]+\z/) { $phys = substr($av[$i++], -1) eq 'P' }
      $i++ if $i > 1 && !ref $av[$i] && ($av[$i] // '') eq '--';
      !@env && !defined $ENV{CDPATH} && (ref $av[$i] || ($av[$i] // '') !~ /^-./ && ($i == 1 || ($av[$i] // '') ne '-'))
        or E('unsupported cd form', $AP);                                  # 'cd -' is allowed (F12), but not after options
      return %$c = (cd => $av[$i], $phys ? (cd_p => 1) : (), @av > $i + 1 ? (cd_extra => 1) : (), @r ? (redir => \@r) : ()) }   # more operands: an error, as bash (rule E)
    if (my $chk = $CHK{$n}) { E($_, $AP) for grep $_, $chk->(@av[1 .. $#av]) }
    if ($n eq 'unalias' || $n eq 'alias' && grep ref || /=/, @av[1 .. $#av]) {                     # listing: anywhere
      (grep ref, @av[1 .. $#av]) ? ($CUT = 1) : alias_def($n, $p0, \@env, \@r, @av[1 .. $#av]) } }   # P1: known only when it runs
  $c->{env} = \@env if @env; $c->{redir} = \@r if @r;
  $c }

sub alias_at { my ($n, $p) = @_; my $v; for (@{$ALIAS{$n} // []}) { last if $$_[0] > $p; $v = $$_[1] } $v }
sub alias_expand {   # B1: if the word at pos is an alias in force here, put its value in its place in the text; 1 if so
  my $p = pos; @AEXP = grep $$_[1] > $p, @AEXP;
  /\G([A-Za-z0-9_.\-]+)(?=[ \t\n;&|()<>]|\z)/ or return 0; my $n = $1;
  return 0 if grep $$_[0] eq $n, @AEXP;                               # not again inside its own value
  my $v = alias_at($n, $p); return 0 unless defined $v;
  E("alias '$n' whose value starts with a keyword", $p) if $v =~ /^[ \t]*(\S+)/ && $KW{$1};
  substr($_, $p, length $n) = $v; pos = $p; push @AEXP, [$n, $p + length $v]; push @ASH, [$p + length $v, length($v) - length $n];
  $ANEXT = $v =~ /[ \t]\z/ ? $p + length $v : undef; 1 }
sub alias_def {   # B1: alias NAME=VALUE / unalias: only as a whole top-level command, so that it surely runs before
  my ($n, $p0, $env, $r, @a) = @_;                                    #   the lines after it, where the aliases hold
  my $before = substr $_, 0, $p0;
  return $CUT = 1   # P1 (the user, 2026-11-03: "go with better aliases"): whether it runs is known only when it runs,
    unless @OPEN == 4 && !$FUNC && !@$env && !@$r && $before =~ /(?:\A|\n|[^;];)[ \t]*\z/ && /\G[ \t]*(?:#[^\n]*)?(?:\n|;(?!;)|\z)/;   #   so the text after
  my $e = index $_, "\n", pos; $e = length($_) + 1 if $e < 0;          # from the next line on
  if ($n eq 'alias') { for (@a) { push @{$ALIAS{$1}}, [$e, $2] if /^([^=]+)=(.*)\z/s } }
  else { push @{$ALIAS{$_}}, [$e, undef] for $a[0] eq '-a' ? keys %ALIAS : @a } }

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
  return [$q . '${#', name("$1", $p)] if /\G\{#($NM|[0-9]+|[#?!\$])\}/gc;   # ${##} ${#?} ${#!} ${#$}: both shells (post-0.04)
  if (!/\G\{#/ && /\G\{($PN)(:?[-+=?]|%%?|##?)/gc) {                    # not ${##} ${#-} ...: lengths in sh
    my ($n, $op) = ($1, $2);

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
    elsif (/\G([\$`])/gc) { my $x = $1; bqdq($p) if $x eq '`' && $q;   # X41: in a pattern the outer "..." does not quote
      push @s, [x => $EX{$x}->($pat ? '' : $q, $p)] }                    #   an expansion's characters (POSIX; both shells)
    elsif (/\G\\(.)/sgc) { my $c = $1; push @s, $q && !$pat && $c !~ /[\$`"\\}]/ ? [u => "\\$c"] : [q => $c] }
    elsif (/\G'/gc) { push @s, $q && !$pat ? [u => "'"] : /\G([^']*)'/gc ? [q => $1] : E('unterminated quote', $p) }
    elsif (/\G"/gc) { push @s, [q => '']; dq(\@s, $p) }
    elsif ($pat && /\G([*?])/gc) { push @s, [g => $1] }
    elsif ($pat && /\G\[/gc) { push @s, /\G(!?\]?[^\] \t\n;&|()<>'"\\\$`{}^\/,]*\])/gc ? [g => "[$1"]
                                 : bracket(\@s, $p, '') ? () : [u => '['] }   # quotes, expansions inside (post4-0.04; X41: active)
    elsif (!$pat && /\G([*?\[])/gc) { push @s, [u => $1] }   # ${x:-a?}: active only where the ${...} is unquoted (post4-0.04)
    else  { E(/\G\z/ ? "unterminated '\${'" : 'unsupported character in a ${...} word', $p) } }
  my $k = join '', map $$_[0], @s; my @v;
  if ($pat) { push @v, defined $1 ? ['*', join '', map $$_[1], splice @s, 0, length $1] : (shift @s)->[1]
                while $k =~ /([ug]*g[ug]*)|./g }
  else { while ($k =~ /(q+)|./g) { my $t = join '', map $$_[1], my @x = splice @s, 0, length($1 // 1);
           push @v, !defined $1 ? $x[0][1] : $q ? $t : ["'", $t] } }   # quoted text in an unquoted ${...}: not split
  mkword(@v) }

sub l_arith {   # after '$((': the grammar with assignments; a variable assigned to must be assignable.  $( ), `...`,
  my $p = shift; my ($t, $d, @w) = ('', 0, '');   # ${#NAME} and $((...)) inside are expanded first (P2): then the Word
  until (!$d && /\G\)\)/gc) {                      # of the text and those Parts, else the text alone
    if    (/\G([^()\$`]+)/gc) { $t .= $1; $w[-1] .= $1 }
    elsif (/\G\(/gc) { $d++; $t .= '('; $w[-1] .= '(' }
    elsif (/\G\)/gc) { --$d >= 0 or E('bad arithmetic expression', $p); $t .= ')'; $w[-1] .= ')' }
    elsif (/\G(\$(?:\{(?:$NM|[0-9]+|[?!#\$])\}|$NM|[0-9?!#\$]))/gc) { $t .= $1; $w[-1] .= $1 }   # substituted as text
    elsif (/\G(?=\$\(|\$\{#|`)/) { my $x = /\G\$/gc ? '$' : /\G`/gc && '`';
      push @w, $EX{$x}->('"', pos() - 1), ''; $t .= '1' }   # the grammar sees an operand
    else { E('bad arithmetic expression', $p) } }
  "$t" =~ /^((?&e))(?&w)\z$ARITH/ && $t !~ /\+\+|--/ or E('bad arithmetic expression', $p);
  while ($t =~ /\b($NM)(?=[ \t\n]*(?:<<|>>|[-+*\/%&^|])?=(?!=))|\b($NM)/g) { defined $1 ? vname("$1", $p) : name("$2", $p) }
  @w > 1 ? [grep ref || length, @w] : $w[0] }

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

Where dash and bash differ, the subset takes the plainly logical behaviour where there is one, and rejects
the construct otherwise, so that the caller can hand the string to C</bin/sh> (rule E, with the list of
choices in F<doc/large-subset/large-subset-logical.md>). A construct outside the subset that shows up only at run time makes
L<Proc::ShellSpawn> stop that shell with status 248 (rule A4); differences that show up only at run time
follow dash (rule A5).

Options: those of L<Proc::ShellSubset>, except C<brace> (brace expansion is bash only).

The specification, with the tree additions, is F<doc/large-subset/large-subset-spec.md>; the corpus
measurements are in F<doc/large-subset/large-subset-state.md>.

=head1 SEE ALSO

L<Proc::ShellSubset>, L<Proc::ShellSpawn>, F<doc/large-subset/README.md>.

=cut
