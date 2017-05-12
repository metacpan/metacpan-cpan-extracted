#!/usr/bin/perl -w
use strict;
use Test::More tests => 1;
use SVK::Test;
use File::Path;
our $output;

my ($xd, $svk) = build_test('mv');
$svk->mkdir(-m => 'trunk', '/mv/T');
$svk->mkdir(-m => 'trunk', '/mv/B');
my $tree = create_basic_tree($xd, '/mv/T');
my ($copath, $corpath) = get_copath ('moving');

my $depot = $xd->find_depot('mv');
my $uri = uri($depot->repospath);

$svk->mirror('//mirror/P', $uri);
$svk->sync('//mirror/P');

my $trunk = '/mirror/P/T';
$svk->checkout('/'.$trunk,$copath);
chdir($copath);

$svk->mkdir ('//mirror/P/B/F', -m => 'Feature');
$svk->mkdir ('//mirror/P/B/R', -m => 'Release');
$svk->list ('//mirror/P');
$svk->cp ('//mirror/P/T', '//mirror/P/B/F/foo', '-p', -m => '- Trunk to Feature foo');

is_output ($svk, 'move', ['//mirror/P/B/F/foo', '//mirror/P/B/R/bar', '-p', -m => "move foo to bar"],
    ["Merging back to mirror source $uri.",
     "Merge back committed as revision 8.",
     "Syncing $uri",
     "Retrieving log information from 8 to 8",
     "Committed revision 9 from revision 8."]);
