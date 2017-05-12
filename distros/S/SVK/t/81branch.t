#!/usr/bin/perl -w
use strict;
use Test::More tests => 6;
use SVK::Test;
use File::Path;

my ($xd, $svk) = build_test('test');
our $output;
$svk->mkdir(-m => 'trunk', '/test/trunk');
$svk->mkdir(-m => 'trunk', '/test/branches');
$svk->mkdir(-m => 'trunk', '/test/tags');
my $tree = create_basic_tree($xd, '/test/trunk');

my $depot = $xd->find_depot('test');
my $uri = uri($depot->repospath);

$svk->mirror('//mirror/MyProject', $uri);
$svk->sync('//mirror/MyProject');

my ($copath, $corpath) = get_copath ('MyProject');
$svk->checkout('//mirror/MyProject/trunk',$copath);
chdir($copath);

is_output_like ($svk, 'branch', ['--create', 'feature/foo'], qr'Project branch created: feature/foo');
$svk->branch('--list');
is_output_like ($svk, 'branch',
    ['--create', 'feature/bar', '--switch-to'],
    qr'Project branch created: feature/bar');
is_output_like ($svk, 'info', [], qr'Depot Path: //mirror/MyProject/branches/feature/bar');

#is_output_like ($svk, 'switch', ['//mirror/MyProject/trunk'], qr'.*');
#$svk->info();
#warn $output;

is_output_like ($svk, 'branch', ['--create', 'feature/foobar', '--switch-to', '--local'],
    qr'Project branch created: feature/foobar \(in local\)');
is_output_like ($svk, 'info', [], qr'Copied From: /mirror/MyProject/trunk, Rev. \d+');

is_output_like ($svk, 'branch', ['--create', '--tag', 'bar'], qr'Project tag created: bar');
