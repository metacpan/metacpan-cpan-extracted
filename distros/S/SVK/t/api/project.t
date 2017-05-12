#!/usr/bin/perl -w
use strict;
use SVK::Test;
plan tests => 5;
our $output;

use_ok('SVK::Project');

my ($xd, $svk) = build_test('test');

$svk->mkdir(-m => 'trunk', '/test/trunk');
$svk->mkdir(-m => 'trunk', '/test/branches');
$svk->mkdir(-m => 'trunk', '/test/tags');
my $tree = create_basic_tree($xd, '/test/trunk');

my $depot = $xd->find_depot('test');
my $uri = uri($depot->repospath);

$svk->mirror('//mirror/MyProject', $uri);
$svk->sync('//mirror/MyProject');

my $proj = SVK::Project->new(
    {   name            => 'MyProject',
        depot           => $xd->find_depot(''),
        trunk           => '/mirror/MyProject/trunk',
        branch_location => '/mirror/MyProject/branches',
        tag_location    => '/mirror/MyProject/tags',
        local_root      => '/local/MyProject',
    });

isa_ok($proj, 'SVK::Project');

is_deeply($proj->branches, [], 'no branches yet');

$svk->cp(-m => 'branch Foo', '//mirror/MyProject/trunk', '//mirror/MyProject/branches/Foo');

is_deeply($proj->branches, [['Foo','']], 'found 1 branch');

$svk->cp(-pm => 'feature branch Bar', '//mirror/MyProject/trunk', '//mirror/MyProject/branches/feature/Bar');

is_deeply($proj->branches, [['Foo', ''], ['feature/Bar','']], 'found deep branches');
