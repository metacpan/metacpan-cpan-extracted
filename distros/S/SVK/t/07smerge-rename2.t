#!/usr/bin/perl -w

# testing smerge copies happened in intermediate branch which the
# sourcemight not map to something sensible
use Test::More tests => 1;
use strict;
use File::Path;
use Cwd;
use SVK::Test;

my ($xd, $svk) = build_test();
our $output;
my ($copath, $corpath) = get_copath ('smerge-rename2');
my ($repospath, undef, $repos) = $xd->find_repos ('//', 1);
my $uuid = $repos->fs->get_uuid;

$svk->mkdir ('-m', 'trunk', '//trunk');
$svk->mkdir ('-m', 'trunk', '//branches');
$svk->cp(-m => 'newbranch', '//trunk', '//branches/newbranch');
$svk->checkout ('//branches/newbranch', $copath);

chdir($copath);
$svk->mkdir('dir_added_in_newbranch');
overwrite_file('dir_added_in_newbranch/file_added_in_newbranch', 'foo');
$svk->add('dir_added_in_newbranch/file_added_in_newbranch');
$svk->ci(-m => "New files in newbranch");

$svk->copy(-m => "second copy", '//branches/newbranch', '//branches/branchcopy');


$svk->switch('//branches/branchcopy');

$svk->move('dir_added_in_newbranch/file_added_in_newbranch', 'dir_added_in_newbranch/file_moved_in_branchcopy');

$svk->commit(-m => "Renamed file in branchcopy");

is_output($svk, 'smerge', ['--sync', '--log', '--message', "Merge branchcopy back into trunk",  '--remoterev', '//branches/branchcopy', '//trunk'],
	  ['Auto-merging (0, 6) /branches/branchcopy to /trunk (base /trunk:1).',
	   'A   dir_added_in_newbranch',
	   'A   dir_added_in_newbranch/file_moved_in_branchcopy',
	   "New merge ticket: $uuid:/branches/branchcopy:6",
	   "New merge ticket: $uuid:/branches/newbranch:4",
	   'Committed revision 7.']);
