#!/usr/bin/perl -w
use strict;
use SVK::Test;
plan tests => 20;

our $output;
my ($xd, $svk) = build_test('test');
my ($copath, $corpath) = get_copath ('log');
my ($repospath, undef, $repos) = $xd->find_repos ('//', 1);
$svk->checkout ('//', $copath);
chdir ($copath);
mkdir ('A');
overwrite_file ("A/foo", "foobar\nfnord\n");
overwrite_file ("A/bar", "foobar\n");
$svk->add ('A');
$svk->commit ('-m', 'init');
$svk->cp ('//A/foo', 'foo-cp');
$svk->cp ('//A/bar', 'bar-cp');
overwrite_file ("foo-cp", "foobar\nfnord\nnewline");
$svk->ps ('mmm', 'xxx', 'A/foo');
$svk->commit ('-m', 'cp and ps');
is_output_like ($svk, 'log', [],
		qr|r2.*cp and ps.*r1.*init|s);
is_output ($svk, 'log', ['--quiet'],
	   [qr|-+|, qr|r2:.*|, qr|-+|, qr|r1:.*|, qr|-+|]);
$svk->pd ('--revprop', '-r' => 2 , 'svn:author');

is_output_like ($svk, 'log', ['-v'],
		qr|
r2.*\QChanged paths:
   M /A/foo
  A  /bar-cp (from /A/bar:1)
  M  /foo-cp (from /A/foo:1)\E.*
r1.*\Q  A  /A
  A  /A/bar
  A  /A/foo\E|s);

$svk->mirror ('/test/A', uri("$repospath/A"));
$svk->sync ('/test/A');

is_output_like ($svk, 'log', ['-v', '-l1', '/test/'],
		qr/\Qr3 (orig r2):  (no author)\E/);
is_output_like ($svk, 'log', ['-v', '-l1', '/test/A/'],
		qr/\Qr3 (orig r2):  (no author)\E/);
is_output ($svk, 'log', ['-q', '--verbose', '--limit', '1' ,'/test/A/'],
	   [qr|-+|,
	    qr|\Qr3 (orig r2):  (no author)\E|,
	    'Changed paths:',
	    '   M /A/foo',
	    qr|-+|]);
is_output_like ($svk, 'log', ['-v', '-r2@', '/test/A/'],
		qr/\Qr3 (orig r2):  (no author)\E/);

is_output ($svk, 'log', ['-v', '-r5@', '/test/A/'],
	   ["Can't find local revision for 5 on /A."]);

is_output ($svk, 'log', [-r => 16384, -l1 =>'/test/A'],
	   ['Revision too large, show log from 3.',
	    qr|-+|, qr|r3.*orig r2|, '',
	    qr|cp and ps|,
	    qr|-+|]);
is_output ($svk, 'log', [-r => 'asdf', '/test/A'],
	   ['asdf is not a number.']);
$svk->update ('A');
$svk->rm (-m => 'bye', '//A');

is_output_like ($svk, 'log', [-l1 => 'A'],
		qr|r2.*cp and ps|s);
is_output_like ($svk, 'desc', [], qr'SYNOPSIS');
is_output_like ($svk, 'desc', [2],
		qr|r2.*cp and ps.*Property changes on: A/foo.*--- foo-cp\t\(revision 1\)|s);
is_output_like ($svk, 'desc', ['r2'],
		qr|r2.*cp and ps.*Property changes on: A/foo.*--- foo-cp\t\(revision 1\)|s);
is_output_like ($svk, 'desc', ['r2@', '/test/A'],
		qr|r3 \(orig r2\).*cp and ps.*Property changes on: A/foo|s);
$svk->mv (-m => 'mv', '//foo-cp', '//foo-mv');
$svk->rm (-m => 'rm', '//bar-cp');
$svk->cp (-m => 'cp', '//bar-cp@4', '//bar-notmv');
is_output ($svk, 'log', ['//foo-mv'],
	   [qr|-+|, qr|r4.*|, '', qr|mv|,
            qr|-+|, qr|r2.*|, '', qr|cp and ps|s,
            qr|-+|]);
is_output ($svk, 'log', ['//bar-notmv'],
	   [qr|-+|, qr|r6.*|, '', qr|cp|,
            qr|-+|]);
is_output ($svk, 'log', ['//bar-notmv', '--cross'],
	   [qr|-+|, qr|r6.*|, '', qr|cp|,
	    qr|-+|, qr|r2.*|, '', qr|cp and ps|,
	    qr|-+|, qr|r1.*|, '', qr|init|,
            qr|-+|]);

# If you specify a copath (or implicitly specify . ) to svk desc which
# happens to be of an older revision than the revision you specify, it
# should work anyway.
$svk->up('-r1');
is_output_like ($svk, 'desc', ['r2'],
		qr|r2.*cp and ps.*Property changes on: A/foo.*--- foo-cp\t\(revision 1\)|s);

is_output($svk, 'desc', ['r7'],
          [
           "Depot // has no revision 7",
          ]);
