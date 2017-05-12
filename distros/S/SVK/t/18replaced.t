#!/usr/bin/perl -w
use Test::More tests => 31;
use strict;
our $output;
use SVK::Test;
my ($xd, $svk) = build_test();
$svk->mkdir ('-m', 'init', '//V');
my $tree = create_basic_tree ($xd, '//V');
my ($copath, $corpath) = get_copath ('replaced');
$svk->checkout ('//V', $copath);
$svk->rm ("$copath/A/be");
overwrite_file ("$copath/A/be", "foobar\n");
is_output ($svk, 'add', ["$copath/A/be"],
	   [__"R   $copath/A/be"]);
is_output ($svk, 'status', [$copath],
	   [__"R   $copath/A/be"]);
is_output ($svk, 'commit', ['-m', 'replace A/be', $copath],
	   ['Committed revision 4.']);
$svk->rm ("$copath/A");
mkdir ("$copath/A");
overwrite_file ("$copath/A/be", "foobar\n2nd replace\n");
overwrite_file ("$copath/A/neu", "foobar\n2nd replace\n");
# XXX: notify flush and cb_unknown ordering
is_output ($svk, 'add', ["$copath/A"],
	   [
	    __"A   $copath/A/be",
            __"A   $copath/A/neu",
            __"R   $copath/A",
        ]);

is_output ($svk, 'status', ["$copath/A"],
	   [__"R   $copath/A",
	    __"A   $copath/A/be",
            __"A   $copath/A/neu",
        ]);

overwrite_file ("$copath/A/unused", "foobar\n2nd replace\n");
is_output ($svk, 'status', ["$copath"],
	   [__"R   $copath/A",
	    __"A   $copath/A/be",
	    __"A   $copath/A/neu",
	    __"?   $copath/A/unused",
        ]);

is_output ($svk, 'add', ['-N', "$copath/A"],
	   [__("$copath/A already added.")]);

is_output($svk, 'revert', ['-R', $copath],
          ['Reverted '.__('t/checkout/replaced/A'),
           'Reverted '.__('t/checkout/replaced/A/be'),
           'Reverted '.__('t/checkout/replaced/A/neu'),
           __('t/checkout/replaced/A/unused').' is not versioned; ignored.',
           'Reverted '.__('t/checkout/replaced/A/Q'),
           'Reverted '.__('t/checkout/replaced/A/Q/qu'),
           'Reverted '.__('t/checkout/replaced/A/Q/qz'),
           'Reverted '.__('t/checkout/replaced/A/be'),
           __('t/checkout/replaced/A/neu').' is not versioned; ignored.',
           __('t/checkout/replaced/A/unused').' is not versioned; ignored.',
       ]);


is_output ($svk, 'status', [$copath],
	   [__"?   $copath/A/neu",
	    __"?   $copath/A/unused"], 'revert replaced tree items');
ok(-d "$copath/A/Q");

unlink ("$copath/A/neu");
unlink ("$copath/A/unused");
$svk->rm ("$copath/A");
mkdir ("$copath/A");
overwrite_file ("$copath/A/be", "foobar\n2nd replace\n");
overwrite_file ("$copath/A/neu", "foobar\n2nd replace\n");
$svk->add ("$copath/A");

is_output ($svk, 'commit', ['-m', 'replace A/be', $copath],
	   ['Committed revision 5.']);

$svk->rm ("$copath/A");
$svk->status ($copath);
overwrite_file ("$copath/A", "dir replaced as file\n");
$svk->status ($copath);
is_output ($svk, 'add', ["$copath/A"],
	   [__"R   $copath/A"]);

is_output ($svk, 'status', [$copath],
	   [__"R   $copath/A"],
           'file replacing dir');
$svk->commit ('-m', 'commit the replace', $copath);

mkdir ("$copath/T1");
overwrite_file ("$copath/T1/T1", "foobar\n");
mkdir ("$copath/T2");
overwrite_file ("$copath/T2/T2", "foobar\n");
$svk->add ("$copath/T1");
$svk->add ("$copath/T2");



$svk->commit ('-m', 'commit', $copath);

$svk->rm ("$copath/T1/T1");

is_output ($svk, 'cp', ["$copath/T2/T2", "$copath/T1/T1"],
           [__"A   $copath/T1/T1"], 'replace with history');
is_output ($svk, 'st', [$copath],
	   [__"R + $copath/T1/T1"]);
is_output ($svk, 'st', ["$copath/T1/T1"],
	   [__"R + $copath/T1/T1"]);

$svk->commit ('-m', 'commit', $copath);

is_ancestor ($svk, '//V/T1/T1',
	     '/V/T2/T2', 7);

$svk->rm ("$copath/T1");
is_output ($svk, 'cp', ["$copath/T2", "$copath/T1"],
           [__"A   $copath/T1",
            __"A   $copath/T1/T2"]);

is_output ($svk, 'st', [$copath],
	   [__"R + $copath/T1"]);

append_file ("$copath/T1/T2", "hate\n");
is_output ($svk, 'st', [$copath],
	   [__"R + $copath/T1",
	    __"M + $copath/T1/T2"]);
$svk->commit ('-m', 'commit', $copath);

is_ancestor ($svk, '//V/T1',
	     '/V/T2', 7);

$svk->cp('//V@5' => '//Y', -m => 'branch pre-replace');
is_output($svk, 'sm', ['//V@6' => '//Y', -m => 'merge dir->file replace'],
	  ['Auto-merging (5, 6) /V to /Y (base /V:5).',
	   'R   A',
	   qr'New merge ticket: .*:/V:6',
	   'Committed revision 11.']);

is_output($svk, 'merge', [-c => -11, '//Y' => '//Y',
			  -m => 'revert merge dir->file replace'],
	  ['R   A',
	   'A   A/be',
	   'A   A/neu',
	   'Committed revision 12.']);
chdir($copath);
$svk->sw('//Y');

is_output($svk, 'merge', [-c => 11, '//Y'],
	  ['R   A']);

is_output($svk, 'st', [],
	  ['R   A' ]);
ok(-f 'A');
is_output($svk, 'ci', [-m => 'message'],
	  ['Committed revision 13.']);

is_output($svk, 'merge', [-c => -11, '//Y'],
	  ['R   A',
	   __('A   A/be'),
	   __('A   A/neu')]);
ok(-d 'A');

is_output($svk, 'st', [],
	  ['R   A',
	   __('A   A/be'),
	   __('A   A/neu')]);
is_output($svk, 'ci', [-m => 'message'],
	  ['Committed revision 14.']);
