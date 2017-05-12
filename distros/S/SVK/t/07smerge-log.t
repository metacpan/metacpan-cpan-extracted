#!/usr/bin/perl -w
use strict;
use Test::More tests => 9;
use SVK::Test;
our $output;

my ($xd, $svk) = build_test();

my ($copath, $corpath) = get_copath ('smerge-log');
my ($repospath, undef, $repos) = $xd->find_repos ('//', 1);
my $uuid = $repos->fs->get_uuid;
$svk->mkdir ('-m', 'trunk', '//trunk');
$svk->checkout ('//', $copath);
overwrite_file ("$copath/".('trunk/filea.txt'), "this is filea\n");
$svk->commit ('--import', '-m', 'commit on trunk', $copath);

$svk->cp ('-m', 'branch for local', '//trunk', '//local');

$svk->update ($copath);
overwrite_file ("$copath/".('local/fileb.txt'), "this is fileb\n");
$svk->commit ('--import', '-m', 'add fileb on local', $copath);

append_file ("$copath/".('trunk/filea.txt'), "modified on trunk\n");
$svk->commit ('-m', 'modify filea on trunk', $copath);

$svk->smerge ('-Clm', 'Merge from local to trunk', '--host', 'svk', '-f', '//local');

is_output ($svk, 'smerge', ['-m', 'merge down', '-t', '//local'],
	   ['Auto-merging (2, 5) /trunk to /local (base /trunk:2).',
	    'U   filea.txt',
	    "New merge ticket: $uuid:/trunk:5",
	    'Committed revision 6.']);
is_output ($svk, 'smerge', ['-lm', 'Merge from local to trunk', '--host', 'svk', '-f', '//local'],
	   ['Auto-merging (0, 6) /local to /trunk (base /trunk:5).',
	    'A   fileb.txt',
	    "New merge ticket: $uuid:/local:6",
	    'Committed revision 7.']);
is_output ($svk, 'log', ['-r7', '//'],
	   ['-' x 70,
	    qr'r7: .*', '',
	    'Merge from local to trunk',
	    # we should get rid of the copy rev too
	    qr' r3@svk: .*',
	    ' branch for local',
	    qr' r4@svk: .*',
	    ' add fileb on local',
	    '',
	    '-' x 70,
	   ]);

$svk->update ($copath);
append_file ("$copath/".('local/fileb.txt'), "appended\n");
$svk->commit ('-m', 'modify fileb on local', $copath);
is_output ($svk, 'smerge', ['-lm', 'Merge from local to trunk', '--host', 'svk', '-f', '//local'],
	   ['Auto-merging (6, 8) /local to /trunk (base /local:6).',
	    'U   fileb.txt',
	    "New merge ticket: $uuid:/local:8",
	    'Committed revision 9.']);
is_output ($svk, 'log', ['-r9', '//'],
	   ['-' x 70,
	    qr'r9: .*', '',
	    'Merge from local to trunk',
	    qr' r8@svk: .*',
	    ' modify fileb on local',
	    '',
	    '-' x 70]);
$svk->cp ('-m', 'branch for local', '//local', '//fix');
$svk->update ($copath);
append_file ("$copath/".('fix/fileb.txt'), "fileb fixes on branch\n");
$svk->commit ('-m', 'modify fileb on fix', $copath);
$svk->smerge ('-lm', 'Merge from fix to local', '--host', 'fix', '-f', '//fix');
$svk->smerge ('-lm', 'Merge from local to trunk', '--host', 'svk', '-f', '//local');
append_file ("$copath/".('fix/fileb.txt'), "more fileb fixes on branch\n");
$svk->commit ('-m', 'modify fileb on fix', $copath);
$svk->smerge ('-lm', 'Merge from fix to local with verbatim log', '--verbatim', '--host', 'fix', '-f', '//fix');

is_output ($svk, 'log', ['-r12', '//'],
	   ['-' x 70,
	    qr'r12: .*', '',
	    'Merge from fix to local',
	    qr' r10@fix: .*',
	    ' branch for local',
	    qr' r11@fix: .*',
	    ' modify fileb on fix',
	    '',
	    '-' x 70]);
is_output ($svk, 'log', ['-r13', '//'],
	   ['-' x 70,
	    qr'r13: .*', '',
	    'Merge from local to trunk',
	    qr' r12@svk: .*',
	    ' Merge from fix to local',
	    qr'  r10@fix: .*',
	    '  branch for local',
	    qr'  r11@fix: .*',
	    '  modify fileb on fix',
	    ' ',
	    '',
	    '-' x 70]);
is_output ($svk, 'log', ['-r14', '//'],
	   ['-' x 70,
	    qr'r14: .*', '',
	    'modify fileb on fix',
	    '-' x 70
            ]);

# XXX: may lose something if we do "local -> fix merge" first

set_editor(<< 'TMP');
$_ = shift;
open _ or die $!;
# "manually" enter a commit message
@_ = ("Second merge from fix to local\n", <_>);
close _;
unlink $_;
open _, '>', $_ or die $!;
print _ @_;
close _;
TMP

append_file ("$copath/".('fix/fileb.txt'), "even more fileb fixes on branch\n");
$svk->commit ('-m', 'modify fileb on fix again', $copath);
$svk->smerge ('-l', '--host', 'editor-fix', '-f', '//fix');

is_output ($svk, 'log', ['-r17', '//'],
         ['-' x 70,
          qr'r17: .*', '',
          'Second merge from fix to local',
          qr' r16@editor-fix: .*',
          ' modify fileb on fix again',
	  '',
          '-' x 70]);

