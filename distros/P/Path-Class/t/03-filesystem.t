use strict;
use Test::More;
use File::Temp qw(tmpnam tempdir);

use_ok 'Path::Class';


my $file = file(scalar tmpnam());
ok $file, "Got a filename via tmpnam()";

{
  my $fh = $file->open('w');
  ok $fh, "Opened $file for writing";
  
  ok print( $fh "Foo\n"), "Printed to $file";
}

ok -e $file, "$file should exist";

{
  my $fh = $file->open;
  is scalar <$fh>, "Foo\n", "Read contents of $file correctly";
}

{
  my $stat = $file->stat;
  ok $stat;
  cmp_ok $stat->mtime, '>', time() - 20;  # Modified within last 20 seconds

  $stat = $file->dir->stat;
  ok $stat;
}

1 while unlink $file;
ok not -e $file;


my $dir = dir(tempdir(CLEANUP => 1));
ok $dir;
ok -d $dir;

$file = $dir->file('foo.x');
$file->touch;
ok -e $file;

{
  my $dh = $dir->open;
  ok $dh, "Opened $dir for reading";

  my @files = readdir $dh;
  is scalar @files, 3;
  ok scalar grep { $_ eq 'foo.x' } @files;
}

ok $dir->rmtree, "Removed $dir";
ok !-e $dir, "$dir no longer exists";

{
  $dir = dir('t', 'foo', 'bar');
  $dir->parent->rmtree if -e $dir->parent;

  ok $dir->mkpath, "Created $dir";
  ok -d $dir, "$dir is a directory";

  # Use a Unix sample path to test cleaning it up
  my $ugly = Path::Class::Dir->new_foreign(Unix => 't/foo/..//foo/bar');
  $ugly->resolve;
  is $ugly->as_foreign('Unix'), 't/foo/bar';
  
  $dir = $dir->parent;
  ok $dir->rmtree;
  ok !-e $dir;
}

{
  $dir = dir('t', 'foo');
  ok $dir->mkpath;
  ok $dir->subdir('dir')->mkpath;
  ok -d $dir->subdir('dir');
  
  ok $dir->file('file.x')->touch;
  ok $dir->file('0')->touch;
  my @contents;
  while (my $file = $dir->next) {
    push @contents, $file;
  }
  is scalar @contents, 5;

  my $joined = join ' ', sort map $_->basename, grep {-f $_} @contents;
  is $joined, '0 file.x';
  
  my ($subdir) = grep {$_ eq $dir->subdir('dir')} @contents;
  ok $subdir;
  is -d $subdir, 1;

  my ($file) = grep {$_ eq $dir->file('file.x')} @contents;
  ok $file;
  is -d $file, '';
  
  ok $dir->rmtree;
  ok !-e $dir;


  # Try again with directory called '0', in curdir
  my $orig = dir()->absolute;

  ok $dir->mkpath;
  ok chdir($dir);
  my $dir2 = dir();
  ok $dir2->subdir('0')->mkpath;
  ok -d $dir2->subdir('0');

  @contents = ();
  while (my $file = $dir2->next) {
    push @contents, $file;
  }
  ok grep {$_ eq '0'} @contents;

  ok chdir($orig);
  ok $dir->rmtree;
  ok !-e $dir;
}

{
  my $file = file('t', 'slurp');
  ok $file;
  
  my $fh = $file->open('w') or die "Can't create $file: $!";
  print $fh "Line1\nLine2\n";
  close $fh;
  ok -e $file;
  
  my $content = $file->slurp;
  is $content, "Line1\nLine2\n";
  
  my @content = $file->slurp;
  is_deeply \@content, ["Line1\n", "Line2\n"];

  @content = $file->slurp(chomp => 1);
  is_deeply \@content, ["Line1", "Line2"];

  is_deeply [ $file->slurp( chomp => 1, split => qr/n/ ) ]
    => [ [ 'Li', 'e1' ], [ 'Li', 'e2' ] ],
    "regex split with chomp";

  is_deeply [ $file->slurp( chomp => 1, split => 'n' ) ]
    => [ [ 'Li', 'e1' ], [ 'Li', 'e2' ] ],
    "string split with chomp";

  $file->remove;
  ok not -e $file;
}

SKIP: {
  my $file = file('t', 'slurp');
  ok $file;

  skip "IO modes not available until perl 5.7.1", 5
    unless $^V ge v5.7.1;
  
  my $fh = $file->open('>:raw') or die "Can't create $file: $!";
  print $fh "Line1\r\nLine2\r\n\302\261\r\n";
  close $fh;
  ok -e $file;
  
  my $content = $file->slurp(iomode => '<:raw');
  is $content, "Line1\r\nLine2\r\n\302\261\r\n";
  
  my $line3 = "\302\261\n";
  utf8::decode($line3);
  my @content = $file->slurp(iomode => '<:crlf:utf8');
  is_deeply \@content, ["Line1\n", "Line2\n", $line3];

  chop($line3);
  @content = $file->slurp(chomp => 1, iomode => '<:crlf:utf8');
  is_deeply \@content, ["Line1", "Line2", $line3];

  $file->remove;
  ok not -e $file;
}

{
    my $file = file('t', 'spew');
    $file->remove() if -e $file;
    $file->spew( iomode => '>:raw', "Line1\r\n" );
    $file->spew( iomode => '>>', "Line2" );

    my $content = $file->slurp( iomode => '<:raw');

    is( $content, "Line1\r\nLine2" );

    $file->remove;
    ok not -e $file;
}

{
    my $file = file('t', 'spew_lines');
    $file->remove() if -e $file;
    $file->spew_lines( iomode => '>:raw', "Line1" );
    $file->spew_lines( iomode => '>>:raw', [qw/Line2 Line3/] );

    my $content = $file->slurp( iomode => '<:raw');

    is( $content, "Line1$/Line2$/Line3$/" );

    $file->remove;
    ok not -e $file;
}

{
  # Make sure we can make an absolute/relative roundtrip
  my $cwd = dir();
  is $cwd, $cwd->absolute->relative, "from $cwd to ".$cwd->absolute." to ".$cwd->absolute->relative;
}

{
  my $t = dir('t');
  my $foo_bar = $t->subdir('foo','bar');
  $foo_bar->rmtree; # Make sure it doesn't exist

  ok  $t->subsumes($foo_bar), "t subsumes t/foo/bar";
  ok !$t->contains($foo_bar), "t doesn't contain t/foo/bar";

  $foo_bar->mkpath;
  ok  $t->subsumes($foo_bar), "t still subsumes t/foo/bar";
  ok  $t->contains($foo_bar), "t now contains t/foo/bar";

  $t->subdir('foo')->rmtree;

  my $cur = dir();
  ok  $cur->subsumes(dir("foo"));
  ok  $cur->subsumes(dir("foo", "..", "bar"));
  ok !$cur->subsumes("..");
  ok  $cur->subsumes("0");
}

{
  # Some edge cases with updir
  my $c = dir();
  ok  $c->contains(dir()),                 ". contains .";
  ok  $c->contains(dir("t")),              ". contains t";
  ok !$c->contains(dir("..")),             ". does not contain ..";
  ok !$c->contains(dir("t", "..", "foo")), ". does not contains non-existent ./foo";
  ok  $c->contains(dir("t", "..", "t")),   ". contains t/../t";
  ok  $c->contains(dir("t", "..")),        ". contains t/..";
  ok !$c->contains(dir("t", "..", "..")),  ". does not contain t/../..";
  ok  $c->contains(dir("..", ($c->absolute->components)[-1])), "to .. and back";
  
  $c= dir("t","..");
  ok  $c->contains(dir("t")), "./t/../ contains t";
  
  $c= dir("t","..","t","..","t");
  my $other= dir("t","..","t","03-filesystem.t");
  ok  $c->contains($other),            "./t/../t/../t contains t/03-filesystem.t";
  is( ($other->components)[-3], '..',  "no side effect from contains()" );
  is( ($c->components)[-2], '..',      "no side effect from contains()" );
}

{
  # Test recursive iteration through the following structure:
  #     a
  #    / \
  #   b   c
  #  / \   \
  # d   e   f
  #    / \   \
  #   g   h   i
  (my $abe = dir(qw(a b e)))->mkpath;
  (my $acf = dir(qw(a c f)))->mkpath;
  file($acf, 'i')->touch;
  file($abe, 'h')->touch;
  file($abe, 'g')->touch;
  file('a', 'b', 'd')->touch;

  my $a = dir('a');

  # Make sure the children() method works ok
  my @children = sort map $_->as_foreign('Unix'), $a->children;
  is_deeply \@children, ['a/b', 'a/c'];
  
  {
    recurse_test( $a,
		  preorder => 1, depthfirst => 0,  # The default
		  precedence => [qw(a           a/b
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
      recurse_test( $a,
		    preorder => 1, depthfirst => 1,
		    precedence => [qw(a           a/b
				      a           a/c
				      a/b         a/b/e/h
				      a/c         a/c/f/i
				     )],
		  );
    is_depthfirst($files);
  }

  {
    my $files = 
      recurse_test( $a,
		    preorder => 0, depthfirst => 1,
		    precedence => [qw(a/b         a
				      a/c         a
				      a/b/e/h     a/b
				      a/c/f/i     a/c
				     )],
		  );
    is_depthfirst($files);
  }
  

  $a->rmtree;

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
    $a->recurse( callback => sub {$files{shift->as_foreign('Unix')->stringify} = ++$i},
		 %args );
    while (my ($pre, $post) = splice @$precedence, 0, 2) {
      cmp_ok $files{$pre}, '<', $files{$post}, "$pre should come before $post";
    }
    return \%files;
  }
}

{
  $dir = Path::Class::tempdir();
  isa_ok $dir, 'Path::Class::Dir';

  $dir = Path::Class::tempdir(CLEANUP => 1);
  isa_ok $dir, 'Path::Class::Dir';
}

# copy_to()
{
  my $file1 = file('t', 'file1');
  my $file2 = file('t', 'file2');
  $file1->spew("some contents");
  ok -e $file1;

  my $copy = $file1->copy_to($file2);

  isa_ok $copy, "Path::Class::File"; 
  is($copy->stringify, $file2->stringify, "same file");

  ok -e $file2;
  is($file2->slurp, "some contents");

  my $dir = dir('t', 'dir');
  $dir->mkpath;
  $file1->copy_to($dir);
  my $dest = $dir->file($file1->basename);
  ok -e $dest;
  is($dest->slurp, "some contents");

  $_->remove for ($file1, $file2);
  $dir->rmtree;
  ok( ! -e $_, "$_ should be removed") for ($file1, $file2, $dir);
}

# move_to()
{
  my $file1 = file('t', 'file1');
  my $src   = file('t', 'file1');

  my $file2 = file('t', 'file2');
  $file1->spew("some contents");
  ok -e $file1;

  my $move = $file1->move_to($file2);
  ok -e $file2;
  is($file2->slurp, "some contents");
  ok ! -e $src;

  is($file1->stringify, $file2->stringify);

  $file2->remove;
  ok( ! -e $_, "$_ should be gone") for ($file1, $file2);
}

done_testing();
