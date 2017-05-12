use strict;
use warnings;
use Test::More;
use Path::Extended;
use File::Path;
use File::Temp qw/tempdir/;
use utf8;

my $tmpdir = tempdir();

subtest 'basic' => sub {
  my $file = file("$tmpdir/slurp.txt");

  ok $file->save("content"), 'file saved';
  ok $file->slurp eq "content", 'slurped successfully';

  $file->unlink;
};

subtest 'multilines' => sub {
  my $file = file("$tmpdir/slurp.txt");

  my $content = "line1\nline2\nline3\n";
  ok $file->save($content), 'file saved';
  ok $file->slurp eq $content, 'slurped successfully';

  $file->unlink;
};

subtest 'list' => sub {
  my $file = file("$tmpdir/slurp.txt");

  my $content = "line1\nline2\nline3\n";
  ok $file->save($content), 'file saved';

  my @lines = $file->slurp;

  ok $lines[0] eq "line1\n", 'slurped successfully';

  $file->unlink;
};

subtest 'binmode' => sub {
  my $file = file("$tmpdir/slurp.txt");

  ok $file->save("first line\012second line\012", {
    binmode => 1,
  }), 'file saved';

  ok $file->slurp({ binmode => 1 }) eq "first line\012second line\012", 'binmode worked';

  $file->unlink;
};

subtest 'mkdir' => sub {
  my $file = file("$tmpdir/slurp/slurp.txt");
  ok $file->save("content", mkdir => 1), 'made directory';
  ok $file->slurp eq 'content', 'slurped successfully';

  $file->parent->rmdir;
};

subtest 'encode' => sub {
  my $utf8 = "テスト";

  my $file = file("$tmpdir/slurp.txt");
  ok $file->save($utf8, encode => 'utf8'), 'file saved as utf8';
  ok $file->slurp(decode => 'utf8') eq $utf8, 'slurped successfully as utf8';

  $file->unlink;
};

subtest 'chomp' => sub {
  my $file = file("$tmpdir/slurp.txt");
  ok $file->save("first line\nsecond line\n"), 'file saved';
  my @lines = $file->slurp( chomp => 1 );
  ok $lines[0] eq 'first line', 'chomped successfully';

  $file->unlink;
};

subtest 'callback' => sub {
  my $file = file("$tmpdir/slurp.txt");
  ok $file->save("first line\nsecond line\n", callback => sub { s/line/son/; $_; }), 'file saved';
  my @lines = $file->slurp( callback => sub { s/son/daughter/; $_; } );
  ok $lines[0] eq "first daughter\n", 'callback worked';

  $file->unlink;
};

subtest 'mtime' => sub {
  my $file = file("$tmpdir/slurp.txt");
  ok $file->save("first line\nsecond line\n", mtime => time - 30000), 'file saved';
  ok $file->mtime < time - 10000, 'mtime worked';

  $file->unlink;
};

subtest 'multiple_callbacks' => sub {
  my $utf8 = "テスト";

  my $file = file("$tmpdir/slurp.txt");
  ok $file->save($utf8, encode => 'utf8', callback => sub { "$_\n" }), 'file saved as utf8';
  ok $file->slurp(decode => 'utf8', callback => sub { s/\n//s; $_ }) eq $utf8, 'slurped successfully as utf8';

  $file->unlink;
};

done_testing;

END {
  rmtree $tmpdir if $tmpdir && -d $tmpdir;
}
