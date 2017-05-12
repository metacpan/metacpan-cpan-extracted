#!/usr/bin/perl -w
use strict;
use Test::More tests => 3  ;
use Cwd;
use File::Path;

use SVK::Test;

# build another tree to be mirrored ourself
my ($xd, $svk) = build_test('test');

my ($copath, $corpath) = get_copath ('push-pull-cross');

$svk->mkdir(-m => 'trunk', '//trunk');
$svk->co('//', $copath);
chdir($copath);
overwrite_file('trunk/fileA', "foo\nbar\nbaz\nhate\n");
$svk->add('trunk/fileA');
$svk->commit(-m => 'trunk');

$svk->cp(-m => 'local', '//trunk' => '//local');

$svk->mkdir(-m => 'blah', '//waste');

$svk->up;
overwrite_file('local/fileA', "foo\nbar2\nbaz\nhate\n");
$svk->commit(-m => 'change bar line', 'local');

overwrite_file('trunk/fileA', "foo\nbar\nbaz\nhate2\n");
$svk->commit(-m => 'change hate line', 'trunk');

our $output;
$svk->sm(-ItC => '//local');

is_output($svk, 'sm', [-It => '//local'],
	  ['Auto-merging (2, 6) /trunk to /local (base /trunk:2).',
	   '===> Auto-merging (2, 6) /trunk to /local (base /trunk:2).',
	   'G   fileA',
	   qr'New merge ticket: .*:/trunk:6',
	   'Committed revision 7.']);

is_output($svk, 'sm', [-fIC => '//local'],
	  ['Auto-merging (0, 7) /local to /trunk (base /trunk:6).',
	   '===> Auto-merging (0, 3) /local to /trunk (base /trunk:2).',
	   'Empty merge.',
	   '===> Auto-merging (3, 5) /local to /trunk (base /trunk:2).',
	   'G   fileA',
	   qr'New merge ticket: .*:/local:5',
	   '===> Auto-merging (5, 7) /local to /trunk (base */local:5).',
	   'Empty merge.']);

is_output($svk, 'sm', [-If => '//local'],
	  ['Auto-merging (0, 7) /local to /trunk (base /trunk:6).',
	   '===> Auto-merging (0, 3) /local to /trunk (base /trunk:2).',
	   'Empty merge.',
	   '===> Auto-merging (3, 5) /local to /trunk (base /trunk:2).',
	   'G   fileA',
	   qr'New merge ticket: .*:/local:5',
	   'Committed revision 8.',
	   '===> Auto-merging (5, 7) /local to /trunk (base */local:5).',
	   'Empty merge.']);

__END__
trunk 
              local
r2 ----[cp]----> r3
                 r5
r6 ----[merge]-> r7   conflict-resolution-p?
                r7.5
r8 ----[merge]-> r9


non-lump: r10[s:r5, b:r2] <--[merge] mf: r5
lump :    r10[s:r7, b:r2]

1 - r11[s:r7, b:r6> 
2 - r11[s:r7, b:r5> 


r2 - foo
r6 - foo,bar
r5 - foo,baz
r7 - foo,bar,baz
r10 - foo,bar,baz
