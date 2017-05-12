#!/usr/bin/perl -w
use strict;
use SVK::Test;
plan tests => 26;

our $output;
our $answer;
our $show_prompt;
my ($xd, $svk) = build_test();
my ($copath, $corpath) = get_copath ('commit-inter-output');
my ($repospath, undef, $repos) = $xd->find_repos ('//', 1);

$svk->checkout ('//', $copath);
is_output_like ($svk, 'commit', [], qr'not a checkout path');
chdir ($copath);
mkdir ('A');
mkdir ('A/deep');
mkdir ('A/deep/la');
overwrite_file ("A/foo", "foobar\ngrab");
overwrite_file ("A/foox", "foo\nbar\n");
overwrite_file ("A/bar", "foobar\n");
overwrite_file ("A/deep/baz", "foobar");
overwrite_file ("A/deep/la/no", "foobar");
overwrite_file ("A/deep/mas", "po");
overwrite_file ("A/aj", "foobar");
overwrite_file ("A/ow", "foobar");
is_output ($svk, 'commit', ['--interactive'], ['No targets to commit.'], 'commit - no target');

$answer = [('a') x 11];
$svk->add ('A');
is_output ($svk, 'commit', ['--interactive', '-m', 'foo'],
    ['Committed revision 1.'], 'initial commit');
    
overwrite_file ("A/foo",      "alfa\nbeta\nfoobar\ngamma\ndelta");
$svk->propset('one', "multi\nline", 'A/foo');
$svk->propset('two', "", 'A/foo');

overwrite_file ("A/foox",     "pies\nfoo\nkot");
$svk->propset('three', "multi\nline\n", 'A/foox');

overwrite_file ("A/bar",      "alfa\nfoobar\nbeta");

overwrite_file ("A/deep/baz", "");
$svk->propset('four', "max", 'A/deep/baz');
$svk->propset('five', "min", 'A/deep/baz');

overwrite_file ("A/deep/la/no", "\n");
$svk->propset('six', "re\n", 'A/deep/la/no');

overwrite_file ("A/deep/mas", "ten");

$svk->propset('seven', "wol", 'A/aj');
$svk->propset('eight', "wer", 'A/aj');

$svk->propset('nine', "owy", 'A/ow');

$answer = [('a') x 18];

#our $DEBUG = 1;
$show_prompt = 1; #Begin interactive mode.

is_output ($svk, 'commit', ['--interactive', '-m', 'foo2'],
    ['Property change on A/aj',
     '___________________________________________________________________',
     'Name: eight',
     ' +wer',
     '',
     '[1/18] Property change on \'A/aj\' file requested:',
     '[a]ccept, [s]kip this change,',
     'a[c]cept, s[k]ip changes to all properties with that name > ',
     'Property change on A/aj',
     '___________________________________________________________________',
     'Name: seven',
     ' +wol',
     '',
     '[2/18] Property change on \'A/aj\' file requested:',
     '[a]ccept, [s]kip this change,',
     'a[c]cept, s[k]ip changes to all properties with that name,',
     'move to [p]revious change > ',
     "--- A/bar\t(revision 1)",
     "+++ A/bar\t(local)",
     '@@ -0 +0 @@',
     '+alfa',
     ' foobar',
     '',
     '[3/18] Modification to \'A/bar\' file:',
     '[a]ccept, [s]kip this change,',
     '[A]ccept, [S]kip the rest of changes to this file,',
     'move to [p]revious change > ',
     "--- A/bar\t(revision 1)",
     "+++ A/bar\t(local)",
     '@@ -0 +1 @@',
     ' foobar',
     '+beta',
     '\ No newline at end of file',
     '',
     '[4/18] Modification to \'A/bar\' file:',
     '[a]ccept, [s]kip this change,',
     '[A]ccept, [S]kip the rest of changes to this file,',
     'move to [p]revious change > ',
     "--- A/deep/baz\t(revision 1)",
     "+++ A/deep/baz\t(local)",
     '@@ -0 +0 @@',
     '-foobar',
     '\ No newline at end of file',
     '',
     '[5/18] Modification to \'A/deep/baz\' file:',
     '[a]ccept, [s]kip this change,',
     '[A]ccept, [S]kip the rest of changes to this file,',
     'a[c]cept, s[k]ip rest of changes to this file and its properties,',
     'move to [p]revious change > ',
     'Property change on A/deep/baz',
     '___________________________________________________________________',
     'Name: five',
     ' +min',
     '',
     '[6/18] Property change on \'A/deep/baz\' file requested:',
     '[a]ccept, [s]kip this change,',
     'a[c]cept, s[k]ip changes to all properties with that name,',
     'move to [p]revious change > ',
     'Property change on A/deep/baz',
     '___________________________________________________________________',
     'Name: four',
     ' +max',
     '',
     '[7/18] Property change on \'A/deep/baz\' file requested:',
     '[a]ccept, [s]kip this change,',
     'a[c]cept, s[k]ip changes to all properties with that name,',
     'move to [p]revious change > ',
     "--- A/deep/la/no\t(revision 1)",
     "+++ A/deep/la/no\t(local)",
     '@@ -0 +0 @@',
     '-foobar',
     '\ No newline at end of file',
     '+',
     '',
     '[8/18] Modification to \'A/deep/la/no\' file:',
     '[a]ccept, [s]kip this change,',
     '[A]ccept, [S]kip the rest of changes to this file,',
     'a[c]cept, s[k]ip rest of changes to this file and its properties,',
     'move to [p]revious change > ',
     'Property change on A/deep/la/no',
     '___________________________________________________________________',
     'Name: six',
     ' +re',
     '',
     '[9/18] Property change on \'A/deep/la/no\' file requested:',
     '[a]ccept, [s]kip this change,',
     'a[c]cept, s[k]ip changes to all properties with that name,',
     'move to [p]revious change > ',
     "--- A/deep/mas\t(revision 1)",
     "+++ A/deep/mas\t(local)",
     '@@ -0 +0 @@',
     '-po',
     '\ No newline at end of file',
     '+ten',
     '\ No newline at end of file',
     '',
     '[10/18] Modification to \'A/deep/mas\' file:',
     '[a]ccept, [s]kip this change,',
     '[A]ccept, [S]kip the rest of changes to this file,',
     'move to [p]revious change > ',
     "--- A/foo\t(revision 1)",
     "+++ A/foo\t(local)",
     '@@ -0,1 +0,2 @@',
     '+alfa',
     '+beta',
     ' foobar',
     ' grab',
     '[11/18] Modification to \'A/foo\' file:',
     '[a]ccept, [s]kip this change,',
     '[A]ccept, [S]kip the rest of changes to this file,',
     'a[c]cept, s[k]ip rest of changes to this file and its properties,',
     'move to [p]revious change > ',
     "--- A/foo\t(revision 1)",
     "+++ A/foo\t(local)",
     '@@ -0,1 +2,2 @@',
     ' foobar',
     '-grab',
     '\ No newline at end of file',
     '+gamma',
     '+delta',
     '\ No newline at end of file',
     '',
     '[12/18] Modification to \'A/foo\' file:',
     '[a]ccept, [s]kip this change,',
     '[A]ccept, [S]kip the rest of changes to this file,',
     'a[c]cept, s[k]ip rest of changes to this file and its properties,',
     'move to [p]revious change > ',
     'Property change on A/foo',
     '___________________________________________________________________',
     'Name: one',
     ' +multi',
     ' +line',
     '',
     '[13/18] Property change on \'A/foo\' file requested:',
     '[a]ccept, [s]kip this change,',
     'a[c]cept, s[k]ip changes to all properties with that name,',
     'move to [p]revious change > ',
     'Property change on A/foo',
     '___________________________________________________________________',
     'Name: two',
     ' ',
     '[14/18] Property change on \'A/foo\' file requested:',
     '[a]ccept, [s]kip this change,',
     'a[c]cept, s[k]ip changes to all properties with that name,',
     'move to [p]revious change > ',
     "--- A/foox\t(revision 1)",
     "+++ A/foox\t(local)",
     '@@ -0,1 +0,1 @@',
     '+pies',
     ' foo',
     ' bar',
     '',
     '[15/18] Modification to \'A/foox\' file:',
     '[a]ccept, [s]kip this change,',
     '[A]ccept, [S]kip the rest of changes to this file,',
     'a[c]cept, s[k]ip rest of changes to this file and its properties,',
     'move to [p]revious change > ',
     "--- A/foox\t(revision 1)",
     "+++ A/foox\t(local)",
     '@@ -0,1 +1,1 @@',
     ' foo',
     '-bar',
     '+kot',
     '\ No newline at end of file',
     '',
     '[16/18] Modification to \'A/foox\' file:',
     '[a]ccept, [s]kip this change,',
     '[A]ccept, [S]kip the rest of changes to this file,',
     'a[c]cept, s[k]ip rest of changes to this file and its properties,',
     'move to [p]revious change > ',
     'Property change on A/foox',
     '___________________________________________________________________',
     'Name: three',
     ' +multi',
     ' +line',
     '',
     '[17/18] Property change on \'A/foox\' file requested:',
     '[a]ccept, [s]kip this change,',
     'a[c]cept, s[k]ip changes to all properties with that name,',
     'move to [p]revious change > ',
     'Property change on A/ow',
     '___________________________________________________________________',
     'Name: nine',
     ' +owy',
     '',
     '[18/18] Property change on \'A/ow\' file requested:',
     '[a]ccept, [s]kip this change,',
     'a[c]cept, s[k]ip changes to all properties with that name,',
     'move to [p]revious change > ',
     'Committed revision 2.'],
    'file modifications - output');

$svk->rm("A/deep/la");
$svk->propset('one', "multi\nline", 'A/deep');

$svk->rm("A/foox");

$svk->mkdir('A/deep/tra');
$svk->propset('one', "multi\nline", 'A/deep/tra');
$svk->propset('two', "", 'A/deep/tra');

$svk->mkdir('A/deep/tra/bant');
$svk->propset('one', "multi\nline", 'A/deep/tra/bant');

$svk->mkdir('A/deep/tra/per');
$answer = [('a') x 9];
is_output ($svk, 'commit', ['--interactive', '-m', 'foo2'],
    ['',
     '[1/9] File or directory \'A/deep/la\' is marked for deletion:',
     '[a]ccept, [s]kip this change > ',
     '',
     '[2/9] Directory \'A/deep/tra\' is marked for addition:',
     '[a]ccept, [s]kip this change,',
     '[A]ccept changes to whole subdirectory,',
     'move to [p]revious change > ',
     '',
     '[3/9] Directory \'A/deep/tra/bant\' is marked for addition:',
     '[a]ccept, [s]kip this change,',
     'move to [p]revious change > ',
     'Property change on A/deep/tra/bant',
     '___________________________________________________________________',
     'Name: one',
     ' +multi',
     ' +line',
     '',
     '[4/9] Property change on \'A/deep/tra/bant\' directory requested:',
     '[a]ccept, [s]kip this change,',
     'a[c]cept, s[k]ip changes to all properties with that name,',
     'move to [p]revious change > ',
     '',
     '[5/9] Directory \'A/deep/tra/per\' is marked for addition:',
     '[a]ccept, [s]kip this change,',
     'move to [p]revious change > ',
     'Property change on A/deep/tra',
     '___________________________________________________________________',
     'Name: one',
     ' +multi',
     ' +line',
     '',
     '[6/9] Property change on \'A/deep/tra\' directory requested:',
     '[a]ccept, [s]kip this change,',
     'a[c]cept, s[k]ip changes to all properties with that name,',
     'move to [p]revious change > ',
     'Property change on A/deep/tra',
     '___________________________________________________________________',
     'Name: two',
     ' ',
     '[7/9] Property change on \'A/deep/tra\' directory requested:',
     '[a]ccept, [s]kip this change,',
     'a[c]cept, s[k]ip changes to all properties with that name,',
     'move to [p]revious change > ',
     'Property change on A/deep',
     '___________________________________________________________________',
     'Name: one',
     ' +multi',
     ' +line',
     '',
     '[8/9] Property change on \'A/deep\' directory requested:',
     '[a]ccept, [s]kip this change,',
     'a[c]cept, s[k]ip changes to all properties with that name,',
     'move to [p]revious change > ',
     '',
     '[9/9] File or directory \'A/foox\' is marked for deletion:',
     '[a]ccept, [s]kip this change,',
     'move to [p]revious change > ',
     'Committed revision 3.'],
    'directory modifications - output');

overwrite_file ("A/foo", "");
$answer = ['a'];
is_output ($svk, 'commit', ['--interactive', '-m', 'foo'],
    ["--- A/foo\t(revision 3)",
     "+++ A/foo\t(local)",
     '@@ -0,4 +0,3 @@',
     '-alfa',
     '-beta',
     '-foobar',
     '-gamma',
     '-delta',
     '\ No newline at end of file',
     '',
     '[1/1] Modification to \'A/foo\' file:',
     '[a]ccept, [s]kip this change,',
     '[A]ccept, [S]kip the rest of changes to this file > ',
     'Committed revision 4.'],
    'File diff - no nl at end-> empty');
    
$answer = ['a'];
overwrite_file ("A/foo", "foobar\n");
is_output ($svk, 'commit', ['--interactive', '-m', 'foo'],
    ["--- A/foo\t(revision 4)",
     "+++ A/foo\t(local)",
     '@@ -0 +0 @@',
     '+foobar',
     '',
     '[1/1] Modification to \'A/foo\' file:',
     '[a]ccept, [s]kip this change,',
     '[A]ccept, [S]kip the rest of changes to this file > ',
     'Committed revision 5.'],
    'File diff - empty -> nl at end');

$answer = ['a'];
overwrite_file ("A/foo", "");
is_output ($svk, 'commit', ['--interactive', '-m', 'foo'],
    ["--- A/foo\t(revision 5)",
     "+++ A/foo\t(local)",
     '@@ -0 +0 @@',
     '-foobar',
     '',
     '[1/1] Modification to \'A/foo\' file:',
     '[a]ccept, [s]kip this change,',
     '[A]ccept, [S]kip the rest of changes to this file > ',
     'Committed revision 6.'],
    'File diff - nl at end -> empty');

$answer = ['a'];
overwrite_file ("A/foo", "foobar");
is_output ($svk, 'commit', ['--interactive', '-m', 'foo'],
    ["--- A/foo\t(revision 6)",
     "+++ A/foo\t(local)",
     '@@ -0 +0 @@',
     '+foobar',
     '\ No newline at end of file',
     '',
     '[1/1] Modification to \'A/foo\' file:',
     '[a]ccept, [s]kip this change,',
     '[A]ccept, [S]kip the rest of changes to this file > ',
     'Committed revision 7.'],
    'File diff - empty -> no nl at end');

$answer = ['a'];
overwrite_file ("A/foo", "foobar\n");
is_output ($svk, 'commit', ['--interactive', '-m', 'foo'],
    ["--- A/foo\t(revision 7)",
     "+++ A/foo\t(local)",
     '@@ -0 +0 @@',
     '-foobar',
     '\ No newline at end of file',
     '+foobar',
     '',
     '[1/1] Modification to \'A/foo\' file:',
     '[a]ccept, [s]kip this change,',
     '[A]ccept, [S]kip the rest of changes to this file > ',
     'Committed revision 8.'],
    'File diff - no nl at end -> nl at end');

$answer = ['a'];
overwrite_file ("A/foo", "bar\n");
is_output ($svk, 'commit', ['--interactive', '-m', 'foo'],
    ["--- A/foo\t(revision 8)",
     "+++ A/foo\t(local)",
     '@@ -0 +0 @@',
     '-foobar',
     '+bar',
     '',
     '[1/1] Modification to \'A/foo\' file:',
     '[a]ccept, [s]kip this change,',
     '[A]ccept, [S]kip the rest of changes to this file > ',
     'Committed revision 9.'],
    'File diff - nl at end -> nl at end');

$answer = ['a'];
overwrite_file ("A/foo", "rabarbar");
is_output ($svk, 'commit', ['--interactive', '-m', 'foo'],
    ["--- A/foo\t(revision 9)",
     "+++ A/foo\t(local)",
     '@@ -0 +0 @@',
     '-bar',
     '+rabarbar',
     '\ No newline at end of file',
     '',
     '[1/1] Modification to \'A/foo\' file:',
     '[a]ccept, [s]kip this change,',
     '[A]ccept, [S]kip the rest of changes to this file > ',
     'Committed revision 10.'],
    'File diff - nl at end -> no nl at end');

$answer = ['a'];
$svk->propdel('one', 'A/foo');
is_output ($svk, 'commit', ['--interactive', '-m', 'foo'],
    ['Property change on A/foo',
     '___________________________________________________________________',
     'Name: one',
     ' -multi',
     ' -line',
     '',
     '[1/1] Property change on \'A/foo\' file requested:',
     '[a]ccept, [s]kip this change,',
     'a[c]cept, s[k]ip changes to all properties with that name > ',
     'Committed revision 11.'],
    'Prop del - no nl at end');

$answer = ['a'];
$svk->propset('one', 'zenum\n', 'A/foo');
is_output ($svk, 'commit', ['--interactive', '-m', 'foo'],
    ['Property change on A/foo',
     '___________________________________________________________________',
     'Name: one',
     ' +zenum\n',
     '',
     '[1/1] Property change on \'A/foo\' file requested:',
     '[a]ccept, [s]kip this change,',
     'a[c]cept, s[k]ip changes to all properties with that name > ',
     'Committed revision 12.'],
    'Prop set - empty -> nl at end');

$answer = ['a'];
$svk->propdel('one', 'A/foo');
is_output ($svk, 'commit', ['--interactive', '-m', 'foo'],
    ['Property change on A/foo',
     '___________________________________________________________________',
     'Name: one',
     ' -zenum\n',
     '',
     '[1/1] Property change on \'A/foo\' file requested:',
     '[a]ccept, [s]kip this change,',
     'a[c]cept, s[k]ip changes to all properties with that name > ',
     'Committed revision 13.'],
    'Prop del - nl at end');

$svk->propset('one', "por\n", 'A/foo');
$svk->commit('-m', 'baz');

$answer = ['a'];
$svk->propset('one', "rapaport", 'A/foo');
is_output ($svk, 'commit', ['--interactive', '-m', 'foo'],
    ['Property change on A/foo',
     '___________________________________________________________________',
     'Name: one',
     ' -por',
     ' +rapaport',
     '',
     '[1/1] Property change on \'A/foo\' file requested:',
     '[a]ccept, [s]kip this change,',
     'a[c]cept, s[k]ip changes to all properties with that name > ',
     'Committed revision 15.'],
    'Prop set - nl at end -> no nl at end');

$answer = ['a'];
$svk->propset('one', "mar\n", 'A/foo');
is_output ($svk, 'commit', ['--interactive', '-m', 'foo'],
    ['Property change on A/foo',
     '___________________________________________________________________',
     'Name: one',
     ' -rapaport',
     ' +mar',
     '',
     '[1/1] Property change on \'A/foo\' file requested:',
     '[a]ccept, [s]kip this change,',
     'a[c]cept, s[k]ip changes to all properties with that name > ',
     'Committed revision 16.'],
    'Prop set - no nl at end -> nl at end');

SKIP: {
overwrite_file ("A/foo", "0");
$svk->commit("-m", "foo");
$svk->cat("A/foo");
skip('broken SVN::Stream', 2) if $output ne '0';

overwrite_file ("A/foo", "content\n");
$answer = ['a'];
is_output ($svk, 'commit', ['--interactive', '-m', 'foo'],
    ["--- A/foo\t(revision 17)",
     "+++ A/foo\t(local)",
     '@@ -0 +0 @@',
     '-0',
     '\ No newline at end of file',
     '+content',
     '',
     '[1/1] Modification to \'A/foo\' file:',
     '[a]ccept, [s]kip this change,',
     '[A]ccept, [S]kip the rest of changes to this file > ',
     'Committed revision 18.'],
    'File diff - change from "0"');

overwrite_file ("A/foo", "0");
$answer = ['a'];
is_output ($svk, 'commit', ['--interactive', '-m', 'foo'],
    ["--- A/foo\t(revision 18)",
     "+++ A/foo\t(local)",
     '@@ -0 +0 @@',
     '-content',
     '+0',
     '\ No newline at end of file',
     '',
     '[1/1] Modification to \'A/foo\' file:',
     '[a]ccept, [s]kip this change,',
     '[A]ccept, [S]kip the rest of changes to this file > ',
     'Committed revision 19.'],
    'File diff - change to "0"');
}

$svk->propset('one', "0", 'A/foo');
$answer = ['a'];
is_output ($svk, 'commit', ['--interactive', '-m', 'foo'],
    ['Property change on A/foo',
     '___________________________________________________________________',
     'Name: one',
     ' -mar',
     ' +0',
     '',
     '[1/1] Property change on \'A/foo\' file requested:',
     '[a]ccept, [s]kip this change,',
     'a[c]cept, s[k]ip changes to all properties with that name > ',
     'Committed revision 20.'],
    'Prop diff - change to "0"');

$svk->propset('one', "data", 'A/foo');
$answer = ['a'];
is_output ($svk, 'commit', ['--interactive', '-m', 'foo'],
    ['Property change on A/foo',
     '___________________________________________________________________',
     'Name: one',
     ' -0',
     ' +data',
     '',
     '[1/1] Property change on \'A/foo\' file requested:',
     '[a]ccept, [s]kip this change,',
     'a[c]cept, s[k]ip changes to all properties with that name > ',
     'Committed revision 21.'],
    'Prop diff - change from "0"');

# test for bug where svn:keywords or svn:eol-style could make svk revert
# skipped changes

is_output($svk, propset => ['svn:keywords', 'Id', 'A/bar'],
          [__(' M  A/bar')]);

overwrite_file("A/bar", "\$Id\$\nalfa\nfoobar\nbeta\n");

is_output($svk, commit => ['-m', 'set keywords', 'A/bar'], ['Committed revision 22.']);

overwrite_file("A/bar", "\$Id\$\nalfa\nskip this insert\nfoobar\naccept this insert\nbeta\n");

is_output($svk, diff => ['A/bar'],
          [__('=== A/bar'),
              '==================================================================',
           __("--- A/bar\t(revision 22)"),
           __("+++ A/bar\t(local)"),
              '@@ -1,4 +1,6 @@',
              ' $Id$',
              ' alfa',
              '+skip this insert',
              ' foobar',
              '+accept this insert',
              ' beta',
          ]);

$answer = ['s', 'a'];
is_output ($svk, 'commit', ['--interactive', '-m', 'foo'],
           ["--- A/bar\t(revision 22)",
            "+++ A/bar\t(local)",
            '@@ -0,3 +0,3 @@',
            ' $Id$',
            ' alfa',
            '+skip this insert',
            ' foobar',
            ' beta',
            '',
            "[1/2] Modification to 'A/bar' file:",
            '[a]ccept, [s]kip this change,',
            '[A]ccept, [S]kip the rest of changes to this file > ',
            "--- A/bar\t(revision 22)",
            "+++ A/bar\t(local)",
            '@@ -0,3 +1,3 @@',
            ' $Id$',
            ' alfa',
            ' foobar',
            '+accept this insert',
            ' beta',
            '',
            "[2/2] Modification to 'A/bar' file:",
            '[a]ccept, [s]kip this change,',
            '[A]ccept, [S]kip the rest of changes to this file,',
            'move to [p]revious change > ',
            'Committed revision 23.',
           ]);

is_output($svk, diff => ['A/bar'],
          [__('=== A/bar'),
              '==================================================================',
           __("--- A/bar\t(revision 23)"),
           __("+++ A/bar\t(local)"),
              '@@ -1,5 +1,6 @@',
              ' $Id$',
              ' alfa',
              '+skip this insert',
              ' foobar',
              ' accept this insert',
              ' beta',
          ]);
