#!/usr/bin/perl
# large-subset-valueprobe.pl (X27, step 3; post-0.11, 2026-11-12): probes the two assumptions of step 3
# (large-subset-environment.md, section 12) with odd values, in dash, bash --posix and ours (t/try.pl):
#   passthrough  a value from the environment that only passes through the shell reaches the program unchanged: values
#                in the environment (X) or in a file read by $( ) (./v), through quoted words, assignments, ${X:-d},
#                here-documents, export, and a program's output going on; /usr/bin/printf, /bin/cat and the like by
#                path, so the three run the same programs;
#   splitglob    an unquoted value is split and matched against files alike: values with blanks, IFS characters,
#                pattern characters, backslashes, //, a leading dot; files a, ab, 'b c', .hid, d/e, x*, é, -n, B there;
#                into a program's words with the default IFS and with IFS=:, through $( ), in a for list, under set -f.
# Standard output and the status are compared (messages count nowhere: standard error is dropped), byte for byte.
# Prints every form and value where the three differ.  Usage (from the distribution's directory, after make; also:
# make probe-values): perl doc/large-subset/tools/large-subset-valueprobe.pl
# Known (2026-11-12): passthrough, none; splitglob, three, each a known difference: [^a]* (dash takes ^ literally;
# not legalized: TODO A13), .* (dash also gives . and ..; rule E, G2), d*//e (bash collapses //; ours as dash, A5).
use strict; use warnings; use Cwd 'abs_path'; use File::Temp 'tempdir';
-e 't/try.pl' && -d 'blib' or die "run from the distribution's directory, after make\n";
my $TOP = abs_path('.'); my $TRY = "$TOP/t/try.pl";
my %SH = (dash => ['dash', '-c'], bash => ['bash', '--posix', '-c'], ours => [$^X, "-I$TOP/blib/lib", "-I$TOP/blib/arch", $TRY]);
my $base = tempdir('valueprobe.XXXXXX', TMPDIR => 1, CLEANUP => 1);
sub run3 {   # the three runs of TEXT; X in the environment if defined; ./v holds $file if defined; @files made first
  my ($text, $x, $file, @files) = @_; my %out;
  for my $sh (qw(dash bash ours)) { my $d = "$base/$sh"; system 'rm', '-rf', $d; mkdir $d or die; mkdir "$d/d";
    for (@files) { open my $h, '>', "$d/$_" or die "$_: $!"; close $h }
    if (defined $file) { open my $h, '>:raw', "$d/v" or die; print $h $file; close $h }
    my $pid = open my $p, '-|' // die "fork: $!";
    if (!$pid) { chdir $d; open STDERR, '>', '/dev/null'; $ENV{LC_ALL} = 'C'; if (defined $x) { $ENV{X} = $x } else { delete $ENV{X} }
      exec @{$SH{$sh}}, $text; exit 127 }
    binmode $p; local $/; my $o = <$p> // ''; close $p; $out{$sh} = $o . "|st=" . ($? >> 8) }
  \%out }
sub show { my $x = shift; $x = substr($x, 0, 30) . '...' . substr($x, -20) . ' (' . length($x) . ')' if length $x > 60;
  $x =~ s/([^\x20-\x7e])/sprintf '\\x%02x', ord $1/ge; $x }
my ($n, $bad) = (0, 0);
sub report { my ($form, $vn, $out) = @_; $n++; return if $out->{dash} eq $out->{bash} && $out->{bash} eq $out->{ours};
  $bad++; printf "  %-22s %-14s dash %s | bash %s | ours %s\n", $form, $vn, map show($out->{$_}), qw(dash bash ours) }

print "passthrough:\n";
my %V = (empty => '', space => ' ', two => "a  b", star => '*', dash_n => '-n', dashdash => '--', bslash => 'a\\b\\n',
  nl2 => "x\n\n", lead_nl => "\nx", cr => "a\r", tab => "\ta\t", ff => "\xff\xfe", utf8 => "\xc3\xa9t\xc3\xa9",
  dollar => '$x `id` $(id)', pct => '%s%d%%', quote => q{'"}, long => 'y' x 100_000, ifs => ':a:b:', glob => '[a-z]*?',
  tilde => '~', ctrl => "\x01\x1b[0m", nul => "a\0b", nulend => "a\0", only_nl => "\n\n");
my @P = (   # [form, text, env (X) or file (./v)]
  ['env quoted word',      '/usr/bin/printf "[%s]" "$X"', 'env'],
  ['env assigned, quoted', 'y=$X; /usr/bin/printf "[%s]" "$y"', 'env'],
  ['env ${X:-d} quoted',   '/usr/bin/printf "[%s]" "${X:-d}"', 'env'],
  ['env in a here-doc',    "/bin/cat <<E\n[\$X]\nE", 'env'],
  ['env exported',         'export X; /usr/bin/env | /bin/grep -a "^X=" | /usr/bin/od -An -c', 'env'],
  ['$( ) quoted word',     '/usr/bin/printf "[%s]" "$(/bin/cat v)"', 'file'],
  ['$( ) assigned',        'y=$(/bin/cat v); /usr/bin/printf "[%s]" "$y"', 'file'],
  ['$( ) in a here-doc',   "/bin/cat <<E\n[\$(/bin/cat v)]\nE", 'file'],
  ['output going on',      '/bin/cat v', 'file'],
  ['through a pipe',       '/bin/cat v | /bin/cat', 'file'],
  ['$( ) then export',     'y=$(/bin/cat v); export y; /usr/bin/env | /bin/grep -a "^y=" | /usr/bin/od -An -c', 'file']);
for my $f (@P) { my ($form, $text, $how) = @$f;
  for my $vn (sort keys %V) { my $v = $V{$vn}; next if $how eq 'env' && $v =~ /\0/;   # (no NUL in the environment)
    report($form, $vn, run3($text, $how eq 'env' ? ($v, undef) : (undef, $v))) } }

print "splitglob:\n";
my @FILES = ('a', 'ab', 'b c', '.hid', 'd/e', 'x*', 'é', '-n', 'B');
my @SV = ('', ' ', 'a  b', " \ta\n b ", '*', '.*', '*/', '*/*', 'a*', '?', '[ab]', '[!a]*', '[^a]*', '[a-z]*', '[[:upper:]]', '\*',
  'x\*', 'a\b', '[', '[]a]', ']', '*[', 'd/*', '/d', '~', '-n', '--', 'a,b', '{a,b}', 'x*', 'é*', '[é]', ':a:b:', 'a::b', "a\nb",
  '**', '.', '..', 'D*', '[.]hid', '*hid', 'd//*', 'd*//e', './/d', '//');
my @SF = (['default IFS', '/usr/bin/printf "[%s]" $X; echo'], ['IFS=:', 'IFS=:; /usr/bin/printf "[%s]" $X; echo'],
  ['$( )', '/usr/bin/printf "[%s]" $(/usr/bin/printf "%s" "$X"); echo'], ['for list', 'for i in $X; do /usr/bin/printf "[%s]" "$i"; done; echo'],
  ['set -f', 'set -f; /usr/bin/printf "[%s]" $X; echo']);
for my $f (@SF) { my ($form, $text) = @$f; report($form, "'$_'", run3($text, $_, undef, @FILES)) for @SV }
printf "%d runs of the three; %d with a difference\n", $n, $bad;
