#!/usr/bin/perl
# The recorder of doc/large-subset/tools/large-subset-runcompare.pl (the /bin/sh script it writes to BASE/rec), alone:
# what a sample feeds a stand-in (a pipe, a file given by <, a here-document) is read to the end or to 64 KB and logged
# with the call as \036 BYTES SHA256 (IN1, post-0.12); the run's own standard input is not read, nor the input of
# a program that never reads it (A24 (b)).  Linux only (the recorder is for the corpus runs there); no root needed.
use strict; use warnings; use Test::More; use File::Temp 'tempdir'; use Digest::SHA 'sha256_hex';
plan skip_all => 'Linux only' unless $^O eq 'linux';
-x $_ or plan skip_all => "no $_" for qw(/bin/sh /usr/bin/head /usr/bin/wc /usr/bin/sha256sum /usr/bin/stat /usr/bin/rm /usr/bin/yes);
my $src = do { open my $in, '<', 'doc/large-subset/tools/large-subset-runcompare.pl' or plan skip_all => "the runner: $!"; local $/; <$in> };
my ($rec) = $src =~ /<<'SH';[^\n]*\n(.*?)^SH\n/ms or BAIL_OUT('no recorder in the runner');
my $d = tempdir(CLEANUP => 1); my $W = "$d/w"; mkdir $W; mkdir "$d/bin";
{ open my $o, '>', "$d/rec" or die; print $o $rec; close $o; chmod 0755, "$d/rec" } symlink "$d/rec", "$d/bin/prog" or die;
mkdir "$d/real"; symlink '/usr/bin/head', "$d/real/head"; symlink "$d/rec", "$d/bin/head";   # head: as a program of %REAL
sub run { my ($text, $stdin) = @_; unlink "$W/log", "$W/stdin";
  if (defined $stdin) { open my $o, '>', "$W/stdin" or die; print $o $stdin; close $o }
  local %ENV = (PATH => "$d/bin:/usr/bin:/bin", RECLOG => "$W/log", REALDIR => "$d/real", REALNAMES => 'head', LC_ALL => 'C');
  my $out = `/bin/sh -c '$text' < @{[defined $stdin ? "$W/stdin" : '/dev/null']}`;
  my $log = do { open my $i, '<', "$W/log" or return ('', $out); local $/; <$i> }; $log =~ tr/\037\036/ </; ($log, $out) }
my $h = sub { sha256_hex($_[0]) };
is((run('printf abc | prog x'))[0], "prog x<3 " . $h->('abc') . "\n", 'a pipe: read, its size and SHA-256 logged');
is((run("prog <<EOF\nline\nEOF"))[0], "prog<5 " . $h->("line\n") . "\n", 'a here-document');
is((run('prog < /dev/zero'))[0], "prog<65536+ " . $h->("\0" x 65536) . "\n", 'stopped at the cap: 65536+');
is((run('yes | prog; echo $?'))[1], "0\n", 'yes | prog ends (yes stops when the stand-in has read its 64 KB)');
is((run('prog'))[0], "prog\n", 'the run\'s own /dev/null: not read, nothing logged');
my @r = run('prog; read x; echo "$x"', "first\nsecond\n");
is_deeply(\@r, ["prog\n", "first\n"], 'the run\'s own input (a setup\'s file): not read, a later read gets it');
is((run('prog < /dev/stdin; read x; echo "$x"', "first\n"))[1], "first\n", '< /dev/stdin is the run\'s own input too');
is((run('prog <&-'))[0], "prog<closed\n", 'no descriptor 0: closed');
is((run('prog < .'))[0], "prog<unreadable\n", 'a directory: unreadable');
symlink "$d/rec", "$d/bin/$_" or die for qw(mv rm);   # A24 (b): programs that never read their input
is((run('printf "a\nb\n" | while read f; do mv "$f" out; done'))[0], "mv a out\nmv b out\n", 'mv never reads: the loop keeps its input');
is((run('printf abc | rm -f x'))[0], "rm -f x\n", 'rm: not read, nothing logged of it');
is((run('printf y | rm -i x'))[0], "rm -i x<1 " . $h->('y') . "\n", 'rm -i asks: read');
is((run('printf y | mv --interactive a b'))[0], "mv --interactive a b<1 " . $h->('y') . "\n", 'mv --interactive: read');
is((run('printf y | mv -- -i b'))[0], "mv -- -i b\n", 'after --, -i is a name');
symlink "$d/rec", "$d/bin/zcat" or die;   # zcat reads its input only when it names no file
is((run('printf abc | zcat f.gz'))[0], "zcat f.gz\n", 'zcat with a file: not read');
is((run('printf abc | zcat'))[0], "zcat<3 " . $h->('abc') . "\n", 'zcat alone: read');
is((run('printf abc | zcat -f'))[0], "zcat -f<3 " . $h->('abc') . "\n", 'zcat with options only: read');
is((run('printf abc | zcat a.gz - b.gz'))[0], "zcat a.gz - b.gz<3 " . $h->('abc') . "\n", 'zcat naming -: read');
is((run('printf abc | zcat -- -f'))[0], "zcat -- -f\n", 'zcat -- -f: a file named -f, not read');
is((run('printf abc | head -c 2'))[0], "head -c 2\n", '%REAL: logged as before, its input left to the real program');
is((run('printf abc | head -c 2'))[1], "ab", '... which reads it');
done_testing;
