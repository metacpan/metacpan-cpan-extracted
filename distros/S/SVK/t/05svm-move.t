#!/usr/bin/perl -w
use strict;
use Test::More;

use SVK::Test;
eval { require SVN::Mirror; 1 } or plan skip_all => 'require SVN::Mirror';
plan tests => 9;
our $output;
# build another tree to be mirrored ourself
my ($xd, $svk) = build_test('mv_test');
my $tree = create_basic_tree ($xd, '/mv_test/');
my ($test_repospath, $test_a_path, $test_repos) = $xd->find_repos ('/mv_test/A', 1);

my $uri = uri($test_repospath);
$svk->mirror ('//mv/m', $uri.($test_a_path eq '/' ? '' : $test_a_path));
is_output ($svk, 'propget', ['svm:mirror', '//'], ['/mv/m', '']);

$svk->move ('-m', 'moving mirrored path', '//mv/m', '//mv/m2');
is_output ($svk, 'propget', ['svm:mirror', '//'], ['/mv/m2', '']);

TODO: {
    local $TODO = "Update the svm:mirror property when moving mirrored paths";
    $svk->copy ('-m', 'copying mirrored path', '//mv/m', '//mv/m-C');
    is_output ($svk, 'propget', ['svm:mirror', '//'], ['/mv/m', '/mv/m-C']);

    $svk->copy ('-m', 'copying tree containing mirrored path', '//mv', '//mv-C');
    is_output ($svk, 'propget', ['svm:mirror', '//'], ['/mv/m', '/mv/m-C', '/mv-C/m', '/mv-C/m-C']);


    $svk->move ('-m', 'moving tree containing mirrored path', '//mv-C', '//mv2');
    is_output ($svk, 'propget', ['svm:mirror', '//'], ['/mv/m', '/mv/m2', '/mv2/m', '/mv2/m-C']);


    $svk->remove ('-m', 'removing mirrored path', '//mv2/m');
    is_output ($svk, 'propget', ['svm:mirror', '//'], ['/mv/m', '/mv/m2', '/mv2/m']);

    $svk->remove ('-m', 'removing tree containing mirrored path', '//mv');
    is_output ($svk, 'propget', ['svm:mirror', '//'], ['/mv2/m']);
}

TODO: {
    local $TODO = "Duplicate mirror metadata onto the new headrev when after moving a mirror";

    # Whereas the preceding tests ensure that the svm:mirror property is
    # correctly managed, this test is to ensure that mirror metadata is
    # transferred to the destination's revprops... the detach will fail,
    # believing the path to not be a mirror, if this isn't the case.
    is_output ($svk, 'mirror', ['-d', '//mv2/m-C'], 
        [qr'Committed revision \d+\.', 
         "Mirror path '//mv2/m-C' detached."]);
    is_output ($svk, 'propget', ['svm:mirror', '//'], []);
}
