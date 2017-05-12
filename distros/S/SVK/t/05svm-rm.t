#!/usr/bin/perl -w
use strict;
use Test::More;

use SVK::Test;
eval { require SVN::Mirror; 1 } or plan skip_all => 'require SVN::Mirror';
plan tests => 11;

# build another tree to be mirrored ourself
my ($xd, $svk) = build_test('svmrm');
my ($copath, $corpath) = get_copath ('svmrm');

my $tree = create_basic_tree ($xd, '/svmrm/');
my ($test_repospath, $test_a_path, $test_repos) = $xd->find_repos ('/svmrm/A', 1);

my $uri = uri($test_repospath);
$svk->mirror ('//rm/m', $uri.($test_a_path eq '/' ? '' : $test_a_path));

is_output($svk, 'rm', ['-m', 'rm parent of mirrored path', '//rm'],
	  ['//rm contains mirror, remove explicitly: //rm/m']);
$svk->rm ('-m', 'rm parent of mirrored path', '//rm/m');
is_output ($svk, 'propget', ['svm:mirror', '//'], []);

$svk->mirror ('//rm/m', $uri.($test_a_path eq '/' ? '' : $test_a_path));

$svk->checkout ('//', $copath);
chdir ($copath);
is_output ($svk, 'rm', ['rm'],
	  ['//rm contains mirror, remove explicitly: //rm/m']);

$svk->mkdir(-p => "rm/m/foo/bar");
$svk->mkdir(-p => "rm/unrelated");
is_output($svk, 'rm', ["rm/m/foo/bar"],
	  [__("rm/m/foo/bar is scheduled; use '--force' to go ahead.")]);

is_output($svk, 'rm', ["rm/m/foo/bar", "rm/unrelated"],
	  ['//rm contains mirror, remove explicitly: //rm/m']);

is_output($svk, 'rm', ['--force', "rm/m/foo/bar"],
	  [__("D   rm/m/foo/bar")]);

is_output($svk, 'rm', [-m => 'bye', '--direct', '//rm/m'],
	  ['Committed revision 5.']);

TODO: {
local $TODO = 'detach a obstructed mirror source.';

is_output($svk, 'mi', ['--detach', '//rm/m'],
	  ['Committed revision 6.',
	   "Mirror path '/rm/m' detached"]);

is_output ($svk, 'propget', ['svm:mirror', '//'], []);
}

# reset tests
$svk->ps(-m => 'bandaid.', 'svm:mirror', '', '//');

$svk->mirror('//rm/m2', "$uri/A");
$svk->mirror('//rm/m1', "$uri/B");
$svk->sync('-a');


is_output($svk, 'rm', [-m => 'try delete', '//rm/m2/Q', '///rm/m1/S/P'],
	  ['Different source.']);

is_output($svk, 'rm', [-m => 'try delete', '//rm/m2/Q/qu', '///rm/m2/Q/qz'],
	  ["Merging back to mirror source $uri/A.",
	   'Merge back committed as revision 3.',
	   "Syncing $uri/A",
	   'Retrieving log information from 3 to 3',
	   'Committed revision 13 from revision 3.']);

