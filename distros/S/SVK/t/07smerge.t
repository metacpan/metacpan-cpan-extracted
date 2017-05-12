#!/usr/bin/perl -w
use strict;
use SVK::Test;
plan tests => 31;
our $output;

# build another tree to be mirrored ourself
my ($xd, $svk) = build_test('test', 'client2');

my $tree = create_basic_tree ($xd, '/test/');
my $pool = SVN::Pool->new_default;

my ($copath, $corpath) = get_copath('smerge');
my ($scopath, $scorpath) = get_copath('smerge-source');

my ($srepospath, $spath, $srepos) = $xd->find_repos ('/test/A', 1);
my $depot = $xd->find_depot('');
my $repos = $depot->repos;
my ($nrepospath, undef, $nrepos) = $xd->find_repos ('/client2/', 1);

my $uri = uri($srepospath);
$svk->mirror ('//m', $uri.($spath eq '/' ? '' : $spath));

$svk->sync ('//m');

$svk->copy ('-m', 'branch', '//m', '//l');

$svk->checkout ('/test/', $scopath);
append_file ("$scopath/A/be", "modified on trunk\n");
$svk->commit ('-m', 'commit on trunk', $scopath);
$svk->checkout ('//l', $copath);
append_file ("$copath/Q/qu", "modified on local branch\n");
$svk->commit ('-m', 'commit on local branch', $copath);

$svk->sync ('//m');

my ($suuid, $srev) = ($srepos->fs->get_uuid, $srepos->fs->youngest_rev);

is_output ($svk, 'smerge', ['-c6', '//m/be', '//l/be'],
	   ["Can't merge with specified revisions with smart merge."]);

is_output ($svk, 'smerge', ['-C', '//m/be', '//l/be'],
	   ['Auto-merging (2, 6) /m/be to /l/be (base /m/be:2).',
	    'U   be',
	    "New merge ticket: $suuid:/A/be:3"]);
TODO: {
local $TODO = 'better target checks';

is_output ($svk, 'smerge', ['-C', '//m/be', '//l/'],
	   ["Can't merge different types of nodes"]);

}

is_output_like ($svk, 'smerge', ['-C', '//l', '//'],
		qr/contains mirror/);

is_output_like ($svk, 'smerge', ['-C', '//m/Q', '//l/'],
		qr/find merge base/);

is_output ($svk, 'smerge', ['-C', '//m', '//l'],
	   ['Auto-merging (3, 6) /m to /l (base /m:3).',
	    'U   be',
	    'New merge ticket: '.$suuid.':/A:3'], 'check merge down');

my ($uuid, $rev) = ($repos->fs->get_uuid, $repos->fs->youngest_rev);
is_output ($svk, 'smerge', ['-C', '//l', '//m'],
	   ['Auto-merging (0, 5) /l to /m (base /m:3).',
	    "Checking locally against mirror source $uri/A.",
	    'U   Q/qu',
	    "New merge ticket: $uuid:/l:5"], 'check merge up');

is_output ($svk, 'smerge', ['-C', '//l', '//m/'],
	   ['Auto-merging (0, 5) /l to /m (base /m:3).',
	    "Checking locally against mirror source $uri/A.",
	    'U   Q/qu',
	    "New merge ticket: $uuid:/l:5"], 'check merge up');

$svk->merge ('-a', '-m', 'simple smerge from source', '//m', '//l');
$srev = $srepos->fs->youngest_rev;
$svk->update ($copath);
is_deeply (($xd->create_path_object
			     ( copath_anchor => $corpath,
			       xd => $xd,
			       repos => $repos,
			       path => '/l',
			       revision => $repos->fs->youngest_rev,
			     )->root->node_proplist('/l')),
	   {'svk:merge' => "$suuid:/A:$srev",
	    'svm:source' => uri($srepos->path).'!/A',
	    'svm:uuid' => $suuid }, 'simple smerge from source');
$rev = $repos->fs->youngest_rev;

is_output ($svk, 'smerge', ['-m', 'simple smerge from local', '//l', '//m'],
	   ['Auto-merging (0, 7) /l to /m (base /m:6).',
	    "Merging back to mirror source $uri/A.",
	    'U   Q/qu',
	    "New merge ticket: $uuid:/l:7",
	    'Merge back committed as revision 4.',
	    "Syncing $uri/A",
	    'Retrieving log information from 4 to 4',
	    'Committed revision 8 from revision 4.'], 'merge up');
$svk->sync ('//m');

is_deeply ((SVK::Path->real_new
			     ({ depot => $depot,
				path => '/m',
				revision => $repos->fs->youngest_rev,
			       })->root->node_proplist('/m')),
	   {'svk:merge' => "$uuid:/l:$rev",
	    'svm:source' => uri($srepos->path).'!/A',
	    'svm:uuid' => $suuid },
	   'simple smerge back to source');

$svk->smerge ('-C', '//m', '//l');
is_output ($svk, 'smerge', ['-m', 'mergedown', '//m', '//l'],
	   ['Auto-merging (6, 8) /m to /l (base */m:6).',
	    'Empty merge.'], 'merge down - empty');
$svk->pl ('-v', '//m');
is_output ($svk, 'smerge', ['-m', 'mergedown', '//m', '//l'],
	   ['Auto-merging (6, 8) /m to /l (base */m:6).',
	    'Empty merge.'], 'merge up - empty');
$svk->update ($scopath);
append_file ("$scopath/A/be", "more modification on trunk\n");
mkdir "$scopath/A/newdir";
mkdir "$scopath/A/newdir2";
overwrite_file ("$scopath/A/newdir/deepnewfile", "new file added on source\n");
overwrite_file ("$scopath/A/newfile", "new file added on source\n");
overwrite_file ("$scopath/A/newfile2", "new file added on source\n");
$svk->add (map {"$scopath/A/$_"} qw/newdir newdir2 newfile newfile2/);
append_file ("$scopath/A/Q/qz", "file appened on source\n");
$svk->propset ("bzz", "newprop", "$scopath/A/Q/qz");
$svk->propset ("bzz", "newprop", "$scopath/A/Q/qu");
$svk->commit ('-m', 'commit on trunk', $scopath);
$svk->sync ('//m');

$svk->update ($copath);
overwrite_file ("$copath/newfile", "new file added on source\n");
overwrite_file ("$copath/newfile2", "new file added on source\nalso on local\n");
mkdir ("$copath/newdir");
$svk->add ("$copath/newfile");
append_file ("$copath/be", "modification on local\n");
append_file ("$copath/Q/qu", "modified on local\n");
$svk->rm ("$copath/Q/qz");
$svk->commit ('-m', 'commit on local', $copath);
is_output ($svk, 'smerge', ['-C', '//m', '//l'],
	   ['Auto-merging (6, 9) /m to /l (base /l:7).',
	    ' U  Q/qu',
	    '    Q/qz - skipped',
	    'C   be',
	    'A   newdir',
	    'A   newdir/deepnewfile',
	    'g   newfile',
	    'A   newdir2',
	    'A   newfile2',
	    "New merge ticket: $suuid:/A:5",
	    'Empty merge.', '1 conflict found.'],
	   'smerge - added file collision');
$svk->smerge ('-C', '//m', $copath);
is_output ($svk, 'smerge', ['//m', $copath],
	   ['Auto-merging (6, 9) /m to /l (base /l:7).',
	    __" U  $copath/Q/qu",
	    __"    $copath/Q/qz - skipped",
	    __"C   $copath/be",
	    __"    $copath/newdir - skipped",
	    __"    $copath/newdir/deepnewfile - skipped",
	    __"g   $copath/newfile",
	    __"A   $copath/newdir2",
	    __"    $copath/newfile2 - skipped",
	    "New merge ticket: $suuid:/A:5",
	    '1 conflict found.']);
$svk->revert ('-R', $copath);
# XXX: newdir is not removed after revert
rmtree ["$copath/newdir2"];
$svk->add ("$copath/newdir");
is_output ($svk, 'smerge', ['//m', $copath],
	   ['Auto-merging (6, 9) /m to /l (base /l:7).',
	    __" U  $copath/Q/qu",
	    __"    $copath/Q/qz - skipped",
	    __"C   $copath/be",
	    __"A   $copath/newdir/deepnewfile",
	    __"G   $copath/newdir",
	    __"g   $copath/newfile",
	    __"A   $copath/newdir2",
	    __"    $copath/newfile2 - skipped",
	    "New merge ticket: $suuid:/A:5",
	    '1 conflict found.'], 'scheduled dir merged with add');
is_output ($svk, 'commit', ['-m', 'commit with conflict state', $copath],
	   ["1 conflict detected. Use 'svk resolved' after resolving them."],
	   'forbid commit with conflict state');
$svk->revert ("$copath/be");
is_output ($svk, 'commit', ['-m', 'merge down committed from checkout', $copath],
	   ['Committed revision 11.']);
rmdir "$copath/newdir";
$svk->revert ('-R', $copath);
ok (-e "$copath/newdir", 'smerge to checkout - add directory');

$svk->copy ('-m', 'branch on source', '/test/A', '/test/A-cp');
$svk->ps ('-m', 'prop on A', 'blah', 'tobemerged', '/test/A');

is_output ($svk, 'mirror', ['//m-all', $uri],
	   ['Mirroring overlapping paths not supported']);
$svk->mirror ('/client2/m-all', $uri);
$svk->sync ('/client2/m-all');
$svk->smerge ('-C', '/client2/m-all/A', '/client2/m-all/A-cp');
is_output ($svk, 'smerge', ['-m', 'merge down prop only', '/client2/m-all/A', '/client2/m-all/A-cp'],
	   ['Auto-merging (6, 8) /m-all/A to /m-all/A-cp (base /m-all/A:6).',
	    "Merging back to mirror source $uri.",
	    ' U  .',
	    "New merge ticket: $suuid:/A:7",
	    'Merge back committed as revision 8.',
	    "Syncing $uri",
	    'Retrieving log information from 8 to 8',
	    'Committed revision 9 from revision 8.']);

is_output ($svk, 'smerge', ['-m', 'merge down prop only', '/client2/m-all/A', '/client2/m-all/A-cp'],
	   ['Auto-merging (8, 8) /m-all/A to /m-all/A-cp (base /m-all/A:8).',
	    'Empty merge.'], 'empty merge');

$svk->ps ('-m', 'prop on A/be', 'proponly', 'proponly', '/test/A/be');

is_output ($svk, 'smerge', ['-m', 'merge down prop only with --sync and --to', '-st', '/client2/m-all/A-cp'],
	   ["Syncing $uri",
            'Retrieving log information from 9 to 9',
            'Committed revision 10 from revision 9.',
	    'Auto-merging (8, 10) /m-all/A to /m-all/A-cp (base /m-all/A:8).',
	    "Merging back to mirror source $uri.",
	    ' U  be',
	    "New merge ticket: $suuid:/A:9",
	    'Merge back committed as revision 10.',
	    "Syncing $uri",
	    'Retrieving log information from 10 to 10',
	    'Committed revision 11 from revision 10.']);
$svk->update ($scopath);
overwrite_file ("$scopath/A/Q/qu", "on trunk\nfirst line in qu\n2nd line in qu\n");
overwrite_file ("$scopath/A-cp/Q/qu", "first line in qu\non cp branch\n2nd line in qu\n");
$svk->commit ('-m', 'commit on source', $scopath);
$svk->sync ('/client2/m-all');
is_output ($svk, 'smerge', ['-C', '/client2/m-all/A', '/client2/m-all/A-cp'],
	   ['Auto-merging (10, 12) /m-all/A to /m-all/A-cp (base /m-all/A:10).',
	    "Checking locally against mirror source $uri.",
	    'G   Q/qu',
	    "New merge ticket: $suuid:/A:11"]);


set_editor(<< 'TMP');
$_ = shift;
open _ or die $!;
@_ = ("hate\n", <_>);
close _;
unlink $_;
open _, '>', $_ or die $!;
print _ @_;
close _;
TMP

is_output ($svk, 'smerge', ['-m', 'simple text merge for mirrored', '--template', '/client2/m-all/A', '/client2/m-all/A-cp'],
	   ['Auto-merging (10, 12) /m-all/A to /m-all/A-cp (base /m-all/A:10).',
	    'Waiting for editor...',
	    "Merging back to mirror source $uri.",
	    'G   Q/qu',
	    "New merge ticket: $suuid:/A:11",
	    'Merge back committed as revision 12.',
	    "Syncing $uri",
	    'Retrieving log information from 12 to 12',
	    'Committed revision 13 from revision 12.']);
is_output_like ($svk, 'log', [-r13 => '/client2/m-all/A-cp'],
		qr'hate.*simple text's);

overwrite_file ("$copath/Q/qu", "on local\nfirst line in qu\n2nd line in qu\n");
is_output ($svk, 'commit', ['-m', 'more on local', $copath],
	   ['Committed revision 12.']);
is_output ($svk, 'smerge', ['-m', 'merge back', '//l', '//m'],
	   ['Auto-merging (7, 12) /l to /m (base /m:9).',
	    "Merging back to mirror source $uri/A.",
	    qr'Transaction is out of date.*',
	   'Please sync mirrored path /m first.']);

$svk->update ($scopath);
overwrite_file ("$scopath/A/Q/qu", "on trunk\nfirst line in qu\non cp branch\n2nd line in qu\nExtra stuff\n");
$svk->commit ('-m', 'commit on source', $scopath);

$svk->sync ('-a', '/client2/');
is_output ($svk, 'smerge', ['-C', '/client2/m-all/A-cp', '/client2/m-all/A'],
	   ['Auto-merging (0, 13) /m-all/A-cp to /m-all/A (base /m-all/A:12).',
	    "Checking locally against mirror source $uri.",
	    'G   Q/qu',
	    "New merge ticket: $suuid:/A-cp:12"]);


is_output ($svk, 'smerge', ['-l', '-m', 'some message', '--template', '/client2/m-all/A-cp', '/client2/m-all/A'],
	   ['Auto-merging (0, 13) /m-all/A-cp to /m-all/A (base /m-all/A:12).',
	    'Waiting for editor...',
	    "Merging back to mirror source $uri.",
	    'G   Q/qu',
	    "New merge ticket: $suuid:/A-cp:12",
	    "Merge back committed as revision 14.",
	    "Syncing $uri",
	    'Retrieving log information from 14 to 14',
	    'Committed revision 15 from revision 14.']);

is_output_like ($svk, 'log', [-r15 => '/client2/m-all/A'],
		qr'hate.*
		   some\ message.*
		   (orig\ r6).*
		   branch\ on\ source.*
		   (orig\ r11).*
		   commit\ on\ source'sx);
