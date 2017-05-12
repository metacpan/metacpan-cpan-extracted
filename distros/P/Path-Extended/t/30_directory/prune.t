use strict;
use warnings;
use Test::More;
use Path::Extended;
use File::Path;
use File::Temp qw/tempdir/;

my $tmpdir = tempdir();

subtest 'prune' => sub {
  my @expected = qw(
    prune
    prune/file
    prune/dir
    prune/dir/file
  );

  _prune_test(1, @expected);
};

subtest 'no_prune' => sub {
  my @expected = qw(
    prune
    prune/.dot
    prune/.ignore
    prune/dir
    prune/file
    prune/.dot/.dotfile
    prune/.dot/file
    prune/dir/.dotfile
    prune/dir/file
  );

  _prune_test(0, @expected);
};

subtest 'prune_by_regex' => sub {
  my @expected = qw(
    prune
    prune/.ignore
    prune/dir
    prune/file
    prune/dir/.dotfile
    prune/dir/file
  );

  _prune_test(qr/^\.dot$/, @expected);
};

subtest 'prune_by_code' => sub {
  my @expected = qw(
    prune
    prune/.dot
    prune/.ignore
    prune/file
    prune/.dot/.dotfile
    prune/.dot/file
  );

  _prune_test(sub { return shift->basename eq 'dir' ? 1 : 0 }, @expected);
};

sub _prune_test {
  my ($rule, @expected) = @_;

  my $root = dir("$tmpdir/prune");
     $root->mkdir;
     $root->file('.ignore')->touch;
     $root->file('file')->touch;

  foreach my $dirname (qw( .dot dir )) {
    my $dir = $root->subdir($dirname);
    $dir->mkdir;
    $dir->file('.dotfile')->touch;
    $dir->file('file')->touch;
  }

  my @found;
  $root->recurse( prune => $rule, callback => sub {
    push @found, shift->relative($root->parent);
  });
  ok @found == @expected, "found ".@found." items";

  foreach my $item (@found) {
    my $is_found = grep { $_ eq $item } @expected;
    ok $is_found, "found $item";
  }

  $root->remove;
}

done_testing;

END {
  rmtree $tmpdir if $tmpdir && -d $tmpdir;
}
