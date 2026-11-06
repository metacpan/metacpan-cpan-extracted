#!/usr/bin/perl
# large-subset-features.pl (2026-11-02): which dash/bash differences a shell string uses, found from its TEXT alone
# (never by our parser), with each difference's verdict and who decided it. See doc/large-subset/large-subset-dialect-features.md.
#   Verdicts (the user's definition, 2026-11-02): B = blatant ("either one of them fails or does not match the docs; or
#   they behave in blatantly different ways"), S = subtle (any other difference in how dash and bash behave),
#   X = a decision of ours settles the shells' difference, so it does not count: the subset runs a program in place of
#   both shells' builtin (echo, printf, test, [, kill, time; the rule "the program beats blatant", see
#   large-subset-state.md, section 2), or the user decided the behaviour (B2: interactive-only builtins do nothing). Both shells refusing a form also counts as B: we refuse it too (the user, 2026-11-02).
#   Basis: P:ID = set in stone by a probe run in both shells (ID in dialect-cases/cases.txt or large-subset-dialect-probes2.txt);
#          M:N  = item N of "Bash POSIX Mode" in the Bash Reference Manual of bash 5.2.21 (Debian package bash-doc);
#          SC:CODE = ShellCheck 0.11.0 says dash lacks the construct (so dash fails), not probed one by one;
#          J = a judgement by Claude (2026-11-02), not yet reviewed by the user.
# As a library (require): features(TEXT) and sc_features(CODE => MESSAGE, ...) return [id, verdict, basis] lists.
# Usage: perl large-subset-features.pl [-n] TESTFILE... > large-subset-shells.tsv   (test files in the format of shell-subset-tests.pl)
#        -n: also give each string to dash -n and bash --posix -n (they parse it and run nothing): column 'parse'
#        perl large-subset-features.pl -s 'STRING'                            (one string)
# Output columns: file, ID, expected (ok/rej), [parse: both, dash, bash or none accept it,] verdict (B, S, or - for none
# found), features (id:verdict:basis, comma-separated).
# Detection is by patterns, so it can miss a use or see one that is not there (in a comment, or text that only looks like it).
use strict; use warnings; use FindBin;
my $RARG = qr/(?>(?:Q[^Q\n]*Q|'[^']*'|"(?:[^"\\]|\\.)*"|\$\((?:[^()]++|\((?:[^()]++|\([^()]*\))*\))*\)|`[^`]*`|\$\{[^}]*\}|\\.|[^\sQ'"`\$;&|<>()\\]+|[Q\$])++)/;   # a word (read -p PROMPT): quoted text is Q...Q in the views
my $C  = qr/(?:^|[;&|({!]\s*|\b(?:then|do|else|elif)\s+|&&\s*|\|\|\s*)/m;   # command position, roughly
my @F = (   # [id, verdict, basis, regex, on: r(aw text) or u(nquoted parts only, quoted text blanked)]
  # one shell refuses what the other runs (blatant by probe)
  [array       => B => 'P:array',      qr/\b[A-Za-z_]\w*\+?=\(|\$\{#?!?[A-Za-z_]\w*\[|\$\{?PIPESTATUS\b|${C}[A-Za-z_]\w*\[[^\]\s]*\]=/, 'g'],
  [dbracket    => B => 'P:dbracket',   qr/${C}\[\[\s/, 'u'],
  [dparen      => B => 'P:dparen',     qr/${C}\(\(/, 'u'],
  [forarith    => B => 'P:forarith',   qr/\bfor\s*\(\(/, 'u'],
  [arithop     => B => 'P:pow',        qr/\$\(\((?:[^()]|\([^()]*\))*?(?:\*\*|[0-9]#|\+\+|--|,)/, 'u'],
  [dollarbr    => B => 'P:dollarbr',   qr/\$\[/, 'u'],
  [bashparam   => B => 'P:substr',     qr/\$\{(?:!?[A-Za-z_]\w*(?:\/|:[0-9\$]|:[ \t]+-?[0-9]|\^|,|@[QEPAaKkUuL])|![A-Za-z_]\w*[*@]?\}|[@*]:[ \t]*-?[0-9\$])/, 'u'],
  [procsub     => B => 'P:procsub',    qr/(?<![\$<>])[<>]\(/, 'g'],
  [herestr     => B => 'P:herestr',    qr/<<</, 'u'],
  [pipeamp     => B => 'P:pipeamp',    qr/\|&/, 'g'],
  [dupfile     => B => 'P:dupfile',    qr/[<>]&\s*(?![0-9-]|\$)[^\s;&|()<>]/, 'u'],
  [redirdigit  => B => 'P:redirdigit', qr/>&[0-9][<>]/, 'u'],
  [fdvar       => B => 'P:fdvar',      qr/\{[A-Za-z_]\w*\}[<>]/, 'g'],
  [function    => B => 'P:function',   qr/${C}function\s+[^\s(]/, 'u'],
  [select      => B => 'P:select',     qr/${C}select\s+\w+/, 'g'],
  [casefall    => B => 'P:casefall',   qr/;;&|(?<!;);&/, 'u'],
  [unsetarr    => B => 'P:unsetarr',   qr/${C}unset(?:\s+-[vf])?(?:\s+[^\s;&|]+)*?\s+[A-Za-z_]\w*\[/, 'g'],   # post4-0.04: dash refuses it, bash unsets an element
  [bashbuiltin => B => 'P:source',     qr/${C}(?:source|declare|typeset|let|pushd|popd|dirs|shopt|mapfile|readarray|coproc|disown|enable|builtin|caller|complete|compgen|suspend)\b/, 'u'],
  [interactive => X => 'user:B2',    qr/${C}(?:history|fc|bind|help|compopt|logout)\b|\bset\s+[-+]o\s+history\b/, 'u'],   # do nothing, by the user's decision B2
  [time        => X => 'P:time',       qr/${C}time\b/, 'u'],
  [setbash     => B => 'P:setposix',   qr/\bset(?:\s+[-+][A-Za-z]*(?:o\s+[a-z]+)?)*?\s+(?:[-+][A-Za-z]*o\s+(?:pipefail|posix|histexpand|braceexpand|errtrace|functrace|onecmd|physical|keyword)\b|[-+][A-Za-z]*[BHPTEk])/, 'u'],   # also after other options (post-0.03)
  [testext     => X => 'P:testeqeq',   qr/(?:\[|\btest)\s(?:[^\]\n;&|]*\s)?==\s|(?:\[|\btest)\s+(?:!\s+)?-[av]\s/, 'u'],
  [printfext   => X => 'P:printfq',    qr/\bprintf\s+(?:-v\b|(?:--\s+)?['"]?[^'"\s]*%(?:q|\())/, 'r'],
  [readopt     => B => 'P:readn',      qr/${C}read(?:\s+(?:-r+|-r*p\s*$RARG))*\s+-[A-Za-z]*[nstadeiuN]/, 'g'],   # -p PROMPT: both (P6)
  [jobsctx     => X => 'E:info',   qr/(?:\$\(|`)\s*jobs\b|${C}jobs\b[^|;&\n)]*\|(?!\|)/, 'g'],   # inside $( ) or before a pipe: dash lists nothing (post3-0.03)
  [cdargs      => X => 'E:error',      qr/${C}cd(?:\s+-[LP]+)*+(?:\s+--)?+\s+$RARG[ \t]+(?![;&|)#<>]|[0-9]+[<>]|$)$RARG/m, 'g'],   # dash ignores extra operands, bash fails (post3-0.03)
  [readnoname  => B => 'P:readreply',  qr/${C}read(?:\s+(?:-r+|-r*p\s*$RARG))*\s*(?:$|[;&|)<>])/m, 'g'],
  [typeopt     => B => 'P:typep',      qr/${C}type\s+-[ptaPf]/, 'g'],
  [waitn       => B => 'P:waitn',      qr/${C}wait\s+-n\b/, 'g'],
  [exportopt   => B => 'P:exportf',    qr/${C}export\s+-[fn]/, 'g'],
  [execopt     => B => 'P:execa',      qr/${C}exec\s+-[acl]/, 'g'],
  [localopt    => B => 'P:localr',     qr/${C}local\s+-/, 'g'],
  [trapsig     => B => 'P:trapsigint', qr/\btrap\b[^;&|\n]*\s(?:SIG[A-Z]+|ERR|DEBUG|RETURN)\b/, 'u'],
  [jobspec     => X => 'P:job',        qr/\b(?:kill|fg|bg|wait|jobs|disown)\s+(?:-\S+\s+)*%/, 'u'],
  [fnreserved  => B => 'P:fnlocal',    qr/(?:^|[;&|\s])(?:local|source|export|exit|set|shift|eval|exec|readonly|return|trap|unset|break|continue|times|\.)\s*\(\s*\)/m, 'u'],
  [roassign    => B => 'P:uidset',     qr/(?:^|[;&|\s])(?:EUID|PPID|BASHOPTS|SHELLOPTS)=/m, 'u'],
  [uidassign   => X => 'E:posix',      qr/(?:^|[;&|\s])UID=/m, 'u'],   # an ordinary variable, as dash (G15, post-0.04)
  [uidread     => B => 'P:bashvar',    qr/(?!)/, 'u', sub { $_[0] =~ /\$\{?UID\b/ && $_[0] !~ /(?:^|[;&|\s])UID=/m }],   # set by bash
  [fdmulti     => X => 'E:same',    qr/(?:^|\s)[0-9]{2,}[<>]/m, 'u'],
  # both run it, the results always differ (blatant by probe)
  [echobs      => X => 'P:echobs',     qr/(?!)/, 'r', \&echobs],   # a backslash that reaches echo's arguments
  [echoopt     => X => 'P:echoe',      qr/${C}echo\s+-[nE]*[eE]/, 'u'],
  [ansic       => B => 'P:ansi',       qr/(?!)/, 'r', sub { dq_at(@_, "'") }],   # $'...' with the $ unquoted
  [localestr   => B => 'P:locale',     qr/(?!)/, 'r', sub { dq_at(@_, '"') }],
  [brace       => B => 'P:brace',      qr/(?<!\$)\{[^{}\s'"]*(?:,|\.\.)[^{}\s'"]*\}/, 'g'],   # g: all quoted text blanked
  [ampgt       => B => 'P:ampgt',      qr/(?<![&>])&>/, 'u'],
  [dollarlt    => B => 'P:dollarlt',   qr/\$\(\s*<|`\s*</, 'u'],
  [dotargs     => B => 'P:dotargs',    qr/${C}\.\s+[^\s;&|]+\s+[^\s;&|<>]/, 'u'],
  [dotstar     => X => 'E:harm',       qr/(?:^|[\s\/=])\.[*?]+(?=$|[\s\/;&|)])/m, 'g'],   # a component that can match . or ..
  [caret       => X => 'E:platform',      qr/\[\^/, 'g'],
  [atlen       => B => 'P:atlen',      qr/\$\{#[@*]\}/, 'u'],
  [atpat       => X => 'E:same',       qr/\$\{[@*](?:%|#)/, 'u'],   # on each parameter, as bash (G4, post-0.04)
  [bqdq        => B => 'P:bqdq',       qr/"\$\{[^}]*`[^`]*\\"/, 'r'],
  [bashvar     => B => 'P:bashvar',    qr/\$\{?(?:RANDOM|SRANDOM|SECONDS|BASH_VERSION|BASH_VERSINFO|BASHPID|BASH_SOURCE|BASH_LINENO|FUNCNAME|EUID|HOSTNAME|OSTYPE|HOSTTYPE|MACHTYPE|EPOCHSECONDS|EPOCHREALTIME|GROUPS|HISTCMD|DIRSTACK|BASH)\b/, 'u'],
  [underscore  => B => 'P:underscore', qr/\$_(?![A-Za-z0-9_])|\$\{_\}/, 'u'],
  # judgements (not yet reviewed)
  [dashflags   => B => 'J',            qr/\$-|\$\{-\}/, 'u'],           # the value always differs; a test for *i* agrees
  [lineno      => X => 'E:info',       qr/\$\{?LINENO\b/, 'u'],         # the line number, as bash (G8, post-0.04); dash: empty in -c
  [scope       => B => 'P:local',      qr/(?!)/, 'u', sub { $_[0] =~ /${C}local\b(?!=)/ && $_[0] !~ /\w\s*\(\s*\)/ }],   # local outside a function: both shells fail
  [returnout   => X => 'E:error',      qr/(?!)/, 'u', sub { $_[0] =~ /${C}return\b(?!=)/ && $_[0] !~ /\w\s*\(\s*\)/ }],   # return outside a function: an error, as bash (rule E)
  [killsig     => B => 'M:38',         qr/\bkill\s+-SIG/, 'u'],          # both refuse in --posix; whether bash's manual allows it: not checked
  [specialerr  => X => 'E:posix',         qr/(?!)/, 'u'],                   # a special builtin's error (dash stops, bash goes on): not detectable from text
  # subtle
  [localnoval  => S => 'P:local',      qr/\blocal\s+(?:[A-Za-z_]\w*\s+)*[A-Za-z_]\w*(?:\s*$|\s*[;&|)])/m, 'u'],
  [atassign    => S => 'P:atjoin',     qr/=["]?\$\{?@/, 'r'],
  [assignredir => X => 'E:effect',            qr/(?:^|[;&|]\s*)[A-Za-z_]\w*=[^\s;&|]*[\$`][^;&|\n]*\s[0-9]*[<>]/m, 'u'],
  [qmark       => X => 'E:meaning',    qr/\$\{[A-Za-z_]\w*:?\?/, 'u'],   # done (rule A5, as dash; large-subset-logical.md, N2)
  [cmdv        => X => 'user:A5',      qr/\bcommand\s+-v\b/, 'u'],       # done (rule A5 stands, as dash; N3)
  [getopts     => X => 'E:posix', qr/\bgetopts\b/, 'u'],
  [listing     => S => 'P:listset',    qr/${C}(?:set|export|readonly|trap|alias)\s*(?:$|[;&|)])|\b(?:export|readonly)\s+-p\b/m, 'u'],
  [trace       => S => 'P:setx',       qr/\bset\s+(?:[-+][A-Za-z]*[xv]|[-+]o\s+(?:xtrace|verbose))/, 'u'],
  [setm        => S => 'P:setm',       qr/\bset\s+-[A-Za-z]*m/, 'u'],
  [ps1         => S => 'P:ps1',        qr/\$\{?PS1\b/, 'u'],
  [nohome      => X => 'E:info',       qr/\bunset\b[^;&|\n]*\bHOME\b/, 'u'],   # ~ from the password file, as bash (G16, post-0.04)
);
sub ctx {   # the quoting context of each character: u(nquoted) e(scaped: \ and the next) s(ingle) d(ouble) b(ackquoted)
  my $s = shift; my ($m, $st) = ('', '');   # $st: 'd' inside "...", 'b' inside `...`, 'bd' "..." inside `...`
  while ($s =~ /\G(?:(\\.)|(')|(")|(`)|(.))/sgc) {
    my $in = substr($st, -1) // '';
    if (defined $1) { $m .= $in eq 'd' ? 'dd' : $in eq 'b' ? 'bb' : 'ee' }
    elsif (defined $2) { if ($in eq 'd') { $m .= 'd' } else { $s =~ /\G[^']*'?/gc; $m .= 's' x ($+[0] - $-[0] + 1) } }
    elsif (defined $3) { $m .= 'd'; $in eq 'd' ? chop $st : ($st .= 'd') }
    elsif (defined $4) { $m .= 'b'; $in eq 'b' ? chop $st : ($st .= 'b') }
    else { $m .= $in eq 'd' ? 'd' : $in eq 'b' ? 'b' : 'u' } }
  $m }
sub view { my ($s, $m, $blank) = @_; join '', map { substr($m, $_, 1) =~ $blank ? 'Q' : substr($s, $_, 1) } 0 .. length($s) - 1 }
sub dq_at { my ($s, $m, $q) = @_; my $i = -1;   # an unquoted (or backquoted) $ followed by the quote $q
  while (($i = index $s, "\$$q", $i + 1) >= 0) { return 1 if substr($m, $i, 1) =~ /[ub]/ } 0 }
sub echobs {   # does a backslash survive into an argument of echo, before a letter dash's echo expands (a b c f n r t v 0 \)?
  my ($s, $m) = @_;
  while ($s =~ /${C}echo\b/g) { my $i = pos $s;
    while ($i < length $s) { my ($c, $k) = (substr($s, $i, 1), substr($m, $i, 1));
      last if $k eq 'u' && $c =~ /[;&|\n)]/;
      if ($c eq '\\') { my $n = $i + 1 < length $s ? substr($s, $i + 1, 1) : '';
        my $e = qr/[abcfnrtv0]/;   # '\x' and "\x": x follows; "\\x", \\x: a backslash, then x
        my $n2 = $i + 2 < length $s ? substr($s, $i + 2, 1) : '';
        return 1 if $k eq 's' && $n =~ /$e|\\/ || $k eq 'd' && ($n =~ $e || $n eq '\\' && $n2 =~ /$e|\\/)
          || $k eq 'e' && $n eq '\\' && $n2 =~ /$e|\\/;
        $i++ if $k ne 's' }
      $i++ } }
  0 }
sub features { my $s = shift; my $m = ctx($s); my %v = (r => $s, u => view($s, $m, qr/s/), g => view($s, $m, qr/[sd]/),
    ); my @f;
  for (@F) { my ($id, $v, $b, $re, $on, $cond) = @$_;
    push @f, [$id, $v, $b] if $cond ? $cond->($s, $m) : $v{$on} =~ $re }
  @f }
sub verdict { my @f = @_; my %v = map +($$_[1] => 1), @f; $v{B} ? 'B' : $v{S} ? 'S' : $v{X} ? 'X' : '-' }
my %SCX = map +($_ => 1), qw(SC3014 SC3015 SC3016 SC3017 SC3062 SC3063 SC3064 SC3036 SC3050);   # test, echo, printf: programs
sub sc_features {   # ShellCheck's portability codes (SC3xxx) of a sample, with their messages -> [id, verdict, basis]
  my %m = @_; my @f;
  for my $c (sort keys %m) { my $msg = $m{$c} // '';
    if ($SCX{$c}) { push @f, [lc $c, X => "SC:$c"] }
    elsif ($c eq 'SC3026') { push @f, [sc3026 => X => 'E:platform'] }   # ^ in a bracket expression negates (rule E, as caret)
    elsif ($c eq 'SC3023') { push @f, [sc3023 => X => 'E:same'] }       # descriptors above 9 (rule E, as fdmulti)
    elsif ($c eq 'SC3058') { push @f, [sc3058 => X => 'E:same'] }       # string operations on $@, $* (rule E, as atpat; post-0.04)
    elsif ($c eq 'SC3031') { push @f, [sc3031 => '-' => 'M:13'] }        # bash --posix does not glob a redirection target either
    elsif ($c eq 'SC3045' && $msg =~ /\bread -p\b/) { push @f, ['sc3045-read-p', '-' => 'P:readp'] }   # dash 0.5.12 has read -p
    elsif ($c eq 'SC3045' && $msg =~ /\bprintf -v\b/) { push @f, ['sc3045-printf-v', X => 'P:printfv'] }
    elsif ($c eq 'SC3044' && $msg =~ /'/ && !grep !/^(?:history|fc|bind|help|compopt|logout)\z/, $msg =~ /'([^']+)'/g) {
      push @f, ['sc3044-interactive', X => 'user:B2'] }                      # interactive-only builtins: nothing (B2)
    else { push @f, [lc $c, B => "SC:$c"] } }
  grep $$_[1] ne '-', @f }
return 1 if caller;
if (@ARGV && $ARGV[0] eq '-s') { my @f = features($ARGV[1]); print verdict(@f), "\t", join(',', map join(':', @$_), @f), "\n"; exit }
my $N = @ARGV && $ARGV[0] eq '-n' && shift;
sub syn { my ($t, @sh) = @_; my $pid = fork // die;
  unless ($pid) { open STDERR, '>', '/dev/null'; open STDOUT, '>', '/dev/null'; open STDIN, '<', '/dev/null';
    exec @sh, '-n', '-c', $t; exit 127 }
  waitpid $pid, 0; $? == 0 }
sub parse { my $s = shift; my ($d, $b) = (syn($s, 'dash'), syn($s, 'bash', '--posix')); $d && $b ? 'both' : $d ? 'dash' : $b ? 'bash' : 'none' }
my %VD; if (open my $h, '<:utf8', "$FindBin::Bin/large-subset-verdicts.txt") { my $k;   # hand-kept verdicts, as in large-subset-yardsticks.pl
  while (<$h>) { chomp; next if /^#/; if (/^(feature|test):(\S+)\t(.*)$/) { $k = "$1:$2"; my $t = $3;
      $VD{$k} = $t =~ /^([BSX-])(?:\s+(\S+))?\s*$/ ? [$1, $2 // 'user'] : ['O', $t] }
    elsif (/^\t(.*)$/ && $k && $VD{$k}[0] eq 'O') { $VD{$k}[1] .= " $1" } } }
print join("\t", qw(file id expected), $N ? 'parse' : (), qw(verdict features note)), "\n";
for my $file (@ARGV) { (my $fn = $file) =~ s{.*/}{};
  open my $h, '<', $file or die "$file: $!"; my $data;
  while (<$h>) { $data ||= /^__DATA__/; next unless /^(ok|rej)\s+\S+\s+(\S+)\s+(.*)$/;
    my ($exp, $id, $s) = ($1, $2, $3); $s =~ s/\@N/\n/g; $s =~ s/\@T/\t/g; $s =~ s/\@R/\r/g;
    my @f = features($s); my $ps = $N ? parse($s) : '';
    unshift @f, ['parse', 'B', 'P:-n'] if $N && $ps ne 'both';   # a shell refuses to parse it: fails, set in stone
    for (@f) { my $o = $VD{"feature:$$_[0]"} or next; @$_[1, 2] = ($$o[0], $$o[0] eq 'O' ? 'open' : $$o[1]) }
    my $v = verdict(@f); $v = 'O' if $v ne 'B' && grep $$_[1] eq 'O', @f; my $note = '';
    if (my $o = $VD{"test:$id"}) { ($v, $note) = ($$o[0], $$o[1]) }   # a verdict for one test, by its snippet ID
    print join("\t", $fn, $id, $exp, $N ? $ps : (), $v, join(',', map join(':', @$_), @f), $note), "\n" } }
