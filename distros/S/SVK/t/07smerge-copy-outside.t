#!/usr/bin/perl -w
use Test::More tests => 1;
use strict;
use File::Path;
use Cwd;
use SVK::Test;

my ($xd, $svk) = build_test('test');
our $output;
my ($copath, $corpath) = get_copath();
$svk->mkdir ('-pm', 'trunk', '/test/trunk');
$svk->mkdir ('-pm', 'some other local', '//local/something/fnord');
my $tree = create_basic_tree ($xd, '/test/trunk');
$svk->mkdir(-m => 'blah', '//foo/bar');

my ($srepospath, $spath, $srepos) = $xd->find_repos ('/test/trunk', 1);

my $uri = uri($srepospath).$spath;
$svk->mi('//foo/bar/trunk', $uri);
$svk->sync('//foo/bar/trunk');
$svk->cp ('-m', 'branch', '//foo/bar/trunk', '//local/blah');
$svk->cp (-m => 'something', '//local/something/fnord' => '//local/blah/fnord');

is_output(
    $svk, 'push',
    ['//local/blah'],
    [   'Auto-merging (0, 7) /local/blah to /foo/bar/trunk (base /foo/bar/trunk:5).',
        '===> Auto-merging (0, 6) /local/blah to /foo/bar/trunk (base /foo/bar/trunk:5).',
        "Merging back to mirror source $uri.",
        'Empty merge.',
        '===> Auto-merging (6, 7) /local/blah to /foo/bar/trunk (base /foo/bar/trunk:5).',
        "Merging back to mirror source $uri.",
        'A   fnord',
        qr'New merge ticket: .*:/local/blah:7',
        'Merge back committed as revision 4.',
        "Syncing $uri",
        'Retrieving log information from 4 to 4',
        'Committed revision 8 from revision 4.',
    ],
    'fnord is not merged as a copy'
);


