#!/usr/bin/perl -w

use strict;

use Test::More tests => 2;
use File::Path;
use Cwd;
use SVK::Test;

my ($xd, $svk) = build_test();
our $output;
my ($copath, $corpath) = get_copath();
my (undef, undef, $repos) = $xd->find_repos ('//', 1);
my $uuid = $repos->fs->get_uuid;

$svk->mkdir ('-m', 'version 1.0', '//1.0');
my $tree = create_basic_tree ($xd, '//1.0');
$svk->cp ('-m', 'branch 2.0', '//1.0', '//2.0');
$svk->mv ('-m', 'move dir A in 2.0', '//2.0/A', '//2.0/A-moved');
$svk->cp ('-m', 'branch 3.0', '//2.0', '//3.0');

$svk->co ('//1.0', $copath);
append_file("$copath/A/be", "a change\n");
$svk->ci ('-m', 'change file', $copath );

is_output($svk, 'sm', ['-C', '//1.0', '//3.0'],
    [
        'Auto-merging (3, 7) /1.0 to /3.0 (base /1.0:3).',
        '    A - skipped',
        '    A/be - skipped',
        'Empty merge.',
    ],
);

TODO: {
local $TODO = "rename in intermediate branch is not tracked";
is_output($svk, 'sm', ['-C', '--track-rename', '//1.0', '//3.0'],
    [
        'Auto-merging (3, 7) /1.0 to /3.0 (base /1.0:3).',
        'Collecting renames, this might take a while.',
        'M   A/be',
        # some merge ticket
        # new rev committed
    ],
);
}

