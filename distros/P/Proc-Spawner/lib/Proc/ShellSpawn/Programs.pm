package Proc::ShellSpawn::Programs;
# echo, printf, test and [ (and true, false) as GNU coreutils 9.4 does them, inside the Perl process (X21; the user,
# 2026-11-08).  The subset runs them as programs, and their behaviour is part of the subset's meaning
# (large-subset-state.md, section 2), so these follow coreutils, not the shells' builtins.  Each function takes
# (ARGV, ENV, OPT) and returns (STDOUT, STDERR, STATUS, ORDER), ORDER (printf only; else undef) the same text as
# [FD, TEXT] pieces in the order coreutils writes them:
#   ARGV  the command's words, ARGV->[0] its name as written (the messages name it so, as coreutils does)
#   ENV   the command's environment (a hash): POSIXLY_CORRECT for echo, LC_ALL/LC_CTYPE/LC_MESSAGES/LANG for quotes
#   OPT   { isatty => CODE } for test -t FD (the command's FD, not Perl's); { cwd => DIR }: test's relative file names
#         are taken from DIR (the shell's directory, not Perl's)
# Differences known (doc/pspawn-known-issues.md, X21): --help and --version print a short text; printf's floating
# conversions use Perl's double (coreutils: long double); %q follows gnulib's fixed rule (decision IP2).
# Integers go through Perl's own sprintf, so a perl with 64-bit integers is assumed (ivsize 8: Strawberry, Linux).
use strict; use warnings;
use POSIX (); use File::Spec (); use Math::BigInt ();
our $VERSION = '0.10';

my $IMAX = Math::BigInt->new('9223372036854775807'); my $IMIN = -$IMAX - 1;
my $UMAX = Math::BigInt->new('18446744073709551615');
my %CESC = ("\a" => 'a', "\b" => 'b', "\f" => 'f', "\n" => 'n', "\r" => 'r', "\t" => 't', "\013" => 'v');
my $UTF8 = qr/[\xc2-\xdf][\x80-\xbf]|\xe0[\xa0-\xbf][\x80-\xbf]|[\xe1-\xec\xee\xef][\x80-\xbf]{2}|\xed[\x80-\x9f][\x80-\xbf]
             |\xf0[\x90-\xbf][\x80-\xbf]{2}|[\xf1-\xf3][\x80-\xbf]{3}|\xf4[\x80-\x8f][\x80-\xbf]{2}/x;   # one valid character
sub utf8_locale { my ($env, @cat) = @_; (grep $_, map $env->{$_}, 'LC_ALL', @cat, 'LANG')[0] // '' }
sub is_utf8 { utf8_locale(@_) =~ /utf-?8/i }
sub printable { my ($c, $u) = @_;   # a character (one byte, or a valid UTF-8 sequence in a UTF-8 locale)
  return $c =~ /\A[\x20-\x7e]\z/ if length $c == 1; return 0 unless $u; utf8::decode($c); $c =~ /\A\p{Print}\z/ }
sub chars { my ($s, $u) = @_; $u ? $s =~ /$UTF8|./gs : split //, $s }

sub q_ { my ($env, $s) = @_;   # coreutils' quote(): 'x' in the C locale, curly quotes in a UTF-8 one; inside, a backslash
  # doubled, control characters as C escapes, what the locale cannot print in octal, and (C locale) \' for '
  my $u = is_utf8($env, 'LC_MESSAGES');
  my $t = join '', map { printable($_, $u) ? ($_ eq '\\' ? '\\\\' : $_ eq "'" && !$u ? "\\'" : $_)
                                           : join '', map $CESC{$_} ? "\\$CESC{$_}" : sprintf('\\%03o', ord), split // } chars($s, $u);
  $u ? "\xe2\x80\x98$t\xe2\x80\x99" : "'$t'" }

# ------------------------------------------------------------------ echo
sub echo {
  my ($argv, $env) = @_; $env //= {};
  my @a = @$argv[1 .. $#$argv];
  my $posix = defined $env->{POSIXLY_CORRECT};
  my ($nl, $esc) = (1, $posix);   # POSIXLY_CORRECT: escapes always, options only for a first -n
  if (!$posix || (@a && $a[0] eq '-n')) {
    return ($1 eq 'help' ? help('echo') : version('echo'), '', 0) if @a == 1 && $a[0] =~ /^--(help|version)\z/;
    while (@a && $a[0] =~ /^-([eEn]+)\z/) { shift @a; for (split //, $1) { $_ eq 'n' ? ($nl = 0) : ($esc = $_ eq 'e' || $posix) } } }
  my $out = join ' ', @a;
  if ($esc) { ($out, my $stop) = esc($out, 'echo'); return ($out, '', 0) if $stop }   # \c: nothing more, not the newline
  ($out . ($nl ? "\n" : ''), '', 0) }

# The backslash escapes of echo -e and printf's %b (MODE 'echo' or 'b'), or of printf's format ('fmt').  Returns
# (TEXT, STOP, ERROR): STOP after \c, ERROR for printf's "missing hexadecimal number".
my %SIMPLE = (a => "\a", b => "\b", e => "\e", f => "\f", n => "\n", r => "\r", t => "\t", v => "\013", '\\' => '\\');
sub esc {
  my ($s, $mode) = @_; my $o = '';
  my $oct = $mode eq 'fmt' ? qr/([0-7]{1,3})/ : qr/0([0-7]{0,3})|([1-7][0-7]{0,2})/;   # echo and %b: \0NNN or \NNN
  while ($s =~ /\G(?:([^\\]+)|\\)/gc) {
    if (defined $1) { $o .= $1; next }
    if ($s =~ /\G$oct/gc) { $o .= chr(oct('0' . ($1 // $2)) & 255) }
    elsif ($s =~ /\G([abefnrtv\\])/gc) { $o .= $SIMPLE{$1} }
    elsif ($s =~ /\Gc/gc) { return ($o, 1) }
    elsif ($s =~ /\Gx([0-9A-Fa-f]{1,2})/gc) { $o .= chr hex $1 }
    elsif ($mode ne 'echo' && $s =~ /\G(?:u([0-9A-Fa-f]{4})|U([0-9A-Fa-f]{8}))/gc) { my $c = chr hex($1 // $2); utf8::encode($c); $o .= $c }
    elsif ($mode ne 'echo' && $s =~ /\G[xuU]/gc) { return ($o, 0, 'missing hexadecimal number in escape') }
    elsif ($mode eq 'fmt' && $s =~ /\G"/gc) { $o .= '"' }
    else { $o .= '\\' }   # anything else (and a final backslash): the backslash as it is
  }
  ($o, 0) }

# ------------------------------------------------------------------ printf
# coreutils' printf.c: the flags each conversion takes (' and I not with a A c e E o s x X, # not with c d i s u, 0 not
# with c s, a precision not with c); %b and %q take nothing between % and the letter.
my %NOT = ("'" => 'aAceEosxX', I => 'aAceEosxX', '#' => 'cdisu', 0 => 'cs');
sub printf {
  my ($argv, $env) = @_; $env //= {};
  my ($name, @a) = @$argv;
  return ($1 eq 'help' ? help('printf') : version('printf'), '', 0) if @a == 1 && $a[0] =~ /^--(help|version)\z/;
  shift @a if @a && $a[0] eq '--';
  return ('', "$name: missing operand\nTry '$name --help' for more information.\n", 1) unless @a;
  my $fmt = shift @a;
  my ($out, $err, $bad, $flushed, @seq) = ('', '', 0, 0);
  my $msg = sub { push @seq, [1, substr $out, $flushed], [2, "$name: $_[0]\n"]; $flushed = length $out; $err .= "$name: $_[0]\n" };
  my $warn = sub { $msg->(q_($env, $_[0]) . ": $_[1]"); $bad = 1 };
  my $done = sub { ($out, $err, $_[0] // $bad, [@seq, [1, substr $out, $flushed]]) };
  my $num = sub {   # an argument as a number, with coreutils' messages; KIND i (intmax_t), u (uintmax_t), f (double)
    my ($s, $kind) = @_;
    return 0 if !defined $s || $s eq '';
    if ($s =~ /^\s*['"](.)(.*)/s) {   # 'c: the character's code (a warning for more, the status kept)
      $msg->("warning: $2: character(s) following character constant have been ignored") if length $2; return ord $1 }
    if ($kind eq 'f') {
      my ($v, $left) = POSIX::strtod($s); $left //= length $s;
      $warn->($s, $left == length $s ? 'expected a numeric value' : 'value not completely converted') if $left;
      return $left == length $s ? 0 : $v }
    my ($sign, $body, $rest) = $s =~ /^\s*([-+]?)(0[xX][0-9A-Fa-f]+|0[0-7]*|[1-9][0-9]*)(.*)\z/s
      or do { $warn->($s, 'expected a numeric value'); return 0 };
    my $from = $body =~ /^0[xX]/ ? 'from_hex' : $body =~ /^0./ ? 'from_oct' : 'new';
    my $v = Math::BigInt->$from($body);
    $v->bneg if $sign eq '-';
    my ($lo, $hi) = $kind eq 'u' ? (-$UMAX, $UMAX) : ($IMIN, $IMAX);   # (strtoumax: -N is 2**64 - N)
    if ($v < $lo || $v > $hi) { $warn->($s, 'Numerical result out of range'); $v = $kind eq 'u' || $v > 0 ? $hi : $lo }
    elsif (length $rest) { $warn->($s, 'value not completely converted') }
    $v += $UMAX + 1 if $v < 0 && $kind eq 'u';
    "$v" };
  my $used;
  while (1) {
    my $took = 0;
    while ($fmt =~ /\G(?:([^%\\]+)|\\(0?[0-7]{1,3}|x[0-9A-Fa-f]{0,2}|u[0-9A-Fa-f]{0,4}|U[0-9A-Fa-f]{0,8}|.?)|%(%)|%([bq])
                       |%([-+ #0'I]*)(\*|[0-9]*)(?:\.(\*|[0-9]*))?[lLhjtz]*(.?))/gcsx) {
      my ($text, $e, $pct, $bq, $fl, $w, $p, $cv, $from) = ($1, $2, $3, $4, $5, $6, $7, $8, $-[0]);
      if (defined $text) { $out .= $text; next }
      if (defined $pct) { $out .= '%'; next }
      if (defined $e) {
        my ($t, $stop, $error) = esc("\\$e", 'fmt'); $out .= $t;
        if ($error) { $msg->($error); return $done->(1) }
        return $done->() if $stop; next }
      $cv = $bq, $fl = $w = '' if defined $bq;
      if (!defined $bq && ($cv !~ /^[aAcdeEfFgGiosuxX]\z/ || grep(index($NOT{$_} // "", $cv) >= 0, split //, $fl) || defined $p && $cv eq 'c')) {
        $msg->(substr($fmt, $from, pos($fmt) - $from) . ": invalid conversion specification"); return $done->(1) }   # (as written)
      $used = 1;
      if ($w eq '*') { $w = 0 + $num->(shift(@a), 'i'); $took++; $fl .= '-', $w = -$w if $w < 0 }
      if (defined $p && $p eq '*') { $p = 0 + $num->(shift(@a), 'i'); $took++; undef $p if $p < 0 }
      my $arg = shift @a; $took++ if defined $arg;
      $fl =~ tr/'I//d;   # (grouping, the locale's digits: none in the C locale)
      my $spec = "%$fl$w" . (defined $p ? ".$p" : '');
      if ($cv eq 'q') { $out .= shell_quote($arg, $env) if defined $arg }   # (no argument: nothing)
      elsif ($cv eq 'b') {
        my ($t, $stop, $error) = esc($arg // '', 'b');
        if ($error) { $msg->($error); return $done->(1) }
        $out .= sprintf "${spec}s", $t; return $done->() if $stop }
      elsif ($cv eq 's') { $out .= sprintf "${spec}s", $arg // '' }
      elsif ($cv eq 'c') { my $c = substr $arg // '', 0, 1; $out .= sprintf "${spec}s", length $c ? $c : "\0" }   # (none: a NUL)
      elsif ($cv =~ /[di]/) { $out .= sprintf "${spec}d", $num->($arg, 'i') }
      elsif ($cv =~ /[ouxX]/) { $out .= sprintf "$spec$cv", $num->($arg, 'u') }
      else { $out .= float($spec, $fl, $w, $p, $cv, $num->($arg, 'f'), $arg) } }
    last unless @a && $took;
    pos $fmt = 0 }
  $msg->("warning: ignoring excess arguments, starting with " . q_($env, $a[0])) if @a && !$used;
  $done->() }

sub float {   # a floating conversion: Perl's sprintf, but inf and nan as glibc writes them, and an integer below 2**64
  my ($spec, $fl, $w, $p, $cv, $v, $arg) = @_;   # under %f exact, as coreutils' long double has it (a double rounds)
  my $sign = $fl =~ /\+/ ? '+' : $fl =~ / / ? ' ' : '';
  if ($v != $v || abs $v == 9**9**9) {
    my $t = ($v < 0 ? '-' : $sign) . ($v != $v ? 'nan' : 'inf');
    return pad($fl =~ tr/0//dr, $w, $cv =~ /[EFGA]/ ? uc $t : $t) }
  if ($cv =~ /[fF]/ && defined $arg && $arg =~ /^\s*([-+]?)0*([0-9]{16,20})\s*\z/ && Math::BigInt->new($2) <= $UMAX) {
    my $prec = $p // 6; $prec ||= 0;
    return pad($fl, $w, ($1 eq '-' ? '-' : $sign) . $2 . ($prec || $fl =~ /#/ ? '.' . '0' x $prec : '')) }
  sprintf "$spec$cv", $v }
sub pad { my ($fl, $w, $t) = @_;   # a number's text in WIDTH, by the flags - and 0 (zeros after the sign)
  my $n = ($w || 0) - length $t; return $t if $n <= 0;
  $fl =~ /-/ ? $t . ' ' x $n : $fl =~ /0/ ? $t =~ s/^([-+ ]?)/$1 . '0' x $n/er : ' ' x $n . $t }

# %q: gnulib's quotearg in shell_escape_quoting_style, as coreutils' printf, with gnulib's later fix (decision IP2): a
# word needing no quotes as it is; else in '...', a ' as '\'', what must be escaped (controls; what the locale cannot
# print, byte by byte in octal) in $'...' runs; a word whose only trouble is a ' (and spaces, #, ~ in front) in "...".
my %QESC = (%CESC, "\0" => '0');
sub shell_quote {
  my ($w, $env) = @_; my $u = is_utf8($env // {}, 'LC_CTYPE');
  my @c = chars($w, $u); my $plain = !grep !printable($_, $u), @c;
  return $w if $w ne '' && $plain && $w !~ /[\\?'\s!"\$&()*;<=>\[^`|]|^[#~]|^[{}]\z/;
  return qq{"$w"} if $plain && $w =~ /'/ && $w !~ /[\\?!"\$&()*;<=>\[^`|{}]|.[#~]/s;
  my ($q, $dollar) = ("'", 0);
  for (@c) {
    if (!printable($_, $u)) { $q .= q{'$'} unless $dollar; $dollar = 1; $q .= join '', map $QESC{$_} ? "\\$QESC{$_}" : sprintf('\\%03o', ord), split // }
    elsif ($_ eq "'") { $q .= q{'\''}; $dollar = 0 }
    else { $q .= "''" if $dollar; $dollar = 0; $q .= $_ } }
  "$q'" }

# ------------------------------------------------------------------ test and [
# coreutils' grammar: with 1 to 4 arguments the POSIX rules, else (and inside them where they say so) the expression
# -o, -a, !, ( ), -l STRING as an integer.  The words are consumed from @W; for [, the ] stays in $BEYOND, past the
# end, where coreutils' messages still see it ("')' expected, found ']'").
my %UNARY = map +($_ => 1), qw(-b -c -d -e -f -g -G -h -k -L -N -O -p -r -s -S -t -u -w -x -z -n);
my %BINARY = map +($_ => 1), qw(= == != -eq -ne -lt -le -gt -ge -nt -ot -ef);
our (@W, $LAST, $BEYOND, $ENV, $OPT);
sub test {
  my ($argv, $env, $opt) = @_;
  my ($name, @a) = @$argv; my $br = $name =~ m{(?:^|/)\[\z};
  if ($br) {
    return ($1 eq 'help' ? help('[') : version('['), '', 0) if @a == 1 && $a[0] =~ /^--(help|version)\z/;
    return ('', "$name: missing " . q_($env // {}, ']') . "\n", 2) unless @a && pop(@a) eq ']' }
  local (@W, $LAST, $BEYOND, $ENV, $OPT) = (@a); ($LAST, $BEYOND, $ENV, $OPT) = ($a[-1], $br ? ']' : undef, $env // {}, $opt // {});
  my $r = eval { my $v = @W ? posix(scalar @W) : 0; die "extra argument " . q_($ENV, $W[0]) . "\n" if @W; $v ? 1 : 0 };
  defined $r ? ('', '', $r ? 0 : 1) : ('', "$name: " . $@, 2) }

sub beyond { die "missing argument after " . q_($ENV, $LAST) . "\n" }
sub next_word { shift @W; beyond() unless @W; 1 }   # coreutils' advance(true)
sub dash1 { defined $_[0] && $_[0] =~ /^-.\z/s }
sub posix {
  my $n = shift;
  if ($n == 1) { return length shift @W }
  if ($n == 2) {
    return !posix(1) if $W[0] eq '!' && shift @W;
    return unary_op() if $UNARY{$W[0]};
    dash1($W[0]) ? die q_($ENV, $W[0]) . ": unary operator expected\n" : beyond() }
  if ($n == 3) {
    return binary_op(0) if $BINARY{$W[1]};
    return next_word() && !posix(2) if $W[0] eq '!';
    return (shift @W, posix(1), shift @W)[1] if $W[0] eq '(' && $W[2] eq ')';
    return expr() if $W[1] =~ /^-[ao]\z/;
    die q_($ENV, $W[1]) . ": binary operator expected\n" }
  if ($n == 4) {
    return next_word() && !posix(3) if $W[0] eq '!';
    return (shift @W, posix(2), shift @W)[1] if $W[0] eq '(' && $W[3] eq ')' }
  expr() }
sub expr { beyond() unless @W; my $v = and_(); while (@W && $W[0] eq '-o') { shift @W; my $r = and_(); $v ||= $r } $v }
sub and_ { my $v = term(); while (@W && $W[0] eq '-a') { shift @W; my $r = term(); $v &&= $r } $v }   # (every term evaluated)
sub term {
  my $neg = 0;
  next_word(), $neg = !$neg while @W && $W[0] eq '!';
  beyond() unless @W;
  my $v;
  if ($W[0] eq '(') {
    next_word();
    my ($close) = grep $W[$_] eq ')', 1 .. ($#W < 4 ? $#W : 4);   # the POSIX rules up to a ')' at most 4 words on
    $v = posix($close // scalar @W);
    my $at = @W ? $W[0] : $BEYOND;
    die q_($ENV, ')') . " expected" . (defined $at ? ", found " . q_($ENV, $at) : '') . "\n" unless defined $at && $at eq ')';
    shift @W }
  elsif (@W >= 4 && $W[0] eq '-l' && $BINARY{$W[2]}) { shift @W; $v = binary_op(1) }
  elsif (@W >= 3 && $BINARY{$W[1]}) { $v = binary_op(0) }
  elsif (dash1($W[0])) { die q_($ENV, $W[0]) . ": unary operator expected\n" unless $UNARY{$W[0]}; $v = unary_op() }
  else { $v = length shift @W }
  $neg ? !$v : $v }
sub unary_op { my $op = shift @W; beyond() unless @W; unary($op, shift @W) }
sub binary_op {   # L: -l STRING before (already taken); -l STRING after counts for the integer operators only
  my $l = shift;
  my ($x, $op) = splice @W, 0, 2; my $y = shift @W;
  my $r = $y eq '-l' && @W ? shift @W : undef;   # (coreutils: -l after the operator, with a word after it)
  if ($op =~ /^-(?:eq|ne|lt|le|gt|ge)\z/) { $x = length $x if $l; $y = length $r if defined $r }
  binary($x, $op, $y) }

sub int_of { my $s = shift;   # an integer of test: blanks around, a sign, digits (any length)
  $s =~ /^[ \t]*([-+]?[0-9]+)[ \t]*\z/ ? Math::BigInt->new($1) : die "invalid integer " . q_($ENV, $s) . "\n" }
sub path { my $f = shift; defined $OPT->{cwd} && length $f && !File::Spec->file_name_is_absolute($f) ? "$OPT->{cwd}/$f" : $f }
sub mtime { my @s = eval { require Time::HiRes; Time::HiRes::stat($_[0]) }; @s = stat $_[0] unless @s; @s ? $s[9] : undef }
my %CMP = (eq => sub { $_[0] == 0 }, ne => sub { $_[0] != 0 }, lt => sub { $_[0] < 0 }, le => sub { $_[0] <= 0 },
           gt => sub { $_[0] > 0 }, ge => sub { $_[0] >= 0 });
sub binary {
  my ($x, $op, $y) = @_;
  return $x eq $y if $op eq '=' || $op eq '==';
  return $x ne $y if $op eq '!=';
  return $CMP{$1}->(int_of($x) <=> int_of($y)) if $op =~ /^-(eq|ne|lt|le|gt|ge)\z/;
  ($x, $y) = (path($x), path($y));
  if ($op eq '-ef') { my @a = stat $x; my @b = stat $y; return @a && @b && $a[0] == $b[0] && $a[1] == $b[1] }
  my ($new, $old) = map mtime($_), $op eq '-nt' ? ($x, $y) : ($y, $x);
  defined $new && (!defined $old || $new > $old) }
sub unary {
  my ($op, $f) = @_;
  return !length $f if $op eq '-z';
  return length $f if $op eq '-n';
  if ($op eq '-t') { my $d = int_of($f); return $d >= 0 && ($OPT->{isatty} ? $OPT->{isatty}->("$d") : POSIX::isatty("$d")) }
  $f = path($f);
  return -l $f if $op eq '-h' || $op eq '-L';
  my @s = stat $f or return 0;
  return { -e => 1, -f => -f _, -d => -d _, -b => -b _, -c => -c _, -p => -p _, -S => -S _, -u => -u _, -g => -g _,
           -k => -k _, -s => $s[7] > 0, -O => $s[4] == $>, -G => $s[5] == (split ' ', $))[0], -N => $s[9] > $s[8],
           -r => -r $f, -w => -w $f, -x => -x $f }->{$op} }

sub help { my $n = shift; "Usage: $n ...\n(in the Perl process: Proc::ShellSpawn::Programs, after GNU coreutils 9.4's $n)\n" }
sub version { my $n = shift; "$n (Proc::ShellSpawn::Programs $VERSION, after GNU coreutils 9.4)\n" }
sub true { ('', '', 0) }
sub false { ('', '', 1) }

1;

__END__

=head1 NAME

Proc::ShellSpawn::Programs - echo, printf, test and [ as GNU coreutils 9.4 does them, inside the Perl process (EXPERIMENTAL)

=head1 SYNOPSIS

  my ($out, $err, $status) = Proc::ShellSpawn::Programs::printf(['printf', '%s|%5.2f\n', 'x', 3.14159], { LC_ALL => 'C' });

=head1 DESCRIPTION

C<echo>, C<printf>, C<test> (also for C<[>), C<true> and C<false> take
C<(\@ARGV, \%ENV, \%OPT)> and return C<(STDOUT, STDERR, STATUS)>; C<printf>
also returns, fourth, the same text as C<[FD, TEXT]> pieces in the order
coreutils writes them.  C<ARGV-E<gt>[0]> is the name as written (messages use
it).  C<ENV> gives C<POSIXLY_CORRECT> (echo) and the locale (C<LC_ALL>,
C<LC_CTYPE>, C<LC_MESSAGES>, C<LANG>: UTF-8 or not, for quotes and C<%q>).
C<OPT>: C<cwd> (test's relative file names), C<isatty> (a code ref for
C<test -t FD>).

L<Proc::ShellSpawn> runs them in place of the programs (by default; see
C<PROC_SHELLSPAWN_INPROC> there).  The known differences from coreutils 9.4
are listed as X21 in F<doc/pspawn-known-issues.md>.

=cut
