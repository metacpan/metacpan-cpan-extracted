# Proc::ShellSpawn::Programs (echo, printf, test, [ inside the Perl process) against what GNU coreutils 9.4 did with the same
# words, in the C and the C.UTF-8 locale: t/programs.txt, recorded by 'perl t/programs.t --record' where coreutils 9.4 is
# installed (Ubuntu 24.04).  The cases: written by hand, and generated with a fixed seed (a third of those checked when the
# module was written: 12266 runs, differing only where X21 says).  File tests use fixtures in a temporary directory.
use strict; use warnings; no warnings "qw";   # (printf formats with # in qw lists)
use Test::More; use File::Temp 'tempdir'; use Cwd 'abs_path';
use lib 'lib'; use Proc::ShellSpawn::Programs;
my $record = @ARGV && $ARGV[0] eq '--record';
my $data = abs_path('t') . '/programs.txt'; my $try = abs_path('t/try.pl');
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

# The order of output and messages (glibc's error() flushes stdout first), as the shell layer writes them
my @o = Proc::ShellSpawn::Programs::printf(['printf', 'a%db%dc', 1, 'x', 2, 'y'], { LC_ALL => 'C' });
is_deeply [grep length $_->[1], @{$o[3]}], [[1, 'a1b'], [2, "printf: 'x': expected a numeric value\n"], [1, '0ca2b'],
  [2, "printf: 'y': expected a numeric value\n"], [1, '0c']], 'printf: output and messages in order';

# test's file names are relative to OPT's cwd, not Perl's
chdir 'dir' or die;
is((Proc::ShellSpawn::Programs::test(['test', '-f', 'file'], {}, { cwd => $dir }))[2], 0, 'test -f: relative to cwd');
chdir $dir;

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
done_testing;
