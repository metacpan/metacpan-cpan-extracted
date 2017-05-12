#!/usr/bin/perl -w
use strict;
use Test::More;
use SVK::Test;
eval { require SVN::Mirror; 1 } or plan skip_all => 'require SVN::Mirror';
plan tests => 2;

my ($xd, $svk) = build_test('test');

our $output;

$svk->mkdir(-pm => 'init', '/test/i/a/trunk/ac');
my $tree = create_basic_tree ($xd, '/test/i/a/trunk/ac');
$svk->mkdir(-pm => 'prepare to reorg', '/test/i/a/ac');
$svk->mv(-pm => 'reorg', '/test/i/a/trunk/ac' => '/test/i/a/ac/trunk');
$svk->rm(-pm => 'remove old trunk', '/test/i/a/trunk');
$svk->mkdir(-pm => 'some other things', '/test/i/a/useless');
create_basic_tree ($xd, '/test/i/a/useless');
$svk->mv(-pm => 'to toplevel', '/test/i/a' => '/test/a');

$svk->cp(-pm => 'to toplevel', '/test/a/ac/trunk' => '/test/a/ac/branches/baz');

my ($copath, $corpath) = get_copath();

$svk->checkout('/test/a/ac/trunk', $copath);

append_file("$corpath/B/fe", "moose\n");
$svk->ci(-m => 'some changes', $copath);

my ($srepospath, $spath, $srepos) = $xd->find_repos ('/test/a/ac', 1);
my $uri = uri($srepospath.($spath eq '/' ? '' : $spath));

$svk->mi('//mirror/proj', $uri);

is_output($svk, 'sync', ['//mirror/proj'],
          ["Syncing $uri",
           'Retrieving log information from 1 to 11',
           'Committed revision 2 from revision 9.',
           'Committed revision 3 from revision 10.',
           'Committed revision 4 from revision 11.',
       ]);

is_ancestor($svk, "//mirror/proj/branches/baz", "/mirror/proj/trunk", 2);

