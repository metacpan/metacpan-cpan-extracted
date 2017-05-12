#!/usr/bin/perl -w
use strict;
use SVK::Test;
plan tests => 13;
our $output;

my ($xd, $svk) = build_test('test');

$svk->mkdir(-m => 'trunk', '/test/trunk');
$svk->mkdir(-m => 'trunk', '/test/branches');
$svk->mkdir(-m => 'trunk', '/test/tags');
my $tree = create_basic_tree($xd, '/test/trunk');

my $depot = $xd->find_depot('test');
my $uri = uri($depot->repospath);

$svk->mirror('//MyProject', $uri);
$svk->sync('//MyProject');

$svk->cp(-m => 'branch Foo', '//MyProject/trunk', '//MyProject/branches/Foo');

my ($copath, $corpath) = get_copath('bm-root-basic');

$svk->checkout('//MyProject/trunk', $copath);

chdir($copath);

is_output($svk, 'br', ['-l'],
          ['Foo'], 'default to guess project of current checkout');

is_output($svk, 'br', ['-l', '//MyProject'],
          ['Foo']);

is_output_like ($svk, 'branch', ['--create', 'feature/foo', '--switch-to'], qr'Project branch created: feature/foo');

is_output($svk, 'br', ['-l', '//MyProject'],
          ['Foo','feature/foo']);

is_output($svk, 'br', ['-l'],
          ['Foo','feature/foo']);

is_output_like ($svk, 'info', [],
    qr'Depot Path: //MyProject/branches/feature/foo', 'Switched');

$svk->branch('--switch', 'trunk'); # switch to trunk
is_output_like ($svk, 'info', [],
    qr'Depot Path: //MyProject/trunk', 'Switch to trunk');

$svk->branch('--switch-to', 'feature/foo'); # switch to foo
is_output_like ($svk, 'info', [],
    qr'Depot Path: //MyProject/branches/feature/foo', 'Switch to feature/foo branch');

$svk->branch('--switch-to', '//MyProject/trunk'); # switch to trunk via //MyProject/trunk
is_output_like ($svk, 'info', [],
    qr'Depot Path: //MyProject/branches/feature/foo', 'Switch to trunk');

$svk->branch('--switch-to', '//MyProject/branches/feature/foo'); # switch to foo
is_output_like ($svk, 'info', [],
    qr'Depot Path: //MyProject/branches/feature/foo', 'Switch to feature/foo branch');

is_output_like ($svk, 'branch', ['--create', 'feature/foobar', '--local'],
    qr'Project branch created: feature/foobar \(in local\)');

is_output($svk, 'br', ['-l', '--local', '//MyProject'],
          ['feature/foobar']);

is_output($svk, 'br', ['-l', '--all', '//MyProject'],
          ['Foo', 'feature/foo', 'feature/foobar (in local)']);

