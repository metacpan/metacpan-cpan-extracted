#!usr/bin/perl -w
use strict;
use Test::More;
use SVK::Test;
plan_svm tests => 20;
our ($output, $answer);
# build another tree to be mirrored ourself
my ($xd, $svk) = build_test('test');
$svk->mkdir (-m => 'trunk', '/test/trunk');
my $tree = create_basic_tree ($xd, '/test/trunk');

$svk->copy (-pm => 'local', '/test/trunk' => '/test/local');

$svk->copy (-pm => 'here', '/test/trunk' => '/test/branches/hate');
$svk->copy (-pm => 'here', '/test/trunk' => '/test/branches/hate2');

my ($srepospath, $spath, $srepos) =$xd->find_repos ('/test/trunk', 1);
my $uri = uri($srepospath);

is_output ($svk, 'sync', ['-a'], []);
is_output ($svk, 'sync', ['-a', '//'], []);

$svk->mirror ('//m-main/trunk', $uri.'/trunk');
$svk->mirror ('//m-main/local', $uri.'/local');
$svk->mirror ('//m-hate', $uri.'/branches/hate');

is_output ($svk, 'sync', ['-a'],
          ["Starting to synchronize //m-hate",
           "Syncing $uri/branches/hate",
           "Retrieving log information from 1 to 6",
           "Committed revision 4 from revision 5.",
           "Starting to synchronize //m-main/local",
           "Syncing $uri/local",
           "Retrieving log information from 1 to 6",
           "Committed revision 5 from revision 4.",
           "Starting to synchronize //m-main/trunk",
           "Syncing $uri/trunk",
           "Retrieving log information from 1 to 6",
           "Committed revision 6 from revision 1.",
           "Committed revision 7 from revision 2.",
           "Committed revision 8 from revision 3."]);

$svk->mirror ('--detach', '//m-main/trunk');
$svk->mirror ('--detach', '//m-main/local');
$svk->rm (-m => '', '//m-main');

$svk->mirror ('--detach', '//m-hate');
$svk->rm (-m => '', '//m-hate');

$svk->mirror ('//m-main/trunk', $uri.'/trunk');
$svk->mirror ('//m-main/local', $uri.'/local');
$svk->mirror ('//m-hate', $uri.'/branches/hate');

is_output ($svk, 'sync', ['-a', '//'],
          ["Starting to synchronize //m-hate",
           "Syncing $uri/branches/hate",
           "Retrieving log information from 1 to 6",
           "Committed revision 17 from revision 5.",
           "Starting to synchronize //m-main/local",
           "Syncing $uri/local",
           "Retrieving log information from 1 to 6",
           "Committed revision 18 from revision 4.",
           "Starting to synchronize //m-main/trunk",
           "Syncing $uri/trunk",
           "Retrieving log information from 1 to 6",
           "Committed revision 19 from revision 1.",
           "Committed revision 20 from revision 2.",
           "Committed revision 21 from revision 3."]);

$svk->mirror ('--detach', '//m-main/trunk');
$svk->mirror ('--detach', '//m-main/local');
$svk->rm (-m => '', '//m-main');

$svk->mirror ('--detach', '//m-hate');
$svk->rm (-m => '', '//m-hate');

$svk->mirror ('//m-main/trunk', $uri.'/trunk');
$svk->mirror ('//m-main/local', $uri.'/local');
$svk->mirror ('//m-hate', $uri.'/branches/hate');

is_output ($svk, 'sync', ['-a', '//m-main'],
          ["Starting to synchronize //m-main/local",
           "Syncing $uri/local",
           "Retrieving log information from 1 to 6",
           "Committed revision 30 from revision 4.",
           "Starting to synchronize //m-main/trunk",
           "Syncing $uri/trunk",
           "Retrieving log information from 1 to 6",
           "Committed revision 31 from revision 1.",
           "Committed revision 32 from revision 2.",
           "Committed revision 33 from revision 3."]);

$svk->mirror ('--detach', '//m-main/trunk');
$svk->mirror ('--detach', '//m-main/local');
$svk->rm (-m => '', '//m-main');

$svk->mirror ('--detach', '//m-hate');
$svk->rm (-m => '', '//m-hate');

$svk->mirror ('//m-main/trunk', $uri.'/trunk');
$svk->mirror ('//m-main/local', $uri.'/local');
$svk->mirror ('//m-hate', $uri.'/branches/hate');

is_output ($svk, 'sync', ['-a', '//m-main/trunk'],
          ["Starting to synchronize //m-main/trunk",
           "Syncing $uri/trunk",
           "Retrieving log information from 1 to 6",
           "Committed revision 42 from revision 1.",
           "Committed revision 43 from revision 2.",
           "Committed revision 44 from revision 3."]);

$svk->mirror ('--detach', '//m-main/trunk');
$svk->mirror ('--detach', '//m-main/local');
$svk->rm (-m => '', '//m-main');

$svk->mirror ('--detach', '//m-hate');
$svk->rm (-m => '', '//m-hate');

$svk->mirror ('//m-main/trunk', $uri.'/trunk');
$svk->mirror ('//m-main/local', $uri.'/local');
$svk->mirror ('//m-hate', $uri.'/branches/hate');

is_output ($svk, 'sync', ['-a', '//m-invalid'],
          ["no mirrors found underneath //m-invalid"]);
is_output ($svk, 'sync', ['-a', '/clkao/is/a/lazy/bugger/says/sky'],
          ["/clkao/is/a/lazy/bugger/says/sky does not contain a valid depotname"]);

is_output ($svk, 'sync', ['-a', 'really_invalid'],
          ["really_invalid does not contain a valid depotname"]);


$svk->mkdir (-m => 'trunk', '//trunk');
my ($srepospath2, $spath2, $srepos2) =$xd->find_repos ('//trunk', 1);
my $uri2 = uri($srepospath2);

is_output ($svk, 'sync', ['-a', 'test'], []); 
is_output ($svk, 'sync', ['-a', '/test'], []);
is_output ($svk, 'sync', ['-a', '/test/'], []);

TODO: {
local $TODO = 'fixme';
is_output ($svk, 'sync', ['-a', 'test/m-default'],
          ["test/m-default does not contain a valid depotname"]);
}
is_output ($svk, 'sync', ['-a', '/test/m-default'], 
          ["no mirrors found underneath /test/m-default"]);
is_output ($svk, 'sync', ['-a', '/test/m-default/'], 
          ["no mirrors found underneath /test/m-default/"]);

$svk->mirror ('/test/m-default', $uri2.'/trunk');

is_output ($svk, 'sync', ['-a', 'test'],
          ["Starting to synchronize /test/m-default",
           "Syncing $uri2/trunk",
           "Retrieving log information from 1 to 53",
           "Committed revision 8 from revision 53."]);

$svk->mirror ('--detach', '//test/m-default');
$svk->rm (-m => '', '/test/m-default');
$svk->mirror ('/test/m-default', $uri2.'/trunk');

is_output ($svk, 'sync', ['-a', '/test'],
          ["Starting to synchronize /test/m-default",
           "Syncing $uri2/trunk",
           "Retrieving log information from 1 to 53",
           "Committed revision 12 from revision 53."]);

$svk->mirror ('--detach', '//test/m-default');
$svk->rm (-m => '', '/test/m-default');
$svk->mirror ('/test/m-default', $uri2.'/trunk');

is_output ($svk, 'sync', ['-a', '/test/'],
          ["Starting to synchronize /test/m-default",
           "Syncing $uri2/trunk",
           "Retrieving log information from 1 to 53",
           "Committed revision 16 from revision 53."]);

$svk->mirror ('--detach', '//test/m-default');
$svk->rm (-m => '', '/test/m-default');
$svk->mirror ('/test/m-default', $uri2.'/trunk');

$svk->mirror ('--detach', '//m-main/trunk');
$svk->mirror ('--detach', '//m-main/local');
$svk->rm (-m => '', '//m-main');

$svk->mirror ('--detach', '//m-hate');
$svk->rm (-m => '', '//m-hate');

$svk->mirror ('//m-main/trunk', $uri.'/trunk');
$svk->mirror ('//m-main/local', $uri.'/local');
$svk->mirror ('//m-hate', $uri.'/branches/hate');

is_output ($svk, 'sync', ['-a', 'test', '//'],
          ["Starting to synchronize /test/m-default",
           "Syncing $uri2/trunk",
           "Retrieving log information from 1 to 61",
           "Committed revision 20 from revision 53.",
           "Starting to synchronize //m-hate",
           "Syncing $uri/branches/hate",
           "Retrieving log information from 1 to 20",
           "Committed revision 62 from revision 5.",
           "Starting to synchronize //m-main/local",
           "Syncing $uri/local",
           "Retrieving log information from 1 to 20",
           "Committed revision 63 from revision 4.",
           "Starting to synchronize //m-main/trunk",
           "Syncing $uri/trunk",
           "Retrieving log information from 1 to 20",
           "Committed revision 64 from revision 1.",
           "Committed revision 65 from revision 2.",
           "Committed revision 66 from revision 3."]);

$svk->mirror ('--detach', '//test/m-default');
$svk->rm (-m => '', '/test/m-default');
$svk->mirror ('/test/m-default', $uri2.'/trunk');

$svk->mirror ('--detach', '//m-main/trunk');
$svk->mirror ('--detach', '//m-main/local');
$svk->rm (-m => '', '//m-main');

$svk->mirror ('--detach', '//m-hate');
$svk->rm (-m => '', '//m-hate');

$svk->mirror ('//m-main/trunk', $uri.'/trunk');
$svk->mirror ('//m-main/local', $uri.'/local');
$svk->mirror ('//m-hate', $uri.'/branches/hate');

is_output ($svk, 'sync', ['-a'],
           ["Starting to synchronize //m-hate",
            "Syncing $uri/branches/hate",
            "Retrieving log information from 1 to 23",
            "Committed revision 75 from revision 5.",
            "Starting to synchronize //m-main/local",
            "Syncing $uri/local",
            "Retrieving log information from 1 to 23",
            "Committed revision 76 from revision 4.",
            "Starting to synchronize //m-main/trunk",
            "Syncing $uri/trunk",
            "Retrieving log information from 1 to 23",
            "Committed revision 77 from revision 1.",
            "Committed revision 78 from revision 2.",
            "Committed revision 79 from revision 3.",
            "Starting to synchronize /test/m-default",
            "Syncing $uri2/trunk",
            "Retrieving log information from 1 to 79",
            "Committed revision 24 from revision 53."]);



1;
