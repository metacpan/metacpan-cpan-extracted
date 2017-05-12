#!/usr/bin/perl -w
use Test::More tests => 9;
use strict;
use SVK::Test;
our $output;
my ($xd, $svk) = build_test();
my ($copath, $corpath) = get_copath ('remove-revert');
my ($repospath, undef, $repos) = $xd->find_repos ('//', 1);
$svk->checkout ('//', $copath);
chdir ($corpath);
mkdir ('A');
mkdir ('A/deep');
overwrite_file ("A/foo", "foobar");
overwrite_file ("A/deep/bar", "foobar");
$svk->add('A');
$svk->commit('-m', 'commit everything');
#remove the A/deep recursively (not necessary, but people might do it)
$svk->remove('A/deep/bar');
ok(!-f "$corpath/A/deep",'A/deep/bar should be gone now');
$svk->remove('A/deep/');
ok(!-d "$corpath/A/deep",'A/deep should be gone now');
#changed my mind
$svk->revert('A/deep');
ok(-d "$corpath/A/deep",'revert should bring A/deep back');
$svk->revert('A/deep/bar');
ok(-f "$corpath/A/deep/bar",'revert should bring A/deep/bar back');
is_file_content("$copath/A/deep/bar","foobar", 'revert should restore the contents of A/deep/bar') if -f "$copath/A/deep/bar";

 # get A back now, as the above reverts don't work
$svk->up('A/deep');
ok(-d "$corpath/A/deep",'update should also bring A/deep back');
$svk->up('A/deep/bar');
ok(-f "$corpath/A/deep/bar",'update should also bring A/deep/bar back');
is_file_content("$copath/A/deep/bar","foobar", 'revert should restore the contents of A/deep/bar') if -f "$copath/A/deep/bar";

#but in case it doesn't, what if the user put it back
overwrite_file ("A/deep/bar", "foobar");

#now the user decides to remove it after all
$svk->remove('A/deep/');
ok(!-d "$corpath/A/deep",'A/deep should once again be gone now');
$svk->commit('-m','removed A/deep');
#
is_output($svk,'update',[],["Syncing //(/) in $corpath to 2."]);
is_output($svk,'status',[],[]);
$svk->status();
