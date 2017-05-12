use strict;
use warnings;
use Test::More;
use Path::Extended;
use File::Path;
use File::Temp qw/tempdir/;

my $tmpdir = tempdir();

my $file = file("$tmpdir/grep.txt");
$file->save("foo\nbar\nbaz\n");

subtest 'grep_with_string' => sub {
  my @lines = $file->grep('bar');
  ok @lines == 1 && $lines[0] eq "bar\n";
};

subtest 'grep_with_regex' => sub {
  my @lines = $file->grep(qr/^b/);
  ok @lines == 2 && $lines[0] eq "bar\n";
};

done_testing;

END {
  rmtree $tmpdir if $tmpdir && -d $tmpdir;
}
