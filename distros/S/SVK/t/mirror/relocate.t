#!/usr/bin/perl -w
use strict;
use Test::More;
use SVK::Test;
use SVK::Util qw(HAS_SYMLINK);

plan(skip_all => 'symlink not supported') if !HAS_SYMLINK;
plan tests => 5;

my ($xd, $svk) = build_test('test', 'test2');
my ($copath, $corpath) = get_copath();

our $output;

my $tree = create_basic_tree ($xd, '/test/');

my ($srepospath, $spath, $srepos) = $xd->find_repos('/test/A', 1);
my ($srepospath2) = $xd->find_repos('/test2/A', 1);
rmtree [$srepospath2];
symlink($srepospath, $srepospath2);

my $uri = uri($srepospath.($spath eq '/' ? '' : $spath));
my $uri2 = uri($srepospath);

is_output($svk, mirror => ['//m', $uri],
          ["Mirror initialized.  Run svk sync //m to start mirroring."]);

is_output($svk, 'mirror', ['--relocate', '//m', "$uri2/B"],
	  ["Can't relocate: mirror subdirectory changed from /A to /B."]);

is_output($svk, 'mirror', ['--relocate', '//m', "$uri2/A"],
	  ['Mirror relocated.']);

is_output($svk, 'mirror', ['--relocate','//bogus_mirror', "$uri2/B"],
      ['//bogus_mirror is not a mirrored path.']);

is_output($svk, 'mirror', ['--relocate','//m/bogus_mirror', "$uri2/B"],
      ['//m/bogus_mirror is inside a mirrored path.']);
