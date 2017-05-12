use strict;
use warnings;
use Test::More;
use Module::New;
use Module::New::Path;
use Path::Tiny;

Module::New->setup('Module::New::ForTest');

subtest default => sub {
  my $path = Module::New::Path->new;

  my $root = eval { $path->guess_root; } || '';
  my $dir = path('.')->absolute;
  ok $dir->child('Makefile.PL')->exists, 'Makefile.PL exists';
  is $root->realpath => $dir->realpath, 'root is current dir';
};

subtest look_for_makefile_pl => sub {
  my $path = Module::New::Path->new;

  my $current = path('.')->absolute;
  my $testapp = path('t/TestApp')->absolute;
     $testapp->mkpath;
     $testapp->child('lib/foo')->mkpath;
     $testapp->child('Makefile.PL')->touch;
  ok $testapp->child('Makefile.PL')->exists, 'Makefile.PL exists';

  chdir $testapp->child('lib/foo');

  my $root = eval { $path->guess_root; } || '';

  is $root->realpath => $testapp->realpath, 'root is testapp';

  chdir $current;

  $testapp->remove_tree;
};

subtest look_for_build_pl => sub {
  my $path = Module::New::Path->new;

  my $current = path('.')->absolute;
  my $testapp = path('t/TestApp')->absolute;
     $testapp->mkpath;
     $testapp->child('lib/foo')->mkpath;
     $testapp->child('Build.PL')->touch;
  ok $testapp->child('Build.PL')->exists, 'Build.PL exists';

  chdir $testapp->child('lib/foo');

  my $root = eval { $path->guess_root; } || '';

  is $root->realpath => $testapp->realpath, 'root is testapp';
  chdir $current;

  $testapp->remove_tree;
};

subtest not_found => sub {
  my $path = Module::New::Path->new;

  my $current = path('.')->absolute;
  my $dir;
  foreach my $candidate (qw( / /tmp )) {
    $dir = path($candidate)->absolute;
    last if chdir $dir;
  }
  if ( $current eq $dir ) {
    SKIP: {
      skip 'this test may be unstable for you', 1;
      fail;
      return;
    }
  }

  local $@;
  eval { $path->guess_root; };

  ok $@ =~ /^Can't guess root/, "Can't guess root";

  chdir $current;
};

subtest with_args => sub {
  my $path = Module::New::Path->new;

  my $current = path('.')->absolute;
  my $testapp = path('t/TestApp')->absolute;
  ok !$testapp->exists, 'testapp does not exist';

  local $@;
  my $root = eval { $path->guess_root('t/TestApp/'); } || '';

  is $root->absolute => $testapp->absolute, 'root is testapp';
  ok $testapp->exists, 'testapp exists';

  chdir $current;

  $testapp->remove_tree;
};

done_testing;
