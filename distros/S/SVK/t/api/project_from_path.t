#!/usr/bin/perl -w
use strict;
use SVK::Test;
use Data::Dumper; # diag
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

# When the path is mirror path
my $proj = SVK::Project->create_from_path($xd->find_depot(''), '//mirror/MyProject');
isa_ok($proj, 'SVK::Project');

my $proj2 = SVK::Project->new(
    {   name            => 'MyProject',
        depot           => $xd->find_depot(''),
        trunk           => '/mirror/MyProject/trunk',
        branch_location => '/mirror/MyProject/branches',
        tag_location    => '/mirror/MyProject/tags',
        local_root      => '/local/MyProject',
    });

is_deeply ($proj, $proj2, 'The same project?');

my $proj3 = SVK::Project->create_from_path($xd->find_depot(''), '//mirror/MyProject/trunk/B/S/Q');
isa_ok($proj3, 'SVK::Project');
is_deeply ($proj3, $proj2, 'The same project?');
