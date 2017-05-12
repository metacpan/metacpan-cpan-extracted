#!/usr/bin/perl -w
use strict;
use SVK::Test;
plan tests => 16;
our $output;

my ($xd, $svk) = build_test('test');

$svk->mkdir(-m => 'trunk', '/test/trunk');
$svk->mkdir(-m => 'trunk', '/test/branches');
$svk->mkdir(-m => 'trunk', '/test/tags');
my $tree = create_basic_tree($xd, '/test/trunk');

my $depot = $xd->find_depot('test');
my $uri = uri($depot->repospath);

$svk->mirror('//mirror/MyProject', $uri);
$svk->sync('//mirror/MyProject');

$svk->cp(-m => 'branch Foo', '//mirror/MyProject/trunk', '//mirror/MyProject/branches/Foo');

my ($copath, $corpath) = get_copath('basic-trunk');

$svk->checkout('//mirror/MyProject/trunk', $copath);

chdir($copath);

is_output($svk, 'br', ['-l'],
          ['Foo'], 'default to guess project of current checkout');

is_output($svk, 'br', ['-l', '//mirror/MyProject'],
          ['Foo']);

is_output_like ($svk, 'branch', ['--create', 'feature/foo', '--switch-to'], qr'Project branch created: feature/foo');

is_output($svk, 'br', ['-l', '//mirror/MyProject'],
          ['Foo','feature/foo']);

is_output($svk, 'br', ['-l'],
          ['Foo','feature/foo']);

is_output_like ($svk, 'info', [],
    qr'Depot Path: //mirror/MyProject/branches/feature/foo', 'Switched');

$svk->branch('--switch', 'trunk'); # switch to trunk
is_output_like ($svk, 'info', [],
    qr'Depot Path: //mirror/MyProject/trunk', 'Switch to trunk');

$svk->branch('--switch-to', 'feature/foo'); # switch to foo
is_output_like ($svk, 'info', [],
    qr'Depot Path: //mirror/MyProject/branches/feature/foo', 'Switch to feature/foo branch');

$svk->branch('--switch-to', '//mirror/MyProject/trunk'); # switch to trunk via //mirror/MyProject/trunk
is_output_like ($svk, 'info', [],
    qr'Depot Path: //mirror/MyProject/branches/feature/foo', 'Switch to trunk');

$svk->branch('--switch-to', '//mirror/MyProject/branches/feature/foo'); # switch to foo
is_output_like ($svk, 'info', [],
    qr'Depot Path: //mirror/MyProject/branches/feature/foo', 'Switch to feature/foo branch');

is_output_like ($svk, 'branch', ['--create', 'feature/foobar', '--local'],
    qr'Project branch created: feature/foobar \(in local\)');

is_output($svk, 'br', ['-l', '--local', '//mirror/MyProject'],
          ['feature/foobar']);

is_output($svk, 'br', ['-l', '--all', '//mirror/MyProject'],
          ['Foo', 'feature/foo', 'feature/foobar (in local)']);

is_output_like ($svk, 'branch', ['--create', 'tagA', '--tag'],
    qr'Project tag created: tagA');

is_output($svk, 'br', ['-l', '--all', '//mirror/MyProject'],
          ['Foo', 'feature/foo', 'tagA (tags)', 'feature/foobar (in local)']);

is_output($svk, 'br', ['-l', '--tag', '//mirror/MyProject'],
          ['tagA']);
