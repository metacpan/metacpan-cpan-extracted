# Proc::ShellSpawn::Programs (echo, printf, test, [ inside the Perl process) against what GNU coreutils 9.4 did with the same
# words, in the C and the C.UTF-8 locale: t/programs.txt, recorded by 'perl t/programs.t --record' where coreutils 9.4 is
# installed (Ubuntu 24.04).  The cases: written by hand, and generated with a fixed seed (a third of those checked when the
# module was written: 12266 runs, differing only where X21 says).  File tests use fixtures in a temporary directory.
use strict; use warnings; no warnings "qw";   # (printf formats with # in qw lists)
use Test::More; use File::Temp 'tempdir'; use Cwd 'abs_path';
use lib 'lib'; use Proc::ShellSpawn::Programs;
my $record = @ARGV && $ARGV[0] eq '--record';
my $record_sh = @ARGV && $ARGV[0] eq '--record-shells';
my $data = abs_path('t') . '/programs.txt'; my $data_sh = abs_path('t') . '/echo-shells.txt'; my $try = abs_path('t/try.pl');
my $WIN = $^O eq 'MSWin32';

my @c = (
 [qw(echo)], [qw(echo a b)], [qw(echo -n a)], [qw(echo -e a\tb)], ['echo', '-e', 'a\x41\0101\101\cZ'], [qw(echo -- -n)], [qw(echo -neE a\tb)],
 [qw(echo -n -e -x q\tr)], [qw(echo -)], [qw(echo -nn x)], [qw(echo -enx y)], ['echo', '-e', 'x\\'], ['echo', '-e', '\x'], ['echo', '-e', '\xg1'],
 ['echo', '-e', '\e\f\v\q'], ['echo', 'a\tb'], [qw(echo --help x)],
 [['echo', '-n', 'x\ty'], { POSIXLY_CORRECT => 1 }], [['echo', '-e', 'x\ty'], { POSIXLY_CORRECT => 1 }], [['echo', 'a\cb', 'c'], { POSIXLY_CORRECT => 1 }],
 [qw(printf %s\n a b c)], ['printf', '%d %i\n', "'A", '0x1F'], [qw(printf %u\n -1)], ['printf', 'x\101\x42é\n'], [qw(printf %s-%s\n 1 2 3)],
 [qw(printf %5.2f|%-6d|%x|%o|%e|%g|%c\n 3.14159 42 255 8 12345.678 0.0001 hello)], [qw(printf %d\n abc)], [qw(printf %d\n 3x)],
 [qw(printf %d\n 99999999999999999999)], [qw(printf %d\n -99999999999999999999)], [qw(printf %z)], [qw(printf ab%z)], [qw(printf %)], [qw(printf)],
 [qw(printf %d\n)], [qw(printf %s|%c|%b|\n)], ['printf', '%b|', 'a\0101b', 'x\cy', 'z'], ['printf', '%b\n', '\101'], [qw(printf %q\n a)], ['printf', '%q %q %q\n', 'a b', "it's", ''],
 [qw(printf hello x y)], [qw(printf %%\n)], [qw(printf -- %s\n x)], ['printf', '%05d|%-5d|%+d|% d\n', 42, 42, 42, 42], [qw(printf %.3s|%10.3s|\n abcdef abcdef)],
 [qw(printf %*d|%-*d|%.*f\n 5 42 5 42 2 3.14159)], [qw(printf %#x|%#o|%#X\n 255 8 255)], [qw(printf %x\n 18446744073709551615)], [qw(printf %ld\n 5)],
 ['printf', 'a\cb'], ['printf', '\0101\n'], ['printf', '\x'], ['printf', '\q\n'], [qw(printf %c\n 65)], ['printf', '%d\n', "'ab"], ['printf', '%d\n', ' 12'],
 ['printf', '%d\n', '12 '], ['printf', '%d\n', ''], [qw(printf %f\n abc)], [qw(printf %f\n 1.5x)], [qw(printf %.0f\n 2.5)], [qw(printf %e\n inf)], [qw(printf %d\n 010)],
 [qw(printf %#o|%#.3o|%#5o\n 0 8 8)], [qw(printf %+f|%f\n 18446744073709551615 9223372036854775808)], [qw(printf %0s|%-0c|% 0G\n x y nan)],
 [qw(test)], [qw(test x)], [qw(test), ''], [qw(test ! x)], [qw(test -n x)], [qw(test -z x)], [qw(test 1 -eq 1)], [qw(test 1 -eq x)], [qw(test a = a)], [qw(test a != a)],
 [qw(test foo bar)], [qw(test foo bar baz)], [qw(test ! a = b)], ['test', '(', 'a', ')'], [qw(test a -a b)], ['test', 'a', '-o', ''], ['test', qw[( a = a ) -a ( b = c )]],
 [qw(test -f file)], [qw(test -d dir)], [qw(test -e nonexistent)], [qw(test -x exe)], [qw(test -x file)], [qw(test 01 -eq 1)], [qw(test 99999999999999999999 -gt 1)],
 [qw(test -1 -lt 0)], ['test', ' 5 ', '-eq', '5'], [qw(test 1 -eq)], [qw(test -f)], ['test', '(', 'a'], [qw(test a b c d e)], [qw(test ! ! x)], [qw(test -t 99)],
 [qw(test file -nt dir)], [qw(test dir -ot file)], [qw(test dir -ef dir/.)], [qw(test file -ef dir)], ['test', 'a', '<', 'b'], [qw(test -s file)], [qw(test -s empty)],
 [qw(test -h link)], [qw(test -L file)], [qw(test -d link)],
 [qw([ 1 = 1 ])], [qw([ 1 = 1)], [qw([ ])], [qw([ x ])], ['[', '-z', '', ']'],
 (map [split / /], 'test -l abc -eq 3', 'test -l abc = 3', 'test 3 -eq -l abc', 'test -l ab -lt -l abc', 'test x -a -l ab -eq 2',
   'test 3 = -l abc', 'test -l abc -eq -l', 'test -l', 'test -l -l -eq 2', 'test ! -l abc -eq 3', 'test ( -l abc -eq 3 )',
   '[ ( a ]', '[ ( a b ]', '[ a -a ]', '[ ! ]', '[ -f ]', '[ ( x -o ]', 'test ( x -o', '[ x -eq ]',
   '[ ( ( ( x ) ) ]', '[ a b ]', '[ ( ( = x ]', '[ ( ( ( ( ( x ]', 'test ( ( ( ( ( x'), ['[', '(', '(', '=', '', ']'], ['[', '(', '', ']'],
 ['printf', '%q\n', "a'b\n"], ['printf', '%q\n', "\x1b'\f"], ['printf', '%q|%q|%q\n', "\xc3\xa9", "\xff", '{a,b}'],
 # X37: \u and \U as coreutils (the escape where the locale cannot encode the character; a surrogate is an error)
 ['printf', '\u20AC|\U0001F600|\u00e9|\u0041|\u0024|\U0010FFFF|\U00110000\n'], ['printf', 'a\ud800b'], ['printf', 'a\U0000DFFFb'],
 ['printf', '%b|', 'x\u20ACy', '\u007F\u00A0'], ['printf', '%b|', 'a\uDFFFb', 'z'], ['printf', '%b|', 'a\u20A'], ['printf', '\u20A'],
);
# Where we differ from coreutils 9.4 on purpose (X21): its %q of a word with a ' and a character it escapes keeps a stale
# state of gnulib's quotearg when it starts over (fixed in gnulib since): an extra '' at the start, or, when the word
# starts with an escaped character, no $' before it, so the shell reads it back wrong (❰BUG❱).  Ours: gnulib's fixed rule.
my %KNOWN = map { my ($w, $q) = @$_; map +(key(['printf', '%q\n', $w], { LC_ALL => $_ }) => [0, "$q\n", '']), 'C', 'C.UTF-8' }
  ["a'b\n", q{'a'\''b'$'\n'}], ["\x1b'\f", q{''$'\033'\'''$'\f'}];
{ # generated (the same generator as when the module was written, with fewer cases)
  srand 42;
  my @flags = ('', '-', '0', '+', ' ', '#', '-0', '+ ');
  my @conv = qw(d i o u x X f e g E G c s b q);
  my @nums = ('0', '1', '-1', '42', '255', '3.5', '-2.25', '1e3', '0x10', '010', "'a", 'x', '12abc', '', ' 7', '18446744073709551615', '9223372036854775808', '-9223372036854775809', 'inf', '-inf', 'nan', '1.5e3', '0.000001');
  my @strs = ('', 'a', 'hello world', 'a\tb', 'x\101y', 'q\cz', '\0101', '\x41\x4', "it's", 'a"b', '-n', '%', '%%', 'é', "tab\there", 'back\\slash');
  for (1 .. 500) {
    my $nspec = 1 + int rand 3; my ($fmt, @args) = ('');
    for (1 .. $nspec) { my $cv = $conv[rand @conv]; my $w = rand() < 0.5 ? '' : int rand 12; my $p = rand() < 0.6 ? '' : '.' . int rand 8;
      $fmt .= (rand() < 0.3 ? 'x' : '') . '%' . $flags[rand @flags] . $w . $p . $cv . (rand() < 0.3 ? '|' : '') }
    $fmt .= '\n' if rand() < 0.7;
    my $na = int rand 5; push @args, (rand() < 0.5 ? $nums[rand @nums] : $strs[rand @strs]) for 1 .. $na;
    push @c, ['printf', $fmt, @args] }
  for (1 .. 150) { my @a = map { $strs[rand @strs] } 1 .. int rand 4; unshift @a, (qw(-n -e -E -ne -en -nE -x --))[rand 8] while rand() < 0.4;
    push @c, rand() < 0.2 ? [['echo', @a], { POSIXLY_CORRECT => 1 }] : ['echo', @a] }
  my @t = ('!', '(', ')', '-a', '-o', '-n', '-z', '-f', '-d', '=', '!=', '-eq', '-lt', '-gt', 'a', '', '1', '2', '-1', 'x', 'dir', 'file', '-q', ' 3 ');
  for (1 .. 350) { my @a = map { $t[rand @t] } 1 .. int rand 7; push @c, rand() < 0.3 ? ['[', @a, ']'] : ['test', @a] }
}

# Fixtures: dir (a directory, older than file), file (non-empty), empty, exe (executable), link (a symbolic link to dir).
my $dir = tempdir(CLEANUP => 1); chdir $dir or die "$dir: $!";
mkdir 'dir' or die; for (['file', "x\n"], ['empty', ''], ['exe', "#!/bin/sh\n"]) { open my $f, '>', $_->[0] or die; print $f $_->[1]; close $f }
chmod 0755, 'exe'; chmod 0644, 'file'; my $links = eval { symlink 'dir', 'link' } && -l 'link' && -d 'link';   # (Wine: made, but no link to a directory)
utime time - 1000, time - 1000, 'dir';
my %skip = (link => !$links, exe => $WIN, file => 0);   # (Windows: no execute bit; -x is the extension's)

sub esc { my $s = shift; $s =~ s/([\\\t\n]|[^\x20-\x7e])/$1 eq "\\" ? '\\\\' : sprintf '\\x%02x', ord $1/ge; $s }
sub unesc { my $s = shift; $s =~ s/\\(\\|x([0-9a-f]{2}))/defined $2 ? chr hex $2 : '\\'/ge; $s }
sub key { my ($argv, $env) = @_; join "\t", map esc($_), (map "$_=$env->{$_}", sort keys %$env), '--', @$argv }
my @runs = map { my ($argv, $env) = ref $_->[0] ? @$_ : ($_, {}); my $c = $_;
  map +[$argv, { %$env, LC_ALL => $_ }], 'C', 'C.UTF-8' } @c;

# EC1 (the user, 2026-11-09): echo as dash's and bash's builtins (PROC_SHELLSPAWN_ECHO=dash, bash; OPT's echo), against
# what dash 0.5.12 and bash 5.2.21 (bash --posix) did with the same words: t/echo-shells.txt, recorded by
# 'perl t/programs.t --record-shells' where those are installed (Ubuntu 24.04).  The echo cases above (some with
# POSIXLY_CORRECT, which changes neither builtin), and these for the escapes where the two differ; each in both locales.
my @runs_sh = do {
  my @e = ((grep { (ref $_->[0] ? $_->[0][0] : $_->[0]) eq 'echo' } @c),
    ['echo', '-e', '\1|\101|\0101|\01011|\08|\E|\x41|\x|\xg'], ['echo', '\1|\101|\0101|\E|\e|\x41'],
    ['echo', '-e', '€|\u41|\u|\uG|ሴ5|\U1F600|\Ud800|\uDFFF|\u80|￿|\U10FFFF|\U110000|\U7FFFFFFF|\U80000000|\U123456789|\u0x'],
    [qw(echo -e -n -E a\tb)], [qw(echo -n -e a\tb)], [qw(echo -n -n a)], [qw(echo -- a)], [qw(echo -e -x a\tb)], ['echo', '-e', 'a\cb', 'c'], ['echo', 'a\cb', 'c'],
    [['echo', '-e', 'a\tb'], { POSIXLY_CORRECT => 1 }], [['echo', 'a\tb'], { POSIXLY_CORRECT => 1 }], [['echo', '-n', 'a\tb'], { POSIXLY_CORRECT => 1 }]);
  map { my ($argv, $env) = ref $_->[0] ? @$_ : ($_, {});
        map { my $st = $_; map +[$argv, { %$env, PROC_SHELLSPAWN_ECHO => $st, LC_ALL => $_ }], 'C', 'C.UTF-8' } 'dash', 'bash' } @e };

if ($record) {   # the real programs, with the same argv[0]
  require IPC::Open3; require Symbol;
  my %PROG = map +($_ => "/usr/bin/$_"), qw(echo printf test [);
  `$PROG{printf} --version` =~ /GNU coreutils\) 9\.4\b/ or die "not GNU coreutils 9.4: $PROG{printf}\n";
  open my $o, '>', $data or die "$data: $!";
  print $o "# t/programs.txt: GNU coreutils 9.4's results, written by perl t/programs.t --record; one per line: ENV... -- ARGV... TAB\n",
           "# then the results STATUS, STDOUT, STDERR on the next line; escaped: \\\\ and \\xHH\n";
  for (@runs) {
    my ($argv, $env) = @$_; local %ENV = (PATH => '/usr/bin:/bin', %$env);
    my $err = Symbol::gensym(); my $pid = IPC::Open3::open3(my $in, my $out, $err, $^X, '-e', q{exec {shift} @ARGV; die "exec: $!"}, $PROG{$argv->[0]}, @$argv);
    close $in; my $so = do { local $/; <$out> } // ''; my $se = do { local $/; <$err> } // ''; waitpid $pid, 0;
    print $o key($argv, $env), "\n", join("\t", $? >> 8, esc($so), esc($se)), "\n" }
  close $o; print "recorded ", scalar @runs, " runs in $data\n"; exit }

if ($record_sh) {   # the shells' builtins: dash -c 'echo "$@"', bash --posix -c 'echo "$@"'
  require IPC::Open3; require Symbol;
  `bash --version` =~ /version 5\.2\.21\b/ or die "not bash 5.2.21\n";
  open my $o, '>', $data_sh or die "$data_sh: $!";
  print $o "# t/echo-shells.txt: the echo builtins of dash 0.5.12 and bash 5.2.21 (bash --posix), written by perl t/programs.t\n",
           "# --record-shells; as t/programs.txt (PROC_SHELLSPAWN_ECHO in the key says whose)\n";
  for (@runs_sh) {
    my ($argv, $env) = @$_; my %e = %$env; my $st = delete $e{PROC_SHELLSPAWN_ECHO}; local %ENV = (PATH => '/usr/bin:/bin', %e);
    my @sh = $st eq 'dash' ? ('dash', '-c', 'echo "$@"', 'sh') : ('bash', '--posix', '-c', 'echo "$@"', 'bash');
    my $err = Symbol::gensym(); my $pid = IPC::Open3::open3(my $in, my $out, $err, @sh, @$argv[1 .. $#$argv]);
    close $in; my $so = do { local $/; <$out> } // ''; my $se = do { local $/; <$err> } // ''; waitpid $pid, 0;
    print $o key($argv, $env), "\n", join("\t", $? >> 8, esc($so), esc($se)), "\n" }
  close $o; print "recorded ", scalar @runs_sh, " runs in $data_sh\n"; exit }

open my $in, '<', $data or die "$data: $!";
my %want; while (my $k = <$in>) { next if $k =~ /^#/; chomp $k; chomp(my $r = <$in>); $want{$k} = [map unesc($_), split /\t/, $r, -1] }
my (@bad, $n);
for (@runs) {
  my ($argv, $env) = @$_;
  next if grep defined $skip{$_} && $skip{$_}, @$argv;
  my $w = $KNOWN{key($argv, $env)} // $want{key($argv, $env)} or do { push @bad, "not recorded: " . key($argv, $env); next };
  my ($so, $se, $st) = Proc::ShellSpawn::Programs->can($argv->[0] eq '[' ? 'test' : $argv->[0])->($argv, $env);
  $n++;
  push @bad, key($argv, $env) . "\n  want: " . esc(join '|', @$w) . "\n  got:  " . esc(join '|', $st, $so, $se)
    unless $st == $w->[0] && $so eq $w->[1] && $se eq $w->[2] }
ok !@bad, "$n runs as GNU coreutils 9.4 (" . keys(%KNOWN) . " as its fixed %q)" or diag join "\n", @bad[0 .. ($#bad < 30 ? $#bad : 29)];

{ open my $in, '<', $data_sh or die "$data_sh: $!";
  my %w; while (my $k = <$in>) { next if $k =~ /^#/; chomp $k; chomp(my $r = <$in>); $w{$k} = [map unesc($_), split /\t/, $r, -1] }
  my (@bad, $n);
  for (@runs_sh) {
    my ($argv, $env) = @$_;
    my $w = $w{key($argv, $env)} or do { push @bad, "not recorded: " . key($argv, $env); next };
    my ($so, $se, $st) = Proc::ShellSpawn::Programs::echo($argv, $env, { echo => $env->{PROC_SHELLSPAWN_ECHO} }); $n++;
    push @bad, key($argv, $env) . "\n  want: " . esc(join '|', @$w) . "\n  got:  " . esc(join '|', $st, $so, $se)
      unless $st == $w->[0] && $so eq $w->[1] && $se eq $w->[2] }
  ok !@bad, "$n runs of echo as dash's and bash's builtins (EC1)" or diag join "\n", @bad[0 .. ($#bad < 30 ? $#bad : 29)] }

# The order of output and messages (glibc's error() flushes stdout first), as the shell layer writes them
my @o = Proc::ShellSpawn::Programs::printf(['printf', 'a%db%dc', 1, 'x', 2, 'y'], { LC_ALL => 'C' });
is_deeply [grep length $_->[1], @{$o[3]}], [[1, 'a1b'], [2, "printf: 'x': expected a numeric value\n"], [1, '0ca2b'],
  [2, "printf: 'y': expected a numeric value\n"], [1, '0c']], 'printf: output and messages in order';

# test's file names are relative to OPT's cwd, not Perl's
chdir 'dir' or die;
is((Proc::ShellSpawn::Programs::test(['test', '-f', 'file'], {}, { cwd => $dir }))[2], 0, 'test -f: relative to cwd');
chdir $dir;

# pwd (post-0.10, in-process by IP1): as coreutils 9.4 (checked against it on 352 runs: PWD valid, invalid, unset;
# options, operands, POSIXLY_CORRECT); here the main cases, in the fixtures' directory
{ my $P = \&Proc::ShellSpawn::Programs::pwd; require Cwd; my $phys = Cwd::abs_path($dir);
  is_deeply [$P->(['pwd', '-x'], {})], ['', "pwd: invalid option -- 'x'\nTry 'pwd --help' for more information.\n", 1], 'pwd -x';
  is_deeply [$P->(['pwd', '--log=x'], {})], ['', "pwd: option '--logical' doesn't allow an argument\nTry 'pwd --help' for more information.\n", 1], 'pwd --log=x';
  is_deeply [$P->(['pwd', '-L'], { PWD => "$dir/dir/.." }, { cwd => $dir })], ["$phys\n", '', 0], 'pwd -L: a PWD with .. is not used';
  is_deeply [$P->(['pwd', '-L', 'x'], { PWD => $dir }, { cwd => $dir })], ["$dir\n", "pwd: ignoring non-option arguments\n", 0], 'pwd -L: PWD, and the operand ignored';
  SKIP: { skip 'no symbolic links here', 2 unless $links;
    is_deeply [$P->(['pwd', '-L'], { PWD => "$dir/link" }, { cwd => "$dir/link" })], ["$dir/link\n", '', 0], 'pwd -L through a link';
    is_deeply [$P->(['pwd', '-LP'], { PWD => "$dir/link" }, { cwd => "$dir/link" })], [Cwd::abs_path("$dir/dir") . "\n", '', 0], 'pwd -LP: the last counts' } }

# PROC_SHELLSPAWN_ECHO reaches the shell layer's in-process echo; POSIXLY_CORRECT changes only coreutils' (EC1).  The
# string goes to t/try.pl in a file (TRY_FILE), as t/portable.t does, so that this runs on Windows too.
{ my $try_sh = sub { my $f = "$dir/try-cmd"; open my $h, '>', $f or die "$f: $!"; binmode $h; print $h shift; close $h;
                     local $ENV{TRY_FILE} = $f; scalar `"$^X" "$try" 2>&1` };
  my %want = (coreutils => ["a\tb c\td\n", "-e a\tb c\td\n"], dash => ["-e a\tb c\td\n", "-e a\tb c\td\n"], bash => ["a\tb c\td\n", "a\tb c\td\n"]);
  for my $v (sort keys %want) { for my $p (0, 1) {   # (the subset refuses POSIXLY_CORRECT=1 as an assignment: the environment's)
    local $ENV{PROC_SHELLSPAWN_ECHO} = $v; local $ENV{POSIXLY_CORRECT} = 1 if $p; delete local $ENV{POSIXLY_CORRECT} unless $p;
    is $try_sh->('echo -e "a\tb" "c\td"'), $want{$v}[$p], "PROC_SHELLSPAWN_ECHO=$v" . ($p ? ', POSIXLY_CORRECT=1' : '') . ": the shell layer's echo" } }
  local $ENV{PROC_SHELLSPAWN_ECHO} = 'zsh';
  like $try_sh->('echo x'), qr/^PROC_SHELLSPAWN_ECHO: 'zsh' is none of coreutils, dash, bash$/m, 'PROC_SHELLSPAWN_ECHO: an unknown value dies' }

# X44: cd into a directory without search permission fails, as both shells (root may enter any; Windows: no such bit)
SKIP: { skip 'root may enter any directory, Windows has no search bit', 1 if $> == 0 || $WIN;
  mkdir "$dir/x44" or die; chmod 0, "$dir/x44";
  my $f = "$dir/x44-cmd"; open my $h, '>', $f or die; print $h 'cd x44; echo "st=$?"'; close $h;
  local $ENV{TRY_FILE} = $f; is scalar(`"$^X" "$try" 2>&1`), "sh: cd: can't cd to x44\nst=2\n", 'cd into a directory not searchable (X44)';
  chmod 0755, "$dir/x44" }

# X48: return outside a function is an error, as bash --posix (rule E): where its status is tested (&&, ||, !, if, while)
# status 2 and the shell goes on; elsewhere the shell ends, status 2 (found by large-subset-difffuzz.pl)
{ my $m = "sh: return: can only `return' from a function or sourced script\n";
  for (['return || echo o; echo n', "${m}o\nn\n", 0], ['if return; then :; fi; echo n', "${m}n\n", 0],
       ['return 3 && echo a; echo "n $?"', "${m}n 2\n", 0], ['! return; echo "n $?"', "${m}n 0\n", 0],
       ['return; echo n', $m, 2], ['echo a && return; echo n', "a\n$m", 2]) {
    my ($s, $out, $st) = @$_; my $f = "$dir/x48-cmd"; open my $h, '>', $f or die; print $h $s; close $h;
    local $ENV{TRY_FILE} = $f; my $got = `"$^X" "$try" 2>&1`;
    is "$got|" . ($? >> 8), "$out|$st", "return outside a function, as bash (X48): $s" } }

# X49: a signal ignored on entry cannot be trapped or reset, and kill ... $$ with it does nothing (POSIX; both shells)
SKIP: { skip 'no SIGINT to ignore on Windows', 2 if $WIN;
  for (['trap "echo int" INT; kill -INT $$; echo after', "after\n"], ['kill -INT $$; echo after', "after\n"]) {
    my ($s, $out) = @$_; my $f = "$dir/x49-cmd"; open my $h, '>', $f or die; print $h $s; close $h;
    local $ENV{TRY_FILE} = $f; open my $p, '-|', $^X, '-e', '$SIG{INT} = "IGNORE"; exec $^X, @ARGV', $try or die;
    my $got = do { local $/; <$p> } // ''; close $p;
    is $got, $out, "SIGINT ignored on entry (X49): $s" } }

# X50: an expansion error inside a here-document (set -u, ${x:?}, arithmetic) fails that redirection, as dash: the
# command does not run, status 2, the shell goes on; the message and a $( ) in it go through the redirections so far;
# with a special builtin (:) the shell ends (found by large-subset-difffuzz.pl)
{ my $m = "sh: x: parameter not set\n";
  for (["set -u; cat <<E\n\$x\nE\necho after:\$?", "${m}after:2\n", 0], ["set -u; f() { echo ran; }; f <<E\n\$x\nE\necho after:\$?", "${m}after:2\n", 0],
       ["set -u; cat 2>/dev/null <<E\n\$x\nE\necho after:\$?", "after:2\n", 0], ["cat 2>/dev/null <<E\n\$((1/0))\nE\necho after:\$?", "after:2\n", 0],
       ["cat <<E 2>/dev/null\n\${x:?boom}\nE\necho after:\$?", "sh: x: boom\nafter:2\n", 0], ["set -u; : <<E\n\$x\nE\necho after", $m, 2],
       ["x=1; cat <<E\na \$x\nE\necho after:\$?", "a 1\nafter:0\n", 0]) {
    my ($s, $out, $st) = @$_; my $f = "$dir/x50-cmd"; open my $h, '>', $f or die; print $h $s; close $h;
    local $ENV{TRY_FILE} = $f; my $got = `"$^X" "$try" 2>&1`;
    is "$got|" . ($? >> 8), "$out|$st", "expansion error in a here-document, as dash (X50): " . ($s =~ s/\n/|/gr) } }

# X51: a trapped signal's action runs after the foreground command, also when the command runs in this process (a
# pipeline of builtins); a trap set in a subshell does not replace the main shell's (both shells: another process)
for (['trap "echo int" INT; kill -INT $$ | while getopts ab: o -a -b v; do echo $o; done', "a\nb\nint\n"],
     ['trap "echo int" INT; kill -INT $$ | trap "echo int" INT; kill -INT $$ | true; echo end', "int\nint\nend\n"],
     ['trap "echo main" INT; (trap "echo sub" INT; kill -INT $$; echo in-sub); echo after', "in-sub\nmain\nafter\n"],
     ['trap "echo int" INT; x=$(kill -INT $$); echo after', "int\nafter\n"], ['trap "echo int" INT; { kill -INT $$; echo grp; }', "int\ngrp\n"]) {
  my ($s, $out) = @$_; my $f = "$dir/x51-cmd"; open my $h, '>', $f or die; print $h $s; close $h;
  local $ENV{TRY_FILE} = $f; is scalar(`"$^X" "$try" 2>&1`), $out, "a trap after the foreground command (X51): $s" }

# X52: a word from an unquoted expansion whose only pattern characters are escaped by a backslash is not matched
# against files (x\* stays x\*, as both shells), with a file x* there (found by the split-and-glob probe, X27)
{ mkdir "$dir/x52"; open my $t, '>', "$dir/x52/x*" or die; close $t;
  for (['x="x\\*"; echo $x', "x\\*\n"], ['x="[x]\\*"; echo $x', "x*\n"], ['x="\\?"; echo $x', "\\?\n"], ['echo x\\*', "x*\n"]) {
    my ($s, $out) = @$_; my $f = "$dir/x52-cmd"; open my $h, '>', $f or die; print $h "cd x52; $s"; close $h;
    local $ENV{TRY_FILE} = $f; is scalar(`"$^X" "$try" 2>&1`), $out, "an escaped pattern character from an expansion (X52): $s" } }

# X53: a form of command the parser refuses, made only by expansions at run time: outside the subset (A4), status 248
{ my $m = 'Proc::ShellSubset::Large: ';
  for (['x=-n; command $x; echo no', "${m}'command -n' is not supported\n", 248], ['x="-v ls cat"; command $x', "${m}'command -v' with 2 names is not supported\n", 248],
       ['x="-p -x"; command $x', "${m}'command -p -x' is not supported\n", 248], ['x="-p true"; command $x; echo "st=$?"', "st=0\n", 0]) {
    my ($s, $out, $st) = @$_; my $f = "$dir/x53-cmd"; open my $h, '>', $f or die; print $h $s; close $h;
    local $ENV{TRY_FILE} = $f; my $got = `"$^X" "$try" 2>&1`;
    is "$got|" . ($? >> 8), "$out|$st", "command's form from expansions (X53): $s" } }

# X54: cd with more operands from an expansion at run time: "too many arguments", status 1, as with them in the text (as
# bash, rule E); dash takes the first
{ mkdir "$dir/x54"; mkdir "$dir/x54/d";
  for (['x="d e"; cd $x; echo "st=$?"', "sh: cd: too many arguments\nst=1\n"], ['cd d e; echo "st=$?"', "sh: cd: too many arguments\nst=1\n"],
       ['cd $(echo d e) && pwd', "sh: cd: too many arguments\n"], ['x=d; cd $x && echo in', "in\n"], ['x=-n; cd $x; echo "st=$?"', "sh: cd: bad argument\nst=2\n"]) {
    my ($s, $out) = @$_; my $f = "$dir/x54-cmd"; open my $h, '>', $f or die; print $h "cd x54; $s"; close $h;
    local $ENV{TRY_FILE} = $f; is scalar(`"$^X" "$try" 2>&1`), $out, "cd with more operands from an expansion (X54): $s" } }

# The shell layer: the same strings with the programs (PROC_SHELLSPAWN_INPROC=none) and with these (all, the default), where
# the programs exist
SKIP: {
  skip 'no coreutils programs to compare with', 1 if $WIN or !-x '/usr/bin/printf' or !-x '/usr/bin/test';
  my @s = ('echo a b; printf "%s|%d\n" x 3z; test -d dir && echo dir; [ 1 -lt 2 ]; echo $?',
           'cd dir; [ -d ../dir ] && echo rel-ok; test -f file; echo $?', 'printf "%s\n" 1 2 3 | head -1', 'echo x >&-; echo $?',
           'printf "a%db%dc" 1 x 2 y 2>&1 | od -c', '(printf "%01000000d" 0; echo " st $?" >&2) | head -c 3',
           'echo x | (read y; [ "$y" = x ] && echo same)', 'true; echo $?; false; echo $?; test; echo $?', 'command -v printf >/dev/null; echo $?');
  my @bad;
  for my $s (@s) {
    local $ENV{CMD} = $s; my %r;
    for my $v ('none', 'all') {
      local $ENV{PROC_SHELLSPAWN_INPROC} = $v;
      $r{$v} = `$^X $try "\$CMD" 2>&1; echo "<\$?>"` }
    push @bad, "$s\n  programs:   $r{none}\n  in-process: $r{all}" if $r{none} ne $r{all} }
  ok !@bad, scalar(@s) . ' shell strings: the same with the programs and in-process' or diag join "\n", @bad }

# sh as Perl with Proc::ShellSpawn (SH1, post-0.10): the same strings with the program sh (PROC_SHELLSPAWN_SH=program)
# and as Perl (perl); dash's line number in its messages ("NAME: 1: ...") left out, as the shell layer has none (P2)
SKIP: {
  skip 'no /bin/sh to compare with (Windows: t/portable.t)', 2 if $WIN or !-x '/bin/sh';
  my @s = (q{sh -c 'echo "$0|$1|$#"; exit 3' nm a b; echo st=$?}, q{echo 'echo from-stdin $1' | sh -s x},
           q{sh -ec 'false; echo not-here'; echo st=$?}, q{sh -c 'nosuch-cmd-x' myname; echo st=$?},
           q{printf 'echo file $1\n' > f.sh; sh f.sh z; rm f.sh}, q{sh -c "sh -c 'echo nested'"},
           q{sh -c 'kill -TERM $$'; echo st=$?}, q{sh -c 'echo $((1+2)) "$@"' x y z},
           q{sh -u -c 'echo $nosuchvar; echo after'; echo st=$?}, q{sh -c 'cd dir && pwd' | sed 's,.*/,,'; pwd | sed 's,.*/,,'});
  my @bad;
  for my $s (@s) {
    local $ENV{CMD} = $s; my %r;
    for my $v ('program', 'perl') {
      local $ENV{PROC_SHELLSPAWN_SH} = $v;
      ($r{$v} = `$^X $try "\$CMD" 2>&1; echo "<\$?>"`) =~ s/^(\S+: )[0-9]+: /$1/mg }
    push @bad, "$s\n  program: $r{program}\n  perl:    $r{perl}" if $r{program} ne $r{perl} }
  ok !@bad, scalar(@s) . ' strings with sh: the same with the program and as Perl (SH1)' or diag join "\n", @bad;
  local $ENV{PROC_SHELLSPAWN_SH} = 'zsh'; local $ENV{CMD} = 'true';
  like scalar(`$^X $try "\$CMD" 2>&1`), qr/^PROC_SHELLSPAWN_SH: 'zsh' is none of auto, perl, program$/m, 'PROC_SHELLSPAWN_SH: an unknown value dies' }
done_testing;
