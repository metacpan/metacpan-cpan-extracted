use Mojo::Base -strict;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::More;
use Test::Mojo;
plan tests => 11;

my $t = Test::Mojo->new('MyApp');
$t->get_ok('/')->status_is(200)
  ->json_is('/downloads', '/a/b/c/downloads',
  'ConfigHashMerge does not overwrite defaults')
  ->json_is('/music',  '/foo/bar/baz/music')
  ->json_is('/ebooks', '/foo/bar/baz/ebooks');

# we can override the config:

$t = Test::Mojo->new('MyApp',
  {'watch_dirs' => {'themes' => '/foo/bar/baz/themes'}});
$t->get_ok('/')->status_is(200)
  ->json_is('/themes', '/foo/bar/baz/themes',
  'we can override the config in the test')->json_hasnt('/music')
  ->json_hasnt('/ebooks')->json_hasnt('/downloads');


