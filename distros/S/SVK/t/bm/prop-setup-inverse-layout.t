#!/usr/bin/perl -w
# This test for inverse layout of trunk and/or branches
# <clkao> so, dev.catalyst.perl.org/repos/Catalyst/
# <clkao> it has trunk/[PROJNAME], branches/[PROJNAME]/* etc
use strict;
use SVK::Test;
plan tests => 11;
our $output;

my ($xd, $svk) = build_test('test');

$svk->mkdir('-p', -m => 'trunk in project benshi', '/test/trunk/benshi');
$svk->mkdir('-p', -m => 'branches in project benshi', '/test/branches/benshi');
$svk->mkdir('-p', -m => 'tags in project benshi', '/test/tags/benshi');
$svk->mkdir(-m => 'trunk in project sushi', '/test/trunk/sushi');
$svk->mkdir(-m => 'branches in project sushi', '/test/branches/sushi');
# no tags for project sushi
my $tree = create_basic_tree($xd, '/test/trunk/benshi/');
$tree = create_basic_tree($xd, '/test/trunk/sushi/');

my $depot = $xd->find_depot('test');
my $uri = uri($depot->repospath);

my ($copath, $corpath) = get_copath('prop-setup-inverse');

$svk->mirror('//mirror/nomeans', $uri);
$svk->sync('//mirror/nomeans');

$answer = ['', '','',''];
$svk->branch('--setup', '//mirror/nomeans/trunk/sushi');

is_output ($svk, 'branch', ['--list', '//mirror/nomeans/trunk/sushi'], []);

is_output ($svk, 'branch', ['--list', '--project', 'sushi', '//mirror/nomeans'], []);
is_output_like ($svk, 'branch', ['--create','bar','--project','sushi'],
    qr'Project branch created: bar');
is_output ($svk, 'branch', ['--list', '--project', 'sushi', '//mirror/nomeans'], ['bar']);
$answer = [''];
is_output ($svk, 'branch', ['--setup', '//mirror/nomeans/trunk/sushi'],
    ['Project already set in properties: //mirror/nomeans/trunk/sushi']);

chdir($copath);

is_output ($svk, 'branch', ['--list', '//mirror/nomeans/trunk/benshi'], []);
$answer = ['n','','','','',''];
is_output_like ($svk, 'branch', ['--setup', '//mirror/nomeans/trunk/benshi'],
    qr/Project detected in specified path./);
is_output ($svk, 'branch', ['--setup', '//mirror/nomeans/trunk/benshi'],
    ['Project already set in properties: //mirror/nomeans/trunk/benshi']);
is_output_like ($svk, 'branch', ['--create','bar','--project','benshi'],
    qr'Project branch created: bar');
is_output_like ($svk, 'branch', ['--create','bar3','--project','benshi'],
    qr'Project branch created: bar');
is_output ($svk, 'branch', ['--list', '--project', 'benshi'],
    ['bar','bar3']);
