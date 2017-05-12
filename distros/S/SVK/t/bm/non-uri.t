#!/usr/bin/perl -w
use strict;
use SVK::Test;
plan tests => 5;
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

my ($copath, $corpath) = get_copath('non-uri');

$svk->checkout('//mirror/MyProject/trunk', $copath);

chdir($copath);

is_output($svk, 'br', ['-l', $uri],
          ['Foo'], 'default to guess project of current checkout');

is_output($svk, 'br', ['-l', '//mirror/MyProject', $uri],
          ['Foo']);
my $fakeuri = 'http://localhost/non/exists';

is_output($svk, 'br', ['-l', $fakeuri],
          ['URI not allowed here: New mirror site not allowed here.'],
	  'non-existent URI should alarm.');

is_output($svk, 'br', ['-l', '//mirror/MyProject', $fakeuri],
          ['URI not allowed here: New mirror site not allowed here.']);

is_output($svk, 'br', ['--setup', $fakeuri],
          ["Target can't be URI."]);
