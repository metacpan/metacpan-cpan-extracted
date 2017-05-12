#!/usr/bin/perl -w
use strict;
use SVK::Test;
plan tests => 53;

our $output;
our $answer;
my ($xd, $svk) = build_test();
my ($copath, $corpath) = get_copath ('commit-inter-navi');
my ($repospath, undef, $repos) = $xd->find_repos ('//', 1);

$svk->checkout ('//', $copath);
chdir ($copath);
mkdir ('A');
mkdir ('A/deep');
mkdir ('A/deep/la');
overwrite_file_raw ("A/foo", "foobar\ngrab\n");
overwrite_file_raw ("A/deep/baz", "makar");
overwrite_file_raw ("A/deep/la/no", "foobar");
overwrite_file_raw ("A/deep/mas", "po\nkra\nczny");

$svk->add ('A');

$answer = [[q{
[1/7] Directory 'A' is marked for addition:
[a]ccept, [s]kip this change,
[A]ccept changes to whole subdirectory > }, 'p'],[q{
[1/7] Directory 'A' is marked for addition:
[a]ccept, [s]kip this change,
[A]ccept changes to whole subdirectory > }, 'a'],[q{
[2/7] Directory 'A/deep' is marked for addition:
[a]ccept, [s]kip this change,
[A]ccept changes to whole subdirectory,
move to [p]revious change > }, 'a'],[q{
[3/7] File 'A/deep/baz' is marked for addition:
[a]ccept, [s]kip this change,
move to [p]revious change > }, 'a'],[q{
[4/7] Directory 'A/deep/la' is marked for addition:
[a]ccept, [s]kip this change,
[A]ccept changes to whole subdirectory,
move to [p]revious change > }, 'p'],[q{
[3/7] File 'A/deep/baz' is marked for addition:
[a]ccept, [s]kip this change,
move to [p]revious change [a]> }, ''],[q{
[4/7] Directory 'A/deep/la' is marked for addition:
[a]ccept, [s]kip this change,
[A]ccept changes to whole subdirectory,
move to [p]revious change > }, 'p'],[q{
[3/7] File 'A/deep/baz' is marked for addition:
[a]ccept, [s]kip this change,
move to [p]revious change [a]> }, 's'],[q{
[4/7] Directory 'A/deep/la' is marked for addition:
[a]ccept, [s]kip this change,
[A]ccept changes to whole subdirectory,
move to [p]revious change > }, 'p'],[q{
[3/7] File 'A/deep/baz' is marked for addition:
[a]ccept, [s]kip this change,
move to [p]revious change [s]> }, 'p'],[q{
[2/7] Directory 'A/deep' is marked for addition:
[a]ccept, [s]kip this change,
[A]ccept changes to whole subdirectory,
move to [p]revious change [a]> }, 'A'],[q{
[3/3] File 'A/foo' is marked for addition:
[a]ccept, [s]kip this change,
move to [p]revious change > }, 'p'],[q{
[2/3] Directory 'A/deep' is marked for addition:
[a]ccept, [s]kip this change,
[A]ccept changes to whole subdirectory,
move to [p]revious change [A]> }, 'A'],[q{
[3/3] File 'A/foo' is marked for addition:
[a]ccept, [s]kip this change,
move to [p]revious change > }, 'p'],[q{
[2/3] Directory 'A/deep' is marked for addition:
[a]ccept, [s]kip this change,
[A]ccept changes to whole subdirectory,
move to [p]revious change [A]> }, 's'],[q{
[3/3] File 'A/foo' is marked for addition:
[a]ccept, [s]kip this change,
move to [p]revious change > }, 'a'],'stop'];
#our $DEBUG = 1;
$svk->commit('--interactive', '-m', 'foo');

is_deeply($answer, ['stop'], 'all answers used');

is_output ($svk, 'status', [],
   [__('A   A/deep'),
    __('A   A/deep/baz'),
    __('A   A/deep/la'),
    __('A   A/deep/la/no'),
    __('A   A/deep/mas')], 'skip subdirectory');

#our $show_prompt_output = 1;
$svk->propset('roch', 'miata', 'A/deep');
$answer = [[q{
[1/6] Directory 'A/deep' is marked for addition:
[a]ccept, [s]kip this change,
[A]ccept changes to whole subdirectory > }, 'a'],[q{
[2/6] File 'A/deep/baz' is marked for addition:
[a]ccept, [s]kip this change,
move to [p]revious change > }, 'a'],[q{
[3/6] Directory 'A/deep/la' is marked for addition:
[a]ccept, [s]kip this change,
[A]ccept changes to whole subdirectory,
move to [p]revious change > }, 'A'],[q{
[4/5] File 'A/deep/mas' is marked for addition:
[a]ccept, [s]kip this change,
move to [p]revious change > }, 's'],[q{Property change on A/deep
___________________________________________________________________
Name: roch
 +miata

[5/5] Property change on 'A/deep' directory requested:
[a]ccept, [s]kip this change,
a[c]cept, s[k]ip changes to all properties with that name,
move to [p]revious change > }, 's'],'stop'];
$svk->commit('--interactive', '-m', 'foo');

is_deeply($answer, ['stop'], 'all answers used');
is_output ($svk, 'status', [],
   [__('A   A/deep/mas'),
    __(' M  A/deep')], 'accept subdirectory, skip file');

$answer = [[q{
[1/3] File 'A/deep/mas' is marked for addition:
[a]ccept, [s]kip this change > }, 's'],[q{Property change on A/deep
___________________________________________________________________
Name: roch
 +miata

[2/2] Property change on 'A/deep' directory requested:
[a]ccept, [s]kip this change,
a[c]cept, s[k]ip changes to all properties with that name,
move to [p]revious change > }, 'a'],'stop'];
$svk->propset('tada', 'bob', 'A/deep/mas');
$svk->commit('--interactive', '-m', 'foo');
is_deeply($answer, ['stop'], 'all answers used');
# XXX: this should show info about property
is_output ($svk, 'status', [],
   [__('A   A/deep/mas')], 'skip file with property');
is_output ($svk, 'diff', [],
   ['=== A/deep/mas',
    '==================================================================',
    "--- A/deep/mas\t(revision 3)",
    "+++ A/deep/mas\t(local)",
    '@@ -0,0 +1,3 @@',
    '+po',
    '+kra',
    '+czny',
    '\ No newline at end of file',
    '',
    'Property changes on: A/deep/mas',
    '___________________________________________________________________',
    'Name: tada',
    ' +bob',
    ''], 'skip file with property - test prop');

$answer = [[q{
[1/2] File 'A/deep/mas' is marked for addition:
[a]ccept, [s]kip this change > }, 'a'],[q{Property change on A/deep/mas
___________________________________________________________________
Name: tada
 +bob

[2/2] Property change on 'A/deep/mas' file requested:
[a]ccept, [s]kip this change,
a[c]cept, s[k]ip changes to all properties with that name,
move to [p]revious change > }, 's'],'stop'];
$svk->commit('--interactive', '-m', 'foo');
is_deeply($answer, ['stop'], 'all answers used');

is_output ($svk, 'diff', [],
   ['',
    'Property changes on: A/deep/mas',
    '___________________________________________________________________',
    'Name: tada',
    ' +bob',
    ''], 'commit file, skip property');

$answer = [[q{Property change on A/deep/mas
___________________________________________________________________
Name: bata
 +rob

[1/2] Property change on 'A/deep/mas' file requested:
[a]ccept, [s]kip this change,
a[c]cept, s[k]ip changes to all properties with that name > }, 'k'],[q{Property change on A/deep/mas
___________________________________________________________________
Name: tada
 +bob

[2/2] Property change on 'A/deep/mas' file requested:
[a]ccept, [s]kip this change,
a[c]cept, s[k]ip changes to all properties with that name,
move to [p]revious change > }, 'p'],[q{Property change on A/deep/mas
___________________________________________________________________
Name: bata
 +rob

[1/2] Property change on 'A/deep/mas' file requested:
[a]ccept, [s]kip this change,
a[c]cept, s[k]ip changes to all properties with that name [k]> }, 's'],[q{Property change on A/deep/mas
___________________________________________________________________
Name: tada
 +bob

[2/2] Property change on 'A/deep/mas' file requested:
[a]ccept, [s]kip this change,
a[c]cept, s[k]ip changes to all properties with that name,
move to [p]revious change > }, 'a'],'stop'];
$svk->propset('bata', 'rob', 'A/deep/mas');
$svk->commit('--interactive', '-m', 'foo');
is_deeply($answer, ['stop'], 'all answers used');
is_output ($svk, 'diff', [],
   ['',
    'Property changes on: A/deep/mas',
    '___________________________________________________________________',
    'Name: bata',
    ' +rob',
    ''], 'skip only one property');

$answer = [[q{Property change on A/deep/mas
___________________________________________________________________
Name: bata
 +rob

[1/3] Property change on 'A/deep/mas' file requested:
[a]ccept, [s]kip this change,
a[c]cept, s[k]ip changes to all properties with that name > }, 'a'],[q{Property change on A/deep/mas
___________________________________________________________________
Name: zoot
 +wex

[2/3] Property change on 'A/deep/mas' file requested:
[a]ccept, [s]kip this change,
a[c]cept, s[k]ip changes to all properties with that name,
move to [p]revious change > }, 'p'],[q{Property change on A/deep/mas
___________________________________________________________________
Name: bata
 +rob

[1/3] Property change on 'A/deep/mas' file requested:
[a]ccept, [s]kip this change,
a[c]cept, s[k]ip changes to all properties with that name [a]> }, 'c'],[q{Property change on A/deep/mas
___________________________________________________________________
Name: zoot
 +wex

[2/2] Property change on 'A/deep/mas' file requested:
[a]ccept, [s]kip this change,
a[c]cept, s[k]ip changes to all properties with that name,
move to [p]revious change > }, 's'],'stop'];
$svk->propset('bata', 'koro', 'A/deep');
$svk->propset('zoot', 'wex', 'A/deep/mas');
$svk->commit('--interactive', '-m', 'foo');
is_deeply($answer, ['stop'], 'all answers used');
is_output ($svk, 'diff', [],
   ['',
    'Property changes on: A/deep/mas',
    '___________________________________________________________________',
    'Name: zoot',
    ' +wex',
    ''], 'skip all \'bata\' properties');

overwrite_file_raw ("A/deep/mas", "wy\nkra\nkal\n");
$svk->propset('parra', 'kok', 'A/deep/mas');
$answer = [[qq{--- A/deep/mas\t(revision 6)
+++ A/deep/mas\t(local)}.q{
@@ -0,2 +0,2 @@
-po
+wy
 kra
 czny
[1/4] Modification to 'A/deep/mas' file:
[a]ccept, [s]kip this change,
[A]ccept, [S]kip the rest of changes to this file,
a[c]cept, s[k]ip rest of changes to this file and its properties > }, 'S'],[q{Property change on A/deep/mas
___________________________________________________________________
Name: parra
 +kok

[2/3] Property change on 'A/deep/mas' file requested:
[a]ccept, [s]kip this change,
a[c]cept, s[k]ip changes to all properties with that name,
move to [p]revious change > }, 'p'],[qq{--- A/deep/mas\t(revision 6)
+++ A/deep/mas\t(local)}.q{
@@ -0,2 +0,2 @@
-po
+wy
 kra
 czny
[1/3] Modification to 'A/deep/mas' file:
[a]ccept, [s]kip this change,
[A]ccept, [S]kip the rest of changes to this file,
a[c]cept, s[k]ip rest of changes to this file and its properties [S]> }, 'A'],[q{Property change on A/deep/mas
___________________________________________________________________
Name: parra
 +kok

[2/3] Property change on 'A/deep/mas' file requested:
[a]ccept, [s]kip this change,
a[c]cept, s[k]ip changes to all properties with that name,
move to [p]revious change > }, 'a'],[q{Property change on A/deep/mas
___________________________________________________________________
Name: zoot
 +wex

[3/3] Property change on 'A/deep/mas' file requested:
[a]ccept, [s]kip this change,
a[c]cept, s[k]ip changes to all properties with that name,
move to [p]revious change > }, 'p'],[q{Property change on A/deep/mas
___________________________________________________________________
Name: parra
 +kok

[2/3] Property change on 'A/deep/mas' file requested:
[a]ccept, [s]kip this change,
a[c]cept, s[k]ip changes to all properties with that name,
move to [p]revious change [a]> }, ''],[q{Property change on A/deep/mas
___________________________________________________________________
Name: zoot
 +wex

[3/3] Property change on 'A/deep/mas' file requested:
[a]ccept, [s]kip this change,
a[c]cept, s[k]ip changes to all properties with that name,
move to [p]revious change > }, 'p'],[q{Property change on A/deep/mas
___________________________________________________________________
Name: parra
 +kok

[2/3] Property change on 'A/deep/mas' file requested:
[a]ccept, [s]kip this change,
a[c]cept, s[k]ip changes to all properties with that name,
move to [p]revious change [a]> }, 'p'],[qq{--- A/deep/mas\t(revision 6)
+++ A/deep/mas\t(local)}.q{
@@ -0,2 +0,2 @@
-po
+wy
 kra
 czny
[1/3] Modification to 'A/deep/mas' file:
[a]ccept, [s]kip this change,
[A]ccept, [S]kip the rest of changes to this file,
a[c]cept, s[k]ip rest of changes to this file and its properties [A]> }, 'p'],[qq{--- A/deep/mas\t(revision 6)
+++ A/deep/mas\t(local)}.q{
@@ -0,2 +0,2 @@
-po
+wy
 kra
 czny
[1/3] Modification to 'A/deep/mas' file:
[a]ccept, [s]kip this change,
[A]ccept, [S]kip the rest of changes to this file,
a[c]cept, s[k]ip rest of changes to this file and its properties [A]> }, 'k'],'stop'];
$svk->commit('--interactive', '-m', 'foo');
is_deeply($answer, ['stop'], 'all answers used');
is_output ($svk, 'diff', [],
   ['=== A/deep/mas',
    '==================================================================',
    "--- A/deep/mas\t(revision 6)",
    "+++ A/deep/mas\t(local)",
    '@@ -1,3 +1,3 @@',
    '-po',
    '+wy',
    ' kra',
    '-czny',
    '\ No newline at end of file',
    '+kal',
    '',
    'Property changes on: A/deep/mas',
    '___________________________________________________________________',
    'Name: parra',
    ' +kok',
    'Name: zoot',
    ' +wex',
    ''], 'skip all changes to content and properties');

$answer = [[qq{--- A/deep/mas\t(revision 6)
+++ A/deep/mas\t(local)}.q{
@@ -0,2 +0,2 @@
-po
+wy
 kra
 czny
[1/4] Modification to 'A/deep/mas' file:
[a]ccept, [s]kip this change,
[A]ccept, [S]kip the rest of changes to this file,
a[c]cept, s[k]ip rest of changes to this file and its properties > }, 's'],[qq{--- A/deep/mas\t(revision 6)
+++ A/deep/mas\t(local)}.q{
@@ -0,2 +0,2 @@
 po
 kra
-czny
\ No newline at end of file
+kal

[2/4] Modification to 'A/deep/mas' file:
[a]ccept, [s]kip this change,
[A]ccept, [S]kip the rest of changes to this file,
a[c]cept, s[k]ip rest of changes to this file and its properties,
move to [p]revious change > }, 'p'],[qq{--- A/deep/mas\t(revision 6)
+++ A/deep/mas\t(local)}.q{
@@ -0,2 +0,2 @@
-po
+wy
 kra
 czny
[1/4] Modification to 'A/deep/mas' file:
[a]ccept, [s]kip this change,
[A]ccept, [S]kip the rest of changes to this file,
a[c]cept, s[k]ip rest of changes to this file and its properties [s]> }, ''],[qq{--- A/deep/mas\t(revision 6)
+++ A/deep/mas\t(local)}.q{
@@ -0,2 +0,2 @@
 po
 kra
-czny
\ No newline at end of file
+kal

[2/4] Modification to 'A/deep/mas' file:
[a]ccept, [s]kip this change,
[A]ccept, [S]kip the rest of changes to this file,
a[c]cept, s[k]ip rest of changes to this file and its properties,
move to [p]revious change > }, 'p'],[qq{--- A/deep/mas\t(revision 6)
+++ A/deep/mas\t(local)}.q{
@@ -0,2 +0,2 @@
-po
+wy
 kra
 czny
[1/4] Modification to 'A/deep/mas' file:
[a]ccept, [s]kip this change,
[A]ccept, [S]kip the rest of changes to this file,
a[c]cept, s[k]ip rest of changes to this file and its properties [s]> }, 'S'],[q{Property change on A/deep/mas
___________________________________________________________________
Name: parra
 +kok

[2/3] Property change on 'A/deep/mas' file requested:
[a]ccept, [s]kip this change,
a[c]cept, s[k]ip changes to all properties with that name,
move to [p]revious change > }, 'p'],[qq{--- A/deep/mas\t(revision 6)
+++ A/deep/mas\t(local)}.q{
@@ -0,2 +0,2 @@
-po
+wy
 kra
 czny
[1/3] Modification to 'A/deep/mas' file:
[a]ccept, [s]kip this change,
[A]ccept, [S]kip the rest of changes to this file,
a[c]cept, s[k]ip rest of changes to this file and its properties [S]> }, 'A'],[q{Property change on A/deep/mas
___________________________________________________________________
Name: parra
 +kok

[2/3] Property change on 'A/deep/mas' file requested:
[a]ccept, [s]kip this change,
a[c]cept, s[k]ip changes to all properties with that name,
move to [p]revious change > }, 'c'],[q{Property change on A/deep/mas
___________________________________________________________________
Name: zoot
 +wex

[3/3] Property change on 'A/deep/mas' file requested:
[a]ccept, [s]kip this change,
a[c]cept, s[k]ip changes to all properties with that name,
move to [p]revious change > }, 'p'],[q{Property change on A/deep/mas
___________________________________________________________________
Name: parra
 +kok

[2/3] Property change on 'A/deep/mas' file requested:
[a]ccept, [s]kip this change,
a[c]cept, s[k]ip changes to all properties with that name,
move to [p]revious change [c]> }, 's'],[q{Property change on A/deep/mas
___________________________________________________________________
Name: zoot
 +wex

[3/3] Property change on 'A/deep/mas' file requested:
[a]ccept, [s]kip this change,
a[c]cept, s[k]ip changes to all properties with that name,
move to [p]revious change > }, 's'],'stop'];
$svk->commit('--interactive', '-m', 'foo');
is_deeply($answer, ['stop'], 'all answers used');
is_output ($svk, 'diff', [],
   ['',
    'Property changes on: A/deep/mas',
    '___________________________________________________________________',
    'Name: parra',
    ' +kok',
    'Name: zoot',
    ' +wex',
    ''], 'commit only content changes');

overwrite_file_raw ("A/deep/mas", "wy\npstry\nkal\n");
overwrite_file_raw ("A/foo", "temp");
$answer = [[qq{--- A/deep/mas\t(revision 7)
+++ A/deep/mas\t(local)}.q{
@@ -0,2 +0,2 @@
 wy
-kra
+pstry
 kal

[1/4] Modification to 'A/deep/mas' file:
[a]ccept, [s]kip this change,
[A]ccept, [S]kip the rest of changes to this file,
a[c]cept, s[k]ip rest of changes to this file and its properties > }, 'S'],[q{Property change on A/deep/mas
___________________________________________________________________
Name: parra
 +kok

[2/4] Property change on 'A/deep/mas' file requested:
[a]ccept, [s]kip this change,
a[c]cept, s[k]ip changes to all properties with that name,
move to [p]revious change > }, 'p'],[qq{--- A/deep/mas\t(revision 7)
+++ A/deep/mas\t(local)}.q{
@@ -0,2 +0,2 @@
 wy
-kra
+pstry
 kal

[1/4] Modification to 'A/deep/mas' file:
[a]ccept, [s]kip this change,
[A]ccept, [S]kip the rest of changes to this file,
a[c]cept, s[k]ip rest of changes to this file and its properties [S]> }, 'c'],[qq{--- A/foo\t(revision 7)
+++ A/foo\t(local)}.q{
@@ -0,1 +0,1 @@
-foobar
-grab
+temp
\ No newline at end of file

[2/2] Modification to 'A/foo' file:
[a]ccept, [s]kip this change,
[A]ccept, [S]kip the rest of changes to this file,
move to [p]revious change > }, 'p'],[qq{--- A/deep/mas\t(revision 7)
+++ A/deep/mas\t(local)}.q{
@@ -0,2 +0,2 @@
 wy
-kra
+pstry
 kal

[1/2] Modification to 'A/deep/mas' file:
[a]ccept, [s]kip this change,
[A]ccept, [S]kip the rest of changes to this file,
a[c]cept, s[k]ip rest of changes to this file and its properties [c]> }, 'a'],[q{Property change on A/deep/mas
___________________________________________________________________
Name: parra
 +kok

[2/2] Property change on 'A/deep/mas' file requested:
[a]ccept, [s]kip this change,
a[c]cept, s[k]ip changes to all properties with that name,
move to [p]revious change > }, 'p'],[qq{--- A/deep/mas\t(revision 7)
+++ A/deep/mas\t(local)}.q{
@@ -0,2 +0,2 @@
 wy
-kra
+pstry
 kal

[1/2] Modification to 'A/deep/mas' file:
[a]ccept, [s]kip this change,
[A]ccept, [S]kip the rest of changes to this file,
a[c]cept, s[k]ip rest of changes to this file and its properties [a]> }, 'c'],[qq{--- A/foo\t(revision 7)
+++ A/foo\t(local)}.q{
@@ -0,1 +0,1 @@
-foobar
-grab
+temp
\ No newline at end of file

[2/2] Modification to 'A/foo' file:
[a]ccept, [s]kip this change,
[A]ccept, [S]kip the rest of changes to this file,
move to [p]revious change > }, 's'],'stop'];
$svk->commit('--interactive', '-m', 'foo');
is_deeply($answer, ['stop'], 'all answers used');
is_output ($svk, 'status', [],
    [__('M   A/foo')], 'commit all changes to content and properties');

$svk->revert("A/foo");
$svk->propset('parra', 'kok', '.');
$answer = [[q{Property change on 
___________________________________________________________________
Name: parra
 +kok

[1/1] Property change on '.' directory requested:
[a]ccept, [s]kip this change,
a[c]cept, s[k]ip changes to all properties with that name > }, 's'],'stop'];
$svk->commit('--interactive', '-m', 'foo');
is_deeply($answer, ['stop'], 'all answers used');
is_output ($svk, 'diff', [],
   ['',
    'Property changes on: ',
    '___________________________________________________________________',
    'Name: parra',
    ' +kok',
    ''], 'skip change to root directory');

$svk->propset('parra', 'kok', '.');
$answer = [[q{Property change on 
___________________________________________________________________
Name: parra
 +kok

[1/1] Property change on '.' directory requested:
[a]ccept, [s]kip this change,
a[c]cept, s[k]ip changes to all properties with that name > }, 'a'],'stop'];
$svk->commit('--interactive', '-m', 'foo');
is_deeply($answer, ['stop'], 'all answers used');
is_output ($svk, 'status', [], [], 'commit change to root directory');

overwrite_file_raw ("A/foo", "za\ngrab\nione\n");
$answer = [[qq{--- foo\t(revision 9)
+++ foo\t(local)}.q{
@@ -0,1 +0,1 @@
-foobar
+za
 grab

[1/2] Modification to 'foo' file:
[a]ccept, [s]kip this change,
[A]ccept, [S]kip the rest of changes to this file > }, 's'],[qq{--- foo\t(revision 9)
+++ foo\t(local)}.q{
@@ -0,1 +0,1 @@
 foobar
 grab
+ione

[2/2] Modification to 'foo' file:
[a]ccept, [s]kip this change,
[A]ccept, [S]kip the rest of changes to this file,
move to [p]revious change > }, 's'],'stop'];
is_output($svk, 'commit', 
  ['--interactive', 'A/foo', '-m', 'foo'],
  ['No targets to commit.'], "Skip everything in interactive commit.");
is_deeply($answer, ['stop'], 'all answers used');
is_output ($svk, 'diff', [],
   ['=== A/foo',
    '==================================================================',
    "--- A/foo\t(revision 9)",
    "+++ A/foo\t(local)",
    '@@ -1,2 +1,3 @@',
    '-foobar',
    '+za',
    ' grab',
    '+ione'], 'skiped content change to directly passed file');

$svk->propset('papa', 'mot', 'A/foo');
overwrite_file_raw ("A/foo", "za\ngrab\nione\n");
$answer = [[qq{--- foo\t(revision 9)
+++ foo\t(local)}.q{
@@ -0,1 +0,1 @@
-foobar
+za
 grab

[1/3] Modification to 'foo' file:
[a]ccept, [s]kip this change,
[A]ccept, [S]kip the rest of changes to this file,
a[c]cept, s[k]ip rest of changes to this file and its properties > }, 'k'],'stop'];
$svk->commit('--interactive', 'A/foo', '-m', 'foo');
is_deeply($answer, ['stop'], 'all answers used');
is_output ($svk, 'diff', [],
   ['=== A/foo',
    '==================================================================',
    "--- A/foo\t(revision 9)",
    "+++ A/foo\t(local)",
    '@@ -1,2 +1,3 @@',
    '-foobar',
    '+za',
    ' grab',
    '+ione',
    '',
    'Property changes on: A/foo',
    '___________________________________________________________________',
    'Name: papa',
    ' +mot',
    ''], 'skiped content and prop change to directly passed file');

$answer = [[qq{--- foo\t(revision 9)
+++ foo\t(local)}.q{
@@ -0,1 +0,1 @@
-foobar
+za
 grab

[1/3] Modification to 'foo' file:
[a]ccept, [s]kip this change,
[A]ccept, [S]kip the rest of changes to this file,
a[c]cept, s[k]ip rest of changes to this file and its properties > }, 'A'],[q{Property change on foo
___________________________________________________________________
Name: papa
 +mot

[2/2] Property change on 'foo' file requested:
[a]ccept, [s]kip this change,
a[c]cept, s[k]ip changes to all properties with that name,
move to [p]revious change > }, 's'],'stop'];
$svk->commit('--interactive', 'A/foo', '-m', 'foo');
is_deeply($answer, ['stop'], 'all answers used');
is_output ($svk, 'diff', [],
   ['',
    'Property changes on: A/foo',
    '___________________________________________________________________',
    'Name: papa',
    ' +mot',
    ''], 'commited content, skiped prop to directly passed file');

$answer = [[q{Property change on foo
___________________________________________________________________
Name: papa
 +mot

[1/1] Property change on 'foo' file requested:
[a]ccept, [s]kip this change,
a[c]cept, s[k]ip changes to all properties with that name > }, 'a'],'stop'];
$svk->commit('--interactive', 'A/foo', '-m', 'foo');
is_deeply($answer, ['stop'], 'all answers used');
is_output ($svk, 'status', [], [], 'commit prop changes to directly passed file');

our $show_prompt=1;
is_output($svk,'merge', ['-c1', '//A/foo', 'A/deep/mas'],
[ __('C   A/deep/mas'), '1 conflict found.'], "Merge a conflict into the tree");

overwrite_file_raw ("A/foo", "za\npalny\n");
$answer = [[q{Conflict detected in:
  A/deep/mas
file. Do you want to skip it and commit other changes? (y/n) }, 'n'],'stop'];
is_output($svk, 'commit', ['--interactive', '-m', 'foo'],
    ['Conflict detected in:',
     '  A/deep/mas',
     'file. Do you want to skip it and commit other changes? (y/n) ',
     '1 conflict detected. Use \'svk resolved\' after resolving them.'],
     'conflict - output');

is_deeply($answer, ['stop'], 'all answers used');
is_output ($svk, 'status', [],
    [__('C   A/deep/mas'),
     __('M   A/foo')], 'conflict - abort');

$show_prompt=0;
$answer = [[q{Conflict detected in:
  A/deep/mas
file. Do you want to skip it and commit other changes? (y/n) }, 'y'],[qq{--- A/foo\t(revision 11)
+++ A/foo\t(local)}.q{
@@ -0,2 +0,2 @@
 za
-grab
-ione
+palny

[1/1] Modification to 'A/foo' file:
[a]ccept, [s]kip this change,
[A]ccept, [S]kip the rest of changes to this file > }, 'a'],'stop'];
#our $DEBUG=1;
$svk->commit('--interactive', '-m', 'foo');
is_deeply($answer, ['stop'], 'all answers used');
is_output ($svk, 'status', [],[
__('C   A/deep/mas'),
], 'conflict - skip the conflict, but commit changes to foo');

$show_prompt=1;
is_output($svk, 'merge', ['-c1', '//A/foo', 'A/deep/baz'],
[__('C   A/deep/baz'),
'1 conflict found.'
], "create another conflict");
overwrite_file_raw ("A/foo", "");
$answer = [[q{Conflict detected in:
  A/deep/baz
  A/deep/mas
files. Do you want to skip those and commit other changes? (y/n) }, 'n'],'stop'];
is_output($svk, 'commit', ['--interactive', '-m', 'foo'],
    ['Conflict detected in:',
     '  A/deep/baz',
     '  A/deep/mas',
     'files. Do you want to skip those and commit other changes? (y/n) ',
     '2 conflicts detected. Use \'svk resolved\' after resolving them.'],
     'multiple conflicts -  output');

is_deeply($answer, ['stop'], 'all answers used');
is_output ($svk, 'status', [],
    [__('C   A/deep/baz'),
     __('C   A/deep/mas'),
     __('M   A/foo')], 'multiple conflicts - abort');

$show_prompt=0;
$answer = [[q{Conflict detected in:
  A/deep/baz
  A/deep/mas
files. Do you want to skip those and commit other changes? (y/n) }, 'y'],[qq{--- A/foo\t(revision 12)
+++ A/foo\t(local)}.q{
@@ -0,1 +0 @@
-za
-palny

[1/1] Modification to 'A/foo' file:
[a]ccept, [s]kip this change,
[A]ccept, [S]kip the rest of changes to this file > }, 'a'],'stop'];
$svk->commit('--interactive', '-m', 'foo');
is_deeply($answer, ['stop'], 'all answers used');
is_output ($svk, 'status', [],
    [__('C   A/deep/baz'),
     __('C   A/deep/mas')], 'multiple conflicts- skip');

$svk->revert('A/deep/baz', 'A/deep/mas');
$svk->propset('svn:mime-type', 'faked/type', 'A/deep/mas');
overwrite_file_raw ("A/deep/mas", "baran\nkoza\nowca\n");
$show_prompt=1;
$answer = [[q{
[1/2] Modifications to binary file 'A/deep/mas':
[a]ccept, [s]kip this change,
a[c]cept, s[k]ip rest of changes to this file and its properties > }, 'c'],'stop'];
is_output($svk, 'commit', ['--interactive', '-m', 'foo'],
    ['',                                     
     '[1/2] Modifications to binary file \'A/deep/mas\':',
     '[a]ccept, [s]kip this change,',
     'a[c]cept, s[k]ip rest of changes to this file and its properties > ',
     'Committed revision 14.'],
     'replace file with binary one - output');
is_deeply($answer, ['stop'], 'all answers used');
is_output ($svk, 'status', [], [], 'replace file with binary one');

$svk->propset('svn:mime-type', 'text/plain', 'A/deep/mas');
overwrite_file_raw ("A/deep/mas", "krowa\nkoza\n");
$show_prompt=0;
$answer = [[q{
[1/2] Modifications to binary file 'A/deep/mas':
[a]ccept, [s]kip this change,
a[c]cept, s[k]ip rest of changes to this file and its properties > }, 'a'],[q{Property change on A/deep/mas
___________________________________________________________________
Name: svn:mime-type
 -faked/type
 +text/plain

[2/2] Property change on 'A/deep/mas' file requested:
[a]ccept, [s]kip this change,
a[c]cept, s[k]ip changes to all properties with that name,
move to [p]revious change > }, 'a'],'stop'];
$svk->commit('--interactive', '-m', 'foo');
is_deeply($answer, ['stop'], 'all answers used');
is_output ($svk, 'status', [], [], 'replace binary file with text one');

overwrite_file_raw ("A/deep/mas", "byk\nkrowa\nbawol\nkoza\nkaczka\n");
$answer = [[qq{--- A/deep/mas\t(revision 15)
+++ A/deep/mas\t(local)}.q{
@@ -0,1 +0,1 @@
+byk
 krowa
 koza

[1/3] Modification to 'A/deep/mas' file:
[a]ccept, [s]kip this change,
[A]ccept, [S]kip the rest of changes to this file > }, 'a'],[qq{--- A/deep/mas\t(revision 15)
+++ A/deep/mas\t(local)}.q{
@@ -0,1 +1,1 @@
 krowa
+bawol
 koza

[2/3] Modification to 'A/deep/mas' file:
[a]ccept, [s]kip this change,
[A]ccept, [S]kip the rest of changes to this file,
move to [p]revious change > }, 'a'],[qq{--- A/deep/mas\t(revision 15)
+++ A/deep/mas\t(local)}.q{
@@ -0,1 +2,1 @@
 krowa
 koza
+kaczka

[3/3] Modification to 'A/deep/mas' file:
[a]ccept, [s]kip this change,
[A]ccept, [S]kip the rest of changes to this file,
move to [p]revious change > }, 'a'],'stop'];
$svk->commit('--interactive', '-m', 'foo');
is_deeply($answer, ['stop'], 'all answers used');
is_output ($svk, 'status', [], [], 'replace text file with text one');

#our $show_prompt_output=1;
$svk->propset('kox', 'ob', 'A/deep');
overwrite_file_raw ("A/deep/mas", "mleczna\nkrowa\n");
$answer = [[qq{--- A/deep/mas\t(revision 16)
+++ A/deep/mas\t(local)}.q{
@@ -0,4 +0,4 @@
-byk
+mleczna
 krowa
 bawol
 koza
 kaczka

[1/3] Modification to 'A/deep/mas' file:
[a]ccept, [s]kip this change,
[A]ccept, [S]kip the rest of changes to this file > }, 'A'],[q{Property change on A/deep
___________________________________________________________________
Name: kox
 +ob

[2/2] Property change on 'A/deep' directory requested:
[a]ccept, [s]kip this change,
a[c]cept, s[k]ip changes to all properties with that name,
move to [p]revious change > }, 'p'],[qq{--- A/deep/mas\t(revision 16)
+++ A/deep/mas\t(local)}.q{
@@ -0,4 +0,4 @@
-byk
+mleczna
 krowa
 bawol
 koza
 kaczka

[1/2] Modification to 'A/deep/mas' file:
[a]ccept, [s]kip this change,
[A]ccept, [S]kip the rest of changes to this file [A]> }, 'a'],[qq{--- A/deep/mas\t(revision 16)
+++ A/deep/mas\t(local)}.q{
@@ -0,4 +0,3 @@
 byk
 krowa
-bawol
-koza
-kaczka

[2/3] Modification to 'A/deep/mas' file:
[a]ccept, [s]kip this change,
[A]ccept, [S]kip the rest of changes to this file,
move to [p]revious change > }, 'a'],[q{Property change on A/deep
___________________________________________________________________
Name: kox
 +ob

[3/3] Property change on 'A/deep' directory requested:
[a]ccept, [s]kip this change,
a[c]cept, s[k]ip changes to all properties with that name,
move to [p]revious change > }, 's'],'stop'];
$svk->commit('--interactive', '-m', 'foo');
is_output ($svk, 'status', [],
    [__(' M  A/deep')], 'skip directory property on used directory.');
is_deeply($answer, ['stop'], 'all answers used');

