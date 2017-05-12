use strict;
use warnings;
use Test::More;
use Path::Extended::Class;
use File::Path;
use File::Temp qw/tempdir tmpnam/;

my $tmpdir = tempdir();

# ripped from Path::Class' t/03-filesystem.t

$Path::Extended::IgnoreVolume = 1;

subtest 'file' => sub {
  my $file = file(scalar tmpnam());
  ok $file, 'test 02';

  {
    my $fh = $file->open('w');
    ok $fh, 'test 03';
    ok( (print $fh "Foo\n"), 'test 04');
  }

  ok -e $file, 'test 05';

  {
    my $fh = $file->open;
    is scalar <$fh>, "Foo\n", 'test 06';
  }

  my $stat = $file->stat;
  ok $stat, 'test 07';
  cmp_ok $stat->mtime, '>', time() - 20, 'test 08';

  $stat = $file->dir->stat;
  ok $stat, 'test 09';

  1 while unlink $file;
  ok( (not -e $file), 'test 10');
};

subtest 'dir' => sub {
  my $dir = dir($tmpdir);
  ok $dir, 'test 11';
  ok -d $dir, 'test 13';

  my $file = $dir->file('foo.x');
  $file->touch;
  ok -e $file, 'test 14';

  {
    my $dh = $dir->open;
    ok $dh, 'test 15';

    my @files = readdir $dh;
    is scalar @files, 3, 'test 16';
    ok( (scalar grep { $_ eq 'foo.x' } @files), 'test 17');
  }

  ok $dir->rmtree, 'test 18';
  ok !-e $dir, 'test 19';

  $dir = dir($tmpdir, 't', 'foo', 'bar');
  $dir->parent->rmtree if $dir->parent->exists;

  ok $dir->mkpath, 'test 20';
  ok -d $dir, 'test 21';

  $dir = $dir->parent;
  ok $dir->rmtree, 'test 22';
  ok !-e $dir, 'test 23';

  $dir = dir($tmpdir, 't', 'foo');
  ok $dir->mkpath, 'test 24';
  ok $dir->subdir('dir')->mkpath, 'test 25';
  ok -d $dir->subdir('dir'), 'test 26';

  ok $dir->file('file.x')->touch, 'test 27';
  ok $dir->file('0')->touch, 'test 28';
  my @contents;
  while (my $file = $dir->next) {
    push @contents, $file;
  }
  is scalar @contents, 5, 'test 29';

  my $joined = join ' ', map $_->basename, sort grep {-f $_} @contents;
  is $joined, '0 file.x', 'test 30';

  my ($subdir) = grep {$_ eq $dir->subdir('dir')} @contents;
  ok $subdir, 'test 31';
  is -d $subdir, 1, 'test 32';

  ($file) = grep {$_ eq $dir->file('file.x')} @contents;
  ok $file, 'test 33';
  is -d $file, '', 'test 34';

  ok $dir->rmtree, 'test 35';
  ok !-e $dir, 'test 36';

  # Try again with directory called '0', in curdir
  my $orig = dir()->absolute;

  ok $dir->mkpath, 'test ex 01';
  ok chdir($dir), 'test ex 02';
  my $dir2 = dir();
  ok $dir2->subdir('0')->mkpath, 'test ex 03';
  ok -d $dir2->subdir('0'), 'test ex 04';

  @contents = ();
  while (my $file = $dir2->next) {
    push @contents, $file;
  }
  ok grep({$_ eq '0'} @contents), 'test ex 05';

  ok chdir($orig), 'test ex 06';
  ok $dir->rmtree, 'test ex 07';
  ok !-e $dir, 'test ex 08';
};

subtest 'slurp' => sub {
  my $file = file($tmpdir, 't', 'slurp');
  ok $file, 'test 37';

  my $fh = $file->open('w') or die "Can't create $file: $!";
  print $fh "Line1\nLine2\n";
  close $fh;
  ok -e $file, 'test 38';

  my $content = $file->slurp;
  is $content, "Line1\nLine2\n", 'test 39';

  my @content = $file->slurp;
  is_deeply \@content, ["Line1\n", "Line2\n"], 'test 40';

  @content = $file->slurp(chomp => 1);
  is_deeply \@content, ["Line1", "Line2"], 'test 41';

  $file->remove;
  ok((not -e $file), 'test 42');
};

subtest 'slurp_iomode' => sub {  # added
  unless ($^V ge v5.7.1) {
    SKIP: { skip 'IO modes not available until perl 5.7.1', 1; fail };
    return;
  }

  my $file = file($tmpdir, 't', 'slurp');
  ok $file, 'test 37';

  my $fh = $file->open('>:raw') or die "Can't create $file: $!";
  print $fh "Line1\r\nLine2\r\n\302\261\r\n";
  close $fh;
  ok -e $file, 'test 38';

  my $content = $file->slurp(iomode => '<:raw');
  is $content, "Line1\r\nLine2\r\n\302\261\r\n", 'test 39';

  my $line3 = "\302\261\n";
  utf8::decode($line3);
  my @content = $file->slurp(iomode => '<:crlf:utf8');
  is_deeply \@content, ["Line1\n", "Line2\n", $line3], 'test 40';

  chop $line3;
  @content = $file->slurp(chomp => 1, iomode => '<:crlf:utf8');
  is_deeply \@content, ["Line1", "Line2", $line3], 'test 41';

  $file->remove;
  ok((not -e $file), 'test 42');
};

subtest 'absolute_relative' => sub {
  SKIP: { skip 'known incompatibility', 1; fail };
  return;

  my $cwd = dir();
  is $cwd, $cwd->absolute->relative, 'test 43';
};

subtest 'subsumes' => sub {
  my $t = dir($tmpdir, 't');
  my $foo_bar = $t->subdir('foo','bar');
  $foo_bar->rmtree;

  ok  $t->subsumes($foo_bar), 'test 44';
  ok !$t->contains($foo_bar), 'test 45';

  $foo_bar->mkpath;
  ok  $t->subsumes($foo_bar), 'test 46';
  ok  $t->contains($foo_bar), 'test 47';

  $t->subdir('foo')->rmtree;
};

subtest 'recurse' => sub {
  (my $abe = dir(qw(a b e)))->mkpath;
  (my $acf = dir(qw(a c f)))->mkpath;
  file($acf, 'i')->touch;
  file($abe, 'h')->touch;
  file($abe, 'g')->touch;
  file('a', 'b', 'd')->touch;

  my $d = dir('a');
  my @children = sort $d->children; # following test breaks sometimes

  is_deeply \@children, ['a/b', 'a/c'];

  {
    recurse_test( $d,
      preorder => 1, depthfirst => 0,  # The default
      precedence => [qw(
        a           a/b
        a           a/c
        a/b         a/b/e/h
        a/b         a/c/f/i
        a/c         a/b/e/h
        a/c         a/c/f/i
      )],
    );
  }

  {
    my $files = 
      recurse_test( $d,
        preorder => 1, depthfirst => 1,
        precedence => [qw(
          a           a/b
          a           a/c
          a/b         a/b/e/h
          a/c         a/c/f/i
        )],
      );
    is_depthfirst($files);
  }

  {
    my $files = 
      recurse_test( $d,
        preorder => 0, depthfirst => 1,
        precedence => [qw(
          a/b         a
          a/c         a
          a/b/e/h     a/b
          a/c/f/i     a/c
        )],
      );
    is_depthfirst($files);
  }

  $d->rmtree;

  sub is_depthfirst {
    my $files = shift;
    if ($files->{'a/b'} < $files->{'a/c'}) {
      cmp_ok $files->{'a/b/e'}, '<', $files->{'a/c'}, "Ensure depth-first search";
    } else {
      cmp_ok $files->{'a/c/f'}, '<', $files->{'a/b'}, "Ensure depth-first search";
    }
  }

  sub recurse_test {
    my ($dir, %args) = @_;
    my $precedence = delete $args{precedence};
    my ($i, %files) = (0);
    $dir->recurse( callback => sub {$files{shift->as_foreign('Unix')->stringify} = ++$i},
		 %args );
    while (my ($pre, $post) = splice @$precedence, 0, 2) {
      cmp_ok $files{$pre}, '<', $files{$post}, "$pre should come before $post";
    }
    return \%files;
  }
};

done_testing;

END {
  $Path::Extended::IgnoreVolume = 0;
  my $dir_a = dir('a');
  rmtree $dir_a if $dir_a && -d $dir_a;
  rmtree $tmpdir if $tmpdir && -d $tmpdir;
}
