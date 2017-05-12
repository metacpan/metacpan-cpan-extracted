#!/usr/bin/perl -w
use strict;
use SVK::Test;
plan tests => 5;
our $output;

# build another tree to be mirrored ourself
my ($xd, $svk) = build_test('test');

my $tree = create_basic_tree ($xd, '/test/');
my $pool = SVN::Pool->new_default;

my ($copath, $corpath) = get_copath ('smerge-anchor');
my ($scopath, $scorpath) = get_copath ('smerge-anchor-source');

my ($srepospath, $spath, $srepos) = $xd->find_repos ('/test/', 1);
my $depot = $xd->find_depot('');
my $repos = $depot->repos;

$svk->mirror ('//m', uri($srepospath).($spath eq '/' ? '' : $spath));
$svk->sync ('//m');

$svk->copy ('-m', 'branch', '//m/A', '//l');

$svk->checkout ('/test/', $scopath);
append_file ("$scopath/A/be", "modified on trunk\n");
$svk->commit ('-m', 'commit on trunk', $scopath);
$svk->checkout ('//l', $copath);
append_file ("$copath/Q/qu", "modified on local branch\n");
$svk->commit ('-m', 'commit on local branch', $copath);

$svk->sync ('//m');

$svk->smerge ('-m', 'simple smerge from source', '//m/A', '//l');
my ($suuid, $srev) = ($srepos->fs->get_uuid, $srepos->fs->youngest_rev);
$svk->update ($copath);
is_deeply (($xd->create_path_object
			     ( copath_anchor => $corpath,
			       xd => $xd,
			       repos => $repos,
			       path => '/l',
			       revision => $repos->fs->youngest_rev,
				)->root->node_proplist('/l')),
	   {'svk:merge' => "$suuid:/A:$srev"},
	   'simple smerge from source');

append_file ("$scopath/A/be", "more on trunk\n");
$svk->commit ('-m', 'commit on trunk', $scopath);
$svk->sync ('//m');

is_output_like ($svk, 'smerge', ['-m', 'simple smerge from source again', '//m/A', '//l'],
		qr|base /m/A:6|);
my ($uuid, $rev) = ($repos->fs->get_uuid, $repos->fs->youngest_rev);
is_output_like ($svk, 'smerge', ['-m', 'simple smerge from local', '//l', '//m/A'],
		qr|base /m/A:8|);

is_deeply ((SVK::Path->real_new
			     ({ depot => $depot,
			       path => '/m/A',
			       revision => $repos->fs->youngest_rev,
			      })->root->node_proplist('/m/A')),
	   { 'svk:merge' => $uuid.':/l:9'},
	   'simple smerge back to source');
is_output_like ($svk, 'smerge', ['-m', 'mergedown', '//m/A', '//l'],
		qr|Empty merge\.|);
