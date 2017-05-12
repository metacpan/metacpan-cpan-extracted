#!/usr/bin/perl -w
use strict;
use SVK::Test;
plan tests => 19;

my ($xd, $svk) = build_test();
our $output;
my ($copath, $corpath) = get_copath();
my ($repospath, undef, $repos) = $xd->find_repos ('//', 1);
$svk->checkout ('//', $copath);
mkdir "$copath/A";
overwrite_file ("$copath/A/foo", "foobar");
overwrite_file ("$copath/A/bar", "foobarbazz");

$svk->add ("$copath/A");
overwrite_file ("$copath/A/notused", "foobarbazz");
ok(exists $xd->{checkout}->get
   (__"$corpath/A/foo")->{'.schedule'}, 'add recursively');
ok(!exists $xd->{checkout}->get
   (__"$corpath/A/notused")->{'.schedule'}, 'add works on specified target only');
$svk->commit ('-m', 'commit message here', "$copath");
unlink ("$copath/A/notused");
$svk->revert ('-R', $copath);
ok(!-e "$copath/A/notused", 'non-targets not committed');
is ($xd->{checkout}->get ("$corpath")->{revision}, 1,
    'checkout optimization after commit');
mkdir "$copath/A/new";
mkdir "$copath/A/new/newer";
$svk->add ("$copath/A/new");
$svk->revert ('-R', "$copath/A/new");

ok(!$xd->{checkout}->get (__"$corpath/A/new")->{'.schedule'});

ok($xd->{checkout}->get (__"$corpath/A/foo")->{revision} == 1);
$svk->update ("$copath");
ok($xd->{checkout}->get ("$corpath")->{revision} == 1);

$svk->ps ('someprop', 'propvalue', "$copath/A");
$svk->ps ('moreprop', 'propvalue', "$copath/A");
overwrite_file ("$copath/A/baz", "zzzz");
append_file ("$copath/A/foo", "foobar");
$svk->add ("$copath/A/baz");
$svk->ps ('someprop', 'propvalue', "$copath/A/baz");
$svk->status ("$copath/A");
$svk->pl ('-v', "$copath/A/baz");
$svk->commit ('-m', 'commit message here', "$copath/A");

$svk->rm ("$copath/A/bar");
ok(!-e "$copath/A/bar");
$svk->commit ('-m', 'remove files', "$copath/A");

$svk->revert ("$copath/A/bar");
ok(!-e "$copath/A/bar");

$svk->revert ('-R', "$copath/A");
ok(!-e "$copath/A/bar");
$svk->pl ('-v', "$copath/A/baz");

$svk->status ("$copath/A");
$svk->ps ('neoprop', 'propvalue', "$copath/A/baz");
$svk->pl ("$copath/A/baz");
$svk->pl ("$copath/A");

$svk->commit ('-m', 'commit message here', "$copath/A");

$svk->ps ('-m', 'set propdirectly', 'directprop' ,'propvalue', '//A');
$svk->update ($copath);

ok (eq_hash ($xd->create_path_object
			      ( xd => $xd,
				copath_anchor => $corpath,
				repos => $repos,
				path => '/A',
				revision => $repos->fs->youngest_rev)->root->node_proplist('/A') ,
	     { directprop => 'propvalue',
	       someprop => 'propvalue',
	       moreprop => 'propvalue'}), 'prop matched');

mkdir "$copath/B";
overwrite_file ("$copath/B/foo", "foobar");
$svk->update ('-r', 3, "$copath/A");
$svk->add ("$copath/B");
$svk->commit ('-m', 'blah', "$copath/B");
ok ($xd->{checkout}->get (__"$corpath/A")->{revision} == 3,
    'checkout optimzation respects existing state');

$svk->update ($copath);
$svk->mkdir ('-m', 'commit message here', '//A/update-check-only');
is_output($svk, 'update', ['-C', $copath], [
        "Syncing //(/) in $corpath to 7.",
        __("A   $copath/A/update-check-only"), ]);

is_output($svk, 'update', ['-C', '-s', $copath], [
        "Syncing //(/) in $corpath to 7.",
        __("A   $copath/A/update-check-only"), ]);
for (['-m'], ['-s', '-m']) {
    is_output($svk, 'update', ['-C', @$_, $copath], [
            '--check-only cannot be used in conjunction with --merge.', ]);
}

for (['-s'], ['-m'], ['-s', '-m']) {
    is_output($svk, 'update', ['-r', 3, @$_, $copath], [
            '--revision cannot be used in conjunction with --sync or --merge.', ]);
}

1;
