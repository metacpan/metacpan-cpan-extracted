#!usr/bin/perl -w
use strict;
use Test::More;
use SVK::Test;
plan tests => 3;
our ($output, $answer);
# build another tree to be mirrored ourself
my ($xd, $svk) = build_test('test');
$svk->mkdir (-pm => 'trunk', '/test/trunk/foo/baz');
my $tree = create_basic_tree ($xd, '/test/trunk');

$svk->copy (-pm => 'local', '/test/trunk' => '/test/local');

waste_rev ($svk, '/test/wasted') for (1..10);

my ($srepospath, $spath, $srepos) =$xd->find_repos ('/test/trunk', 1);
my $uri = uri($srepospath);

# svn doesn't normalise copy source revision
use SVN::Client;

my $client = SVN::Client->new
    (log_msg =>
     sub { ${$_[0]} = "svn doesn't normalise copy source" }
    );

$client->copy("$uri/trunk/foo", $srepos->fs->youngest_rev, "$uri/trunk/bar2");
is_ancestor($svk, '/test/trunk/bar2', '/trunk/foo', 1);

$svk->copy (-pm => 'here', '/test/trunk/foo' => '/test/trunk/bar');


$svk->mirror ('//m-main', "$uri/trunk");
$svk->sync('-a');

is_ancestor($svk, '//m-main/bar', '/m-main/foo', 2);
is_ancestor($svk, '//m-main/bar2', '/m-main/foo', 2);

