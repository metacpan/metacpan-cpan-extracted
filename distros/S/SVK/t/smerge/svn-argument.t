#!/usr/bin/perl -w
use Test::More tests => 1;
use strict;
use File::Path;
use Cwd;
use SVK::Test;

my ($xd, $svk) = build_test('test');
our $output;
my ($copath, $corpath) = get_copath ('smerge-argument');
$svk->mkdir ('-pm', 'trunk', '/test/trunk');
$svk->mkdir ('-pm', 'some other local', '//local');
my $tree = create_basic_tree ($xd, '/test/trunk');
$svk->mkdir(-m => 'blah', '//foo/bar');

my ($srepospath, $spath, $srepos) = $xd->find_repos ('/test/trunk', 1);

my $uri = uri($srepospath).$spath;
$svk->mi('//foo/bar/trunk', $uri);
$svk->sync('//foo/bar/trunk');
$svk->cp ('-m', 'branch', '//foo/bar/trunk' => '//local/blah');

$svk->mkdir (-m => 'something bzz', '//local/blah/A/bzz');

# invalid base format such as "file:///dev/shm/svk/test_repos/trunk:5"
is_output($svk, 'sm', [-m => 'local to trunk', -b => $uri.':5', '//local/blah', '//foo/bar/trunk'],
          ["Invalid merge base:'$uri:5'"])
