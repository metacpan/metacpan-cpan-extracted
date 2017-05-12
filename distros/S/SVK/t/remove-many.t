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
my ($copath, $corpath) = get_copath();

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

# B/F is rev 6, where B/R is rev 7
# this will raise a 'out of date' error when using B/F as target (in Command/Delete.pm)
is_output ($svk, 'remove', ['//mirror/P/B/F', '//mirror/P/B/R',  -m => "move foo to bar"],
    ["Merging back to mirror source $uri.",
     "Merge back committed as revision 7.",
     "Syncing $uri",
     "Retrieving log information from 7 to 7",
     "Committed revision 8 from revision 7."]);
