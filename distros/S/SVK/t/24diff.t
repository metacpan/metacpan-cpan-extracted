#!/usr/bin/perl -w
use Test::More tests => 36;
use strict;
use SVK::Test;
our $output;
my ($xd, $svk) = build_test();
my ($copath, $corpath) = get_copath ('diff');
my ($repospath, undef, $repos) = $xd->find_repos ('//', 1);
$svk->checkout ('//', $copath);
is_output_like ($svk, 'diff', [], qr'not a checkout path');
chdir ($copath);
mkdir ('A');
overwrite_file ("A/foo", "foobar\nfnord\n");
overwrite_file ("A/bar", "foobar\n");
overwrite_file ("A/nor", "foobar\n");
$svk->add ('A');
$svk->commit ('-m', 'init');

overwrite_file ("A/binary", "foobar\nfnord\n");
$svk->add ('A/binary');
$svk->propset ('svn:mime-type', 'image/png', 'A/binary');
is_output ($svk, 'diff', ['//asdf-non'],
	   ['Revision required.']);
is_output ($svk, 'diff', ['//asdf-non', 'A/binary'],
	   ['path //asdf-non does not exist.']);
is_output ($svk, 'diff', ['A/binary', '//asdf-non'],
	   ['Invalid arguments.']);
is_output ($svk, 'diff', ['//asdf-non', '//'],
	   ['path //asdf-non does not exist.']);
is_output ($svk, 'diff', [],
           ['=== A/binary',
            '==================================================================',
            'Cannot display: file marked as a binary type.',
            '',
            'Property changes on: A/binary',
            '___________________________________________________________________',
            'Name: svn:mime-type',
            ' +image/png',
	    '']);
overwrite_file ("A/foo", "foobar\nnewline\nfnord\n");
overwrite_file ("A/bar", "foobar\nnewline\n");
overwrite_file ("A/baz", "foobar\n");
$svk->add ('A/baz');
$svk->rm ('A/nor');
$svk->commit ('-m', 'some modification');
overwrite_file ("A/foo", "foobar\nnewline\nfnord\nmorenewline\n");
is_output ($svk, 'diff', [],
	   ['=== A/foo',
	    '==================================================================',
	    "--- A/foo\t(revision 2)",
	    "+++ A/foo\t(local)",
	    '@@ -1,3 +1,4 @@',
	    ' foobar',
	    ' newline',
	    ' fnord',
	    '+morenewline',], 'diff - checkout dir');

is_output ($svk, 'diff', ['A/foo'],
	  [__('=== A/foo'),
	   '==================================================================',
	   __("--- A/foo\t(revision 2)"),
	   __("+++ A/foo\t(local)"),
	   '@@ -1,3 +1,4 @@',
	   ' foobar',
	   ' newline',
	   ' fnord',
	   '+morenewline'], 'diff - checkout file');
my $r12output = ['=== A/foo',
		 '==================================================================',
		 "--- A/foo\t(revision 1)",
		 "+++ A/foo\t(revision 2)",
		 '@@ -1,2 +1,3 @@',
		 ' foobar',
		 '+newline',
		 ' fnord',
		 '=== A/bar',
		 '==================================================================',
		 "--- A/bar\t(revision 1)",
		 "+++ A/bar\t(revision 2)",
		 '@@ -1 +1,2 @@',
		 ' foobar',
		 '+newline',
                 '=== A/binary',
                 '==================================================================',
                 'Cannot display: file marked as a binary type.',
                 '',
                 'Property changes on: A/binary',
                 '___________________________________________________________________',
                 'Name: svn:mime-type',
                 ' +image/png',
                 '',
		 '=== A/baz',
		 '==================================================================',
		 "--- A/baz\t(revision 1)",
		 "+++ A/baz\t(revision 2)",
		 '@@ -0,0 +1 @@',
		 '+foobar',
		 '=== A/nor',
		 '==================================================================',
		 "--- A/nor\t(revision 1)",
		 "+++ A/nor\t(revision 2)",
		 '@@ -1 +0,0 @@',
		 '-foobar'];
is_sorted_output ($svk, 'diff', ['-r1:2'], $r12output, 'diff - rN:M copath');
is_sorted_output ($svk, 'diff', ['-c2'], $r12output);
is_sorted_output ($svk, 'diff', ['-r1', '-r2'], $r12output, 'diff - rN:M copath');
is_sorted_output ($svk, 'diff', ['-r1:2', '//'], $r12output, 'diff - rN:M depotdir');
is_output ($svk, 'diff', ['-r1:2', '//A/foo'],
	   ['=== foo',
	    '==================================================================',
	    "--- foo\t(revision 1)",
	    "+++ foo\t(revision 2)",
	    '@@ -1,2 +1,3 @@',
	    ' foobar',
	    '+newline',
	    ' fnord'], 'diff - rN:M depotfile');
is_output ($svk, 'diff', ['-c2', '//A/foo'],
	   ['=== foo',
	    '==================================================================',
	    "--- foo\t(revision 1)",
	    "+++ foo\t(revision 2)",
	    '@@ -1,2 +1,3 @@',
	    ' foobar',
	    '+newline',
	    ' fnord'], 'diff - rN:M depotfile');
$svk->cp ('-m', 'copy', '-r1', '//A', '//B');

is_output ($svk, 'diff', ['//A', '//B'],
	   ['=== foo',
	    '==================================================================',
	    "--- foo\t(/A)\t(revision 3)",
	    "+++ foo\t(/B)\t(revision 3)",
	    '@@ -1,3 +1,2 @@',
	    ' foobar',
	    '-newline',
	    ' fnord',
	    '=== bar',
	    '==================================================================',
	    "--- bar\t(/A)\t(revision 3)",
	    "+++ bar\t(/B)\t(revision 3)",
	    '@@ -1,2 +1 @@',
	    ' foobar',
	    '-newline',
	    '=== nor',
	    '==================================================================',
	    "--- nor\t(/A)\t(revision 3)",
	    "+++ nor\t(/B)\t(revision 3)",
	    '@@ -0,0 +1 @@',
	    '+foobar',
            '=== binary',
            '==================================================================',
            'Cannot display: file marked as a binary type.',
            '',
            'Property changes on: binary',
            '___________________________________________________________________',
            'Name: svn:mime-type',
            ' -image/png',
            '',
	    '=== baz',
	    '==================================================================',
	    "--- baz\t(/A)\t(revision 3)",
	    "+++ baz\t(/B)\t(revision 3)",
	    '@@ -1 +0,0 @@',
	    '-foobar'], 'diff - depotdir depotdir');

is_output ($svk, 'diff', ['-r1'],
	   ['=== A/bar',
	    '==================================================================',
	    "--- A/bar\t(revision 1)",
	    "+++ A/bar\t(local)",
	    '@@ -1 +1,2 @@',
	    ' foobar',
	    '+newline',
	    '=== A/foo',
	    '==================================================================',
	    "--- A/foo\t(revision 1)",
	    "+++ A/foo\t(local)",
	    '@@ -1,2 +1,4 @@',
	    ' foobar',
	    '+newline',
	    ' fnord',
	    '+morenewline',
	    '=== A/nor',
	    '==================================================================',
	    "--- A/nor\t(revision 1)",
	    "+++ A/nor\t(local)",
	    '@@ -1 +0,0 @@',
	    '-foobar',
	    '=== A/baz',
	    '==================================================================',
	    "--- A/baz\t(revision 1)",
	    "+++ A/baz\t(local)",
	    '@@ -0,0 +1 @@',
	    '+foobar',
            '=== A/binary',
            '==================================================================',
            'Cannot display: file marked as a binary type.',
            '',
            'Property changes on: A/binary',
            '___________________________________________________________________',
            'Name: svn:mime-type',
            ' +image/png',
	    '',], 'diff - rN copath (changed)');
TODO: {
local $TODO = 'figure out wth this is about';
is_sorted_output ($svk, 'diff', ['-sr1:2', '//A', $corpath],
	   ['A   A',
	    'A   A/foo',
	    'A   A/bar',
	    'A   A/binary',
	    'A   A/baz',
	    'D   bar',
	    'D   foo',
	    'D   nor']);
}

is_sorted_output ($svk, 'diff', ['-sr1:2'],
	   ['M   A/foo',
	    'M   A/bar',
	    'A   A/binary',
	    'A   A/baz',
	    'D   A/nor']);

is_output ($svk, 'diff', ['-sr1'],
	   ['M   A/bar',
	    'M   A/foo',
	    'A   A/baz',
	    'A   A/binary',
	    'D   A/nor']);

$svk->revert ('-R', 'A');
is_output ($svk, 'diff', ['-r1'],
	   ['=== A/bar',
	    '==================================================================',
	    "--- A/bar\t(revision 1)",
	    "+++ A/bar\t(local)",
	    '@@ -1 +1,2 @@',
	    ' foobar',
	    '+newline',
	    '=== A/foo',
	    '==================================================================',
	    "--- A/foo\t(revision 1)",
	    "+++ A/foo\t(local)",
	    '@@ -1,2 +1,3 @@',
	    ' foobar',
	    '+newline',
	    ' fnord',
	    '=== A/nor',
	    '==================================================================',
	    "--- A/nor\t(revision 1)",
	    "+++ A/nor\t(local)",
	    '@@ -1 +0,0 @@',
	    '-foobar',
	    '=== A/baz',
	    '==================================================================',
	    "--- A/baz\t(revision 1)",
	    "+++ A/baz\t(local)",
	    '@@ -0,0 +1 @@',
	    '+foobar',
            '=== A/binary',
            '==================================================================',
            'Cannot display: file marked as a binary type.',
            '',
            'Property changes on: A/binary',
            '___________________________________________________________________',
            'Name: svn:mime-type',
            ' +image/png',
	    ''], 'diff - rN copath (unchanged)');
$svk->update ('-r1', 'A');
overwrite_file ("A/coonly", "foobar\n");
$svk->add ('A/coonly');
is_output ($svk, 'diff', ['//B', 'A'],
	   ['=== coonly',
	    '==================================================================',
	    "--- coonly\t(/B)\t(revision 3)",
	    "+++ coonly\t(/A)\t(local)",
	    '@@ -0,0 +1 @@',
	    '+foobar'],
	   'diff - depopath copath');

$svk->revert ('-R', 'A');

$svk->update ('-r2', 'A/bar');
append_file ("A/foo", "mixed\n");
append_file ("A/bar", "mixed\n");

is_output ($svk, 'diff', ['A/foo', 'A/bar'],
	   [__('=== A/foo'),
	    '==================================================================',
	    __("--- A/foo\t(revision 1)"),
	    __("+++ A/foo\t(local)"),
	    '@@ -1,2 +1,3 @@',
	    ' foobar',
	    ' fnord',
	    '+mixed',
	    __('=== A/bar'),
	    '==================================================================',
	    __("--- A/bar\t(revision 2)"),
	    __("+++ A/bar\t(local)"),
	    '@@ -1,2 +1,3 @@',
	    ' foobar',
	    ' newline',
	    '+mixed']);

$svk->revert ('-R', 'A');
unlink ('A/coonly');
$svk->update ;
$svk->rm ('A');

is_sorted_output ($svk, 'diff', [],
	   ["=== A\t(deleted directory)",
	    '==================================================================',
            '=== A/foo',
	    '==================================================================',
	    "--- A/foo\t(revision 3)",
	    "+++ A/foo\t(local)",
	    '@@ -1,3 +0,0 @@',
	    '-foobar',
	    '-newline',
	    '-fnord',
	    '=== A/bar',
	    '==================================================================',
	    "--- A/bar\t(revision 3)",
	    "+++ A/bar\t(local)",
	    '@@ -1,2 +0,0 @@',
	    '-foobar',
	    '-newline',
            '=== A/binary',
            '==================================================================',
            'Cannot display: file marked as a binary type.',
            '',
            'Property changes on: A/binary',
            '___________________________________________________________________',
            'Name: svn:mime-type',
            ' -image/png',
            '',
	    '=== A/baz',
	    '==================================================================',
	    "--- A/baz\t(revision 3)",
	    "+++ A/baz\t(local)",
	    '@@ -1 +0,0 @@',
	    '-foobar'], 'recursive delete_entry');

$svk->revert ('-R', 'A');
$svk->update;
$svk->propset ('svn:mime-type', 'image/jpg', 'A/binary');
is_output ($svk, 'diff', [],
           ['',
            'Property changes on: A/binary',
            '___________________________________________________________________',
            'Name: svn:mime-type',
            ' -image/png',
            ' +image/jpg',
	    '']);
$svk->commit('-m', 'Property changes for A/binary.');
is_output ($svk, 'diff', ['-r4:3'],
           ['',
            'Property changes on: A/binary',
            '___________________________________________________________________',
            'Name: svn:mime-type',
            ' -image/jpg',
            ' +image/png',
	    '']);
is_output ($svk, 'diff', ['-c-4'],
           ['',
            'Property changes on: A/binary',
            '___________________________________________________________________',
            'Name: svn:mime-type',
            ' -image/jpg',
            ' +image/png',
	    '']);

# test with expanding copies
$svk->cp ('-m', 'blah', '//B', '//A/B-cp');
$svk->cp ('//A', 'C');
append_file ("C/foo", "copied and modified on C\n");
TODO: {
local $TODO = 'path sep issues on win32' if IS_WIN32;
is_output($svk, 'diff', ['C'],
	  [__("=== C\t(new directory; copied from ").'/A@5)',
	    '==================================================================',
           __("=== C/foo\t(copied from ").'/A/foo@5)',
	   '==================================================================',
	   __("--- C/foo\t(revision 4)"),
	   __("+++ C/foo\t(local)"),
	   '@@ -1,3 +1,4 @@',
	   ' foobar',
	   ' newline',
	   ' fnord',
	   '+copied and modified on C',
	  ]);
is_output ($svk, 'diff', [-X => 'C'],
	   ["=== C\t(new directory)",
	    '==================================================================',
            __("=== C/B-cp\t(new directory)"),
	    '==================================================================',
            __('=== C/B-cp/bar'),
	    '==================================================================',
	    __("--- C/B-cp/bar\t(revision 4)"),
	    __("+++ C/B-cp/bar\t(local)"),
	    '@@ -0,0 +1 @@',
	    '+foobar',
	    __('=== C/B-cp/foo'),
	    '==================================================================',
	    __("--- C/B-cp/foo\t(revision 4)"),
	    __("+++ C/B-cp/foo\t(local)"),
	    '@@ -0,0 +1,2 @@',
	    '+foobar',
	    '+fnord',
	    __('=== C/B-cp/nor'),
	    '==================================================================',
	    __("--- C/B-cp/nor\t(revision 4)"),
	    __("+++ C/B-cp/nor\t(local)"),
	    '@@ -0,0 +1 @@',
	    '+foobar',
	    __('=== C/bar'),
	    '==================================================================',
	    __("--- C/bar\t(revision 4)"),
	    __("+++ C/bar\t(local)"),
	    '@@ -0,0 +1,2 @@',
	    '+foobar',
	    '+newline',
	    __('=== C/baz'),
	    '==================================================================',
	    __("--- C/baz\t(revision 4)"),
	    __("+++ C/baz\t(local)"),
	    '@@ -0,0 +1 @@',
	    '+foobar',
            __('=== C/binary'),
            '==================================================================',
            'Cannot display: file marked as a binary type.',
            '',
            __('Property changes on: C/binary'),
            '___________________________________________________________________',
            'Name: svn:mime-type',
            ' +image/jpg',
            '',
	    __('=== C/foo'),
	    '==================================================================',
	    __("--- C/foo\t(revision 4)"),
	    __("+++ C/foo\t(local)"),
	    '@@ -0,0 +1,4 @@',
	    '+foobar',
	    '+newline',
	    '+fnord',
	    '+copied and modified on C']);

is_output ($svk, 'diff', ['--non-recursive', '-X', 'C'],
	   ["=== C\t(new directory)",
	    '==================================================================',
            __("=== C/B-cp\t(new directory)"),
	    '==================================================================',
            __('=== C/bar'),
	    '==================================================================',
	    __("--- C/bar\t(revision 4)"),
	    __("+++ C/bar\t(local)"),
	    '@@ -0,0 +1,2 @@',
	    '+foobar',
	    '+newline',
	    __('=== C/baz'),
	    '==================================================================',
	    __("--- C/baz\t(revision 4)"),
	    __("+++ C/baz\t(local)"),
	    '@@ -0,0 +1 @@',
	    '+foobar',
            __('=== C/binary'),
            '==================================================================',
            'Cannot display: file marked as a binary type.',
            '',
            __('Property changes on: C/binary'),
            '___________________________________________________________________',
            'Name: svn:mime-type',
            ' +image/jpg',
            '',
	    __('=== C/foo'),
	    '==================================================================',
	    __("--- C/foo\t(revision 4)"),
	    __("+++ C/foo\t(local)"),
	    '@@ -0,0 +1,4 @@',
	    '+foobar',
	    '+newline',
	    '+fnord',
	    '+copied and modified on C']);
}
$svk->revert ('-R', '.');
$svk->resolved ('-R', '.');
$svk->update;

overwrite_file ("A/newfile", "foobar\nnewline\nfnord\n");
$svk->add ('A/newfile');
$svk->ps ('anewprop', 'value', 'A');
$svk->ps ('anewprop', 'value', 'A/newfile');
$svk->commit ('-m', 'some props'); # r6
my $r6diffs =
	   ['=== A/newfile',
	    '==================================================================',
	    "--- A/newfile\t(revision 5)",
	    "+++ A/newfile\t(local)",
	    '@@ -0,0 +1,3 @@',
	    '+foobar',
	    '+newline',
	    '+fnord',
	    '',
	    'Property changes on: A/newfile',
	    '___________________________________________________________________',
	    'Name: anewprop',
	    ' +value',
	    '', '',
	    'Property changes on: A',
	    '___________________________________________________________________',
	    'Name: anewprop',
	    ' +value',
	    '',
	   ];
is_output ($svk, 'diff', ['-r5'],
	   $r6diffs);

overwrite_file ("A/newfile", "");
$svk->st;
is_output ($svk, 'diff', ['A/newfile'],
	   [__('=== A/newfile'),
	    '==================================================================',
	    __("--- A/newfile\t(revision 6)"),
	    __("+++ A/newfile\t(local)"),
	    '@@ -1,3 +0,0 @@',
	    '-foobar',
	    '-newline',
	    '-fnord'
	   ]);

# I'm not sure I really *like* the fact that this produces no output, but 
# that's consistent with svn and there's no obvious thing to print
unlink ('A/newfile');
is_output ($svk, 'diff', ['A/newfile'],
	   [  ]);

for (@$r6diffs)
{
	s{A/?}{};
	s{revision 5}{revision 4};
	s{local}{revision 6};
}
is_output ($svk, 'diff', ['-N', '--revision', '4:6', '//A'],
	   $r6diffs);

$svk->mkdir(-pm => 'foo', '//fnord/baz/C');
$svk->mkdir(-pm => 'foo', '//fnord/baz/D');
$svk->ps(-m => 'bar', 'fnord' => 'value', '//fnord/baz/D');
is_output($svk, 'diff', ['-r7:9', '//fnord/baz'],
	  ["=== D\t(new directory)",
          '==================================================================',
           '', 'Property changes on: D',
	   '___________________________________________________________________',
	   'Name: fnord',
	   ' +value', '']);
is_output_like($svk, 'merge', ['-r7:9', '//fnord/baz', '//fnord/baz/C', '-lm', 'baz', '-P-'],
	       qr/Property changes on: D.*SVK PATCH BLOCK/s);


is_output($svk, 'diff', ['//A/baz', '//B/foo'],
	  ['=== baz',
	   '==================================================================',
	   "--- baz\t(/A/baz)\t(revision 9)",
	   "+++ baz\t(/B/foo)\t(revision 9)", # XXX: this is wrong
	   '@@ -1 +1,2 @@',
	   ' foobar',
	   '+fnord',
	  ]);
