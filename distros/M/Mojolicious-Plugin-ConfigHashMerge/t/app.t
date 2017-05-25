use Mojo::Base -strict;

use FindBin;
use lib "$FindBin::Bin/lib";

use Mojolicious;
use Test::More;
use Test::Mojo;
use constant TEST_OVERRIDE => ($Mojolicious::VERSION >= 7.29) ? 1 : 0;
plan tests => 1 + TEST_OVERRIDE;

my $t = Test::Mojo->new('MyApp');
subtest(
  'without override' => sub {
    plan tests => 5;
    $t->get_ok('/')->status_is(200)
      ->json_is('/downloads', '/a/b/c/downloads',
      'ConfigHashMerge does not overwrite defaults')
      ->json_is('/music',  '/foo/bar/baz/music')
      ->json_is('/ebooks', '/foo/bar/baz/ebooks');
  }
);

# we can override the config:

if (TEST_OVERRIDE > 0) {
  subtest(
    'override config in test object' => sub {
      plan tests => 6;
      $t = Test::Mojo->new('MyApp',
        {'watch_dirs' => {'themes' => '/foo/bar/baz/themes'}});
      $t->get_ok('/')->status_is(200)
        ->json_is('/themes', '/foo/bar/baz/themes',
        'we can override the config in the test')->json_hasnt('/music')
        ->json_hasnt('/ebooks')->json_hasnt('/downloads');
    }
  );
}


