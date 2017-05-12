use strict;
use warnings;
use FindBin;
use Test::More;
use Path::Extended::Tiny;
use File::Path;
use File::Temp qw/tempdir/;

my $tmpdir = tempdir();

subtest 'pm_files' => sub {
  my @found;
  dir("$FindBin::Bin/../../lib")->recurse(sub {
    my $item = shift;
    return unless $item->basename =~ /\.pm$/;

    push @found, $item->absolute;
  });

  ok @found == 1, "found ".@found." items";
};

=pod # incompat

subtest 'preorder' => sub {
  _recurse_test(
    preorder => 1, depthfirst => 0,
    precedences => [qw(
      a    a/b
      a/b  a/b/e/h
      a/b  a/c/f/i
      a/c  a/b/e/h
      a/c  a/c/f/i
    )],
  );
};

=cut

subtest 'preorder_depthfirst' => sub {
  _recurse_test(
    preorder => 1, depthfirst => 1,
    precedences => [qw(
      a    a/b
      a    a/c
      a/b  a/b/e/h
      a/c  a/c/f/i
    )],
  );
};

subtest 'depthfirst' => sub {
  _recurse_test(
    preorder => 0, depthfirst => 1,
    precedences => [qw(
      a/b      a
      a/c      a
      a/b/e/h  a/b
      a/c/f/i  a/c
    )],
  );
};

sub _recurse_test {
  my (%options) = @_;

  my @precedences = @{ delete $options{precedences} };

  my $root = dir("$tmpdir/a");
  my $abe = $root->subdir(qw( b e ))->mkdir;
  my $acf = $root->subdir(qw( c f ))->mkdir;
  $acf->file('i')->touch;
  $abe->file('h')->touch;
  $abe->file('g')->touch;
  $root->file(qw( b d ))->touch;

  my %orders;
  my $count = 0;
  $root->recurse( %options, callback => sub {
    my $entry = shift;
    my $rel = $entry->relative($root->parent);
    $orders{$rel} = $count++;
  });

  $root->remove;

  if ($options{depthfirst}) {
    if ($orders{"a/b"} < $orders{"a/c"}) {
      cmp_ok $orders{"a/b/e"}, '<', $orders{"a/c"}, 'ensure depth-first search';
    }
    else {
      cmp_ok $orders{"a/c/f"}, '<', $orders{"a/b"}, 'ensure depth-first search';
    }
  }

  while ( my ($pre, $post) = splice @precedences, 0, 2 ) {
    cmp_ok $orders{$pre}, '<', $orders{$post}, "$pre should come before $post";
  }
}

done_testing;

END {
  rmtree $tmpdir if $tmpdir && -d $tmpdir;
}
