#!/usr/bin/perl -w

use strict;

use Test::More tests => 1;
use File::Path;
use Cwd;
use SVK::Test;

my ($xd, $svk) = build_test();
our $output;
my ($copath, $corpath) = get_copath();
my (undef, undef, $repos) = $xd->find_repos ('//', 1);
my $uuid = $repos->fs->get_uuid;

$svk->mkdir ('-m', 'trunk', '//trunk');
my $tree = create_basic_tree ($xd, '//trunk');
$svk->cp ('-m', 'branch', '//trunk', '//local');
$svk->cp ('-m', 'branch', '//local', '//local-another');
$svk->co ('//trunk', $copath);
append_file("$copath/me", "a change\n");
$svk->ci ('-m', 'change file', $copath );

$svk->switch ('//local-another', $copath);
append_file("$copath/A/be", "a change\n");
$svk->ci ('-m', 'change file', $copath );
$svk->sm ('-Il', '//local-another', '//local' );

$svk->switch ('//local@4', $copath);
$svk->sm ('//trunk', $copath);

$svk->up ($copath);
is_output($svk, 'diff', [$copath],
    [
     __("=== $copath/me"),
    '==================================================================',
     __("--- $copath/me\t(revision 8)"),
     __("+++ $copath/me\t(local)"),
    '@@ -1,2 +1,3 @@',
    ' first line in me',
    ' 2nd line in me - mod',
    '+a change',
    '',
    __("Property changes on: $copath"),
    '___________________________________________________________________',
    'Name: svk:merge',
    "  $uuid:/local-another:7",
    " -$uuid:/trunk:3",
    " +$uuid:/trunk:6",
    ""
    ]
);
