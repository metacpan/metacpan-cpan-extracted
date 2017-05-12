#!/usr/bin/perl -w
use Test::More tests => 27;
use strict;
use SVK::Test;
our $output;
my ($xd, $svk) = build_test();
my ($copath, $corpath) = get_copath ('status');
my ($repospath, undef, $repos) = $xd->find_repos ('//', 1);
$svk->checkout ('//', $copath);
chdir ($copath);
mkdir ('A');
mkdir ('A/deep');
overwrite_file ("A/foo", "foobar");
overwrite_file ("A/foo~", "foobar");
overwrite_file ("A/bar", "foobar");
overwrite_file ("A/deep/baz", "foobar");

is_output_like ($svk, 'status', ['--help'], qr'SYNOPSIS');

is_output ($svk, 'status', [],
	   ['?   A'], 'status - unknown');
is_output ($svk, 'status', ['-q'],
           [],      '  -q');
is_output ($svk, 'status', ['--quiet'],
           [],      '  --quiet');

$svk->add ('-N', 'A');
$svk->add ('A/foo');
is_output ($svk, 'status', [],
	   [ map __($_), 'A   A', '?   A/bar', '?   A/deep', 'A   A/foo'], 'status - unknown');
chdir('A');
is_output ($svk, 'status', ['../A'],
	   [ map __($_), 'A   ../A', '?   ../A/bar', '?   ../A/deep', 'A   ../A/foo'], 'status - unknown');
chdir('..');
$svk->add ('A/deep');
$svk->commit ('-m', 'add a bunch for files');
overwrite_file ("A/foo", "fnord");
overwrite_file ("A/another", "fnord");
$svk->add ('A/another');
$svk->ps ('someprop', 'somevalue', 'A/foo', 'A/another');
is_output ($svk, 'status', [],
	   [ map __($_), 'MM  A/foo', 'A   A/another', '?   A/bar'], 'status - modified file and prop');
$svk->commit ('-m', 'some modification');
overwrite_file ("A/foo", "fnord\nmore");
$svk->commit ('-m', 'more modification');
rmtree (['A/deep']);
unlink ('A/another');
is_output ($svk, 'status', [],
	   [ map __($_), '!   A/another', '!   A/deep', '?   A/bar'], 'status - absent file and dir');
$svk->revert ('-R', 'A');
unlink ('A/deep/baz');
$svk->status;
$svk->delete ('A/deep');
$svk->delete ('A/another');
is_output ($svk, 'status', [],
	   [ map __($_), '?   A/bar', 'D   A/another', 'D   A/deep', 'D   A/deep/baz'], 'status - deleted file and dir');

is_output ($svk, 'status', ['-q'],
	   [ map __($_), 'D   A/another', 'D   A/deep', 'D   A/deep/baz'], '  -q');

$svk->revert ('-R', 'A');
overwrite_file ("A/foo", "foo");
$svk->merge ('-r1:2', '//A', 'A');
is_output ($svk, 'status', [],
	   [ map __($_), 'C   A/foo', '?   A/bar'], 'status - conflict');
$svk->resolved ('A/foo');
$svk->revert ('-R', 'A');
overwrite_file ("A/foo", "foo");
$svk->merge ('-r2:3', '//A', 'A');
is_output ($svk, 'status', [],
	   [ map __($_), 'C   A/foo', '?   A/bar'], 'status - conflict');
$svk->revert ('A/foo');
$svk->ps ('someprop', 'somevalue', '.');
$svk->ps ('someprop', 'somevalue', 'A');
chdir ('A');
is_output ($svk, 'status', [],
	   [ map __($_), '?   bar', ' M  .']);
chdir ('..');
$svk->revert ('-R', '.');
$svk->ps ('someprop', 'somevalue', 'A/deep/baz');
is_output ($svk, 'status', ['A/deep'],
	   [__(' M  A/deep/baz')], 'prop only');
$svk->revert ('-R', '.');
rmtree (['A/deep']);
overwrite_file ("A/deep", "dir replaced with file.\n");
unlink('A/another');
mkdir('A/another');

is_output ($svk, 'status', [],
	   [map __($_),
	    '?   A/bar',
	    '~   A/another',
	    '~   A/deep'], 'obstructure');

is_output ($svk, 'status', [],
	   [map __($_),
	    '?   A/bar',
	    '~   A/another',
	    '~   A/deep'], 'obstructure - make sure it is not signatured');

# XXX: revert should hint about moving away obstructed entries
$svk->revert ('-R', '.');
# fixup
rmtree (['A/another']);
$svk->revert ('-R', '.');

is_output($svk, 'st', [], [__('?   A/bar'),
			   __('~   A/deep')]);

$svk->mkdir ('-p', '-m', ' ', '//A/deeper/deeper');
$svk->up;
append_file ("A/deeper/deeper/baz", "baz");
$svk->add ("A/deeper/deeper/baz");
$svk->rm ('-m', 'delete', '//A/deeper');
overwrite_file ("A/deeper/deeper/baz", "boo");
$svk->up;
chdir ('A');
TODO: {
local $TODO = 'target_condensed and report being .';
is_output ($svk, 'status', ['deeper/deeper'],
	   [__('C   deeper'),
	    __('C   deeper/deeper'),
	    __('C   deeper/deeper/baz')
	   ]);
}
chdir ('..');
$svk->revert ('-R', 'A');
$svk->add ('A/deeper');
$svk->ps ('foo', 'bar', 'A/deeper');
$svk->ps ('bar', 'ksf', 'A/deeper');
is_output ($svk, 'st', [],
	   [map {__($_)}
	    ('?   A/bar',
	     'A   A/deeper',
	     'A   A/deeper/deeper',
	     'A   A/deeper/deeper/baz',
	     '~   A/deep')]);
my $cowner = $ENV{USER};
$svk->ps ('-r2', '--revprop', 'svn:author', 'user2');
$svk->ps ('-r3', '--revprop', 'svn:author', 'user3');
$svk->ps ('-r5', '--revprop', 'svn:author', 'user5');
is_output ($svk, 'st', ['--verbose'],
	   [map {__($_)}
	    ('           5        2 user2        A/another',
	     '           5        3 user3        A/foo',
	     '?                                  A/bar',
	     'A          0       ?   ?           A/deeper',
	     'A          0       ?   ?           A/deeper/deeper',
	     'A          0       ?   ?           A/deeper/deeper/baz',
	     '~         ?        ?   ?           A/deep',
	     '           5        5 user5        A',
	     '           5        5 user5        .')]);
overwrite_file ("A/bar.o", "binary stuff\n");
is_output ($svk, 'status', ['--no-ignore'],
	   [map {__($_)}
	    ('?   A/bar',
	     'I   A/bar.o',
	     'A   A/deeper',
	     'A   A/deeper/deeper',
	     'A   A/deeper/deeper/baz',
	     'I   A/foo~',
	     '~   A/deep')]);
$svk->ps ('svn:ignore', 'test', 'A/deeper');
overwrite_file ("A/deeper/test", "fnord\nmore");
is_output ($svk, 'status', ['--quiet', '--no-ignore'],
	   [map {__($_)}
	    ('I   A/bar.o',
	     'A   A/deeper',
	     'A   A/deeper/deeper',
	     'A   A/deeper/deeper/baz',
	     'I   A/deeper/test',
	     'I   A/foo~',
	     '~   A/deep')]);
is_output ($svk, 'status', ['--non-recursive', 'A'],
	   [map {__($_)}
	    ('?   A/bar',
	     'A   A/deeper',
	     '~   A/deep')]);
$svk->ci ('A/deeper', '-m', 'added deeper');
$svk->ps ('-r6', '--revprop', 'svn:author', 'user6');
$svk->cp ('A/deeper', 'A/deeper-copy');
is_output ($svk, 'st', ['--verbose'],
	   [map {__($_)}
	    ('           6        2 user2        A/another',
	     '           6        6 user6        A/deeper/deeper/baz',
	     '           6        6 user6        A/deeper/deeper',
	     '           6        6 user6        A/deeper',
	     '           6        3 user3        A/foo',
	     '?                                  A/bar',
	     'A +        -        6 user6        A/deeper-copy',
	     '  +        -        6 user6        A/deeper-copy/deeper/baz',
	     '  +        -        6 user6        A/deeper-copy/deeper',
	     '~         ?        ?   ?           A/deep',
	     '           6        6 user6        A',
	     '           6        6 user6        .')]);
append_file ("A/deeper-copy/deeper/baz", "more baz");
is_output ($svk, 'st', ['--verbose'],
	   [map {__($_)}
	    ('           6        2 user2        A/another',
	     '           6        6 user6        A/deeper/deeper/baz',
	     '           6        6 user6        A/deeper/deeper',
	     '           6        6 user6        A/deeper',
	     '           6        3 user3        A/foo',
	     '?                                  A/bar',
	     'A +        -        6 user6        A/deeper-copy',
	     'M +        -        6 user6        A/deeper-copy/deeper/baz',
	     '  +        -        6 user6        A/deeper-copy/deeper',
	     '~         ?        ?   ?           A/deep',
	     '           6        6 user6        A',
	     '           6        6 user6        .')]);

overwrite_file("A/deeper-copy/bah", "ignore me");
is_output($svk, 'ignore', ["A/bar", "A/deeper-copy/bah"],
          [   ' M  A',
           __(' M  A/deeper-copy')]);
$svk->diff('A');

is_output($svk, 'status', ['--verbose'],
          [map {__($_)}
           ('           6        2 user2        A/another',
            '           6        6 user6        A/deeper/deeper/baz',
            '           6        6 user6        A/deeper/deeper',
            '           6        6 user6        A/deeper',
            '           6        3 user3        A/foo',
            'A +        -        6 user6        A/deeper-copy',
            'M +        -        6 user6        A/deeper-copy/deeper/baz',
            '  +        -        6 user6        A/deeper-copy/deeper',
            '~         ?        ?   ?           A/deep',
            ' M         6        6 user6        A',
            '           6        6 user6        .')]);
