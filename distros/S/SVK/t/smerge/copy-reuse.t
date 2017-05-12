#!/usr/bin/perl -w
use Test::More tests => 2;
use strict;
use File::Path;
use Cwd;
use SVK::Test;

my ($xd, $svk) = build_test('test');
our $output;
my ($copath, $corpath) = get_copath();
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

is_output($svk, 'sm', [-m => 'local to trunk', '//local/blah', '//foo/bar/trunk'],
          ['Auto-merging (0, 7) /local/blah to /foo/bar/trunk (base /foo/bar/trunk:5).',
           "Merging back to mirror source $uri.",
           'A   A/bzz',
           qr'New merge ticket: .*:/local/blah:7',
           'Merge back committed as revision 4.',
           qr'Syncing .*',
           'Retrieving log information from 4 to 4',
           'Committed revision 8 from revision 4.']);
$svk->rm( -m => 'bye', '//local/blah');
$svk->cp( -m => 'again', '//foo/bar/trunk' => '//local/blah');

$svk->mkdir (-m => 'something bzz', '//local/blah/A/bzz2');

is_output($svk, 'sm', [-m => 'local to trunk', '//local/blah', '//foo/bar/trunk'],
          ['Auto-merging (0, 11) /local/blah to /foo/bar/trunk (base /foo/bar/trunk:8).',
           "Merging back to mirror source $uri.",
           'A   A/bzz2',
           qr'New merge ticket: .*:/local/blah:11',
           'Merge back committed as revision 5.',
           qr'Syncing .*',
           'Retrieving log information from 5 to 5',
           'Committed revision 12 from revision 5.']);
