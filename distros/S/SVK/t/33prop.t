#!/usr/bin/perl -w
use Test::More tests => 55;
use strict;
use File::Temp;
use SVK::Test;

my ($xd, $svk) = build_test();
our $output;
my ($copath, $corpath) = get_copath ('prop');
my ($repospath, undef, $repos) = $xd->find_repos ('//', 1);
$svk->checkout ('//', $copath);
mkdir "$copath/A";
overwrite_file ("$copath/A/foo", "foobar");
overwrite_file ("$copath/A/bar", "foobarbazz");
is_output_like ($svk, 'ps', [], qr'SYNOPSIS', 'ps - help');
is_output_like ($svk, 'pe', [], qr'SYNOPSIS', 'ps - help');
is_output_like ($svk, 'pe', ['foo','bar','baz'], qr'SYNOPSIS', 'ps - help');
is_output_like ($svk, 'propdel', [], qr'SYNOPSIS', 'propdel - help');
is_output_like ($svk, 'pg', [], qr'SYNOPSIS', 'pg - help');

is_output_like ($svk, 'pl', ["$copath/A"], qr'not found');

$svk->add ($copath);
is_output ($svk, 'pl', ["$copath/A"],
	   []);
is_output ($svk, 'pl', ["$copath/A/foo"],
	   []);
$svk->commit ('-m', 'commit', $copath);
is_output ($svk, 'pl', ["$copath/A"],
	   []);

is_output ($svk, 'ps', ['myprop', 'myvalue', "$copath/A/unknown"],
	   [__("$copath/A/unknown is not under version control.")]);

overwrite_file ("$copath/A/unknown", 'foo');
is_output ($svk, 'ps', ['myprop', 'myvalue', "$copath/A/unknown"],
	   [__("$copath/A/unknown is not under version control.")]);

$svk->rm ("$copath/A/foo");
is_output ($svk, 'ps', ['myprop', 'myvalue', "$copath/A/foo"],
	   [__("$copath/A/foo is already scheduled for delete.")]);

$svk->revert (-R => $copath);

is_output ($svk, 'ps', ['-q', 'myprop', 'myvalue', "$copath/A"],
	   []);

is_output ($svk, 'ps', ['myprop', 'myvalue', "$copath/A"],
	   [__(" M  $copath/A")]);

is_output ($svk, 'pl', ["$copath/A"],
	   [__("Properties on $copath/A:"),
	    '  myprop']);

is_output ($svk, 'pl', ['-v', "$copath/A"],
	   [__("Properties on $copath/A:"),
	    '  myprop: myvalue']);

is_output ($svk, 'pg', ['myprop', "$copath/A"],
	   ['myvalue']);
is_output ($svk, 'pg', [-R => 'myprop', "$copath"],
	   [__('t/checkout/prop/A - myvalue')]);

$svk->commit ('-m', 'commit', $copath);

is_output ($svk, 'ps', ['thisprop', 'thisvalue', "$copath/A", "$copath/A/foo"],
	   [__(" M  $copath/A"),
	    __(" M  $copath/A/foo")]);

$svk->revert (-R => $copath);

is_output ($svk, 'ps', ['myprop', 'myvalue2', "$copath/A"],
	   [__(" M  $copath/A")]);
is_output ($svk, 'pl', ['-v', "$copath/A"],
	   [__("Properties on $copath/A:"),
	    '  myprop: myvalue2']);
is_output ($svk, 'pg', ['myprop', "$copath/A"],
	   ['myvalue2']);
is_output ($svk, 'pl', ['-v', "//A"],
	   ["Properties on //A:",
	    '  myprop: myvalue']);
is_output ($svk, 'pg', ['myprop', "//A"],
	   ['myvalue']);
is_output ($svk, 'pg', ['myprop', "$copath/A", "//A"],
	   [__("$copath/A - myvalue2"),
            '//A - myvalue']);
is_output ($svk, 'pg', ['--strict', 'myprop', "$copath/A", "//A"],
	   ['myvalue2myvalue']);
$svk->revert ("$copath/A");
is_output ($svk, 'ps', ['myprop2', 'myvalue2', "$copath/A"],
	   [__(" M  $copath/A")]);
is_output ($svk, 'pl', ['-v', "$copath/A"],
	   [__("Properties on $copath/A:"),
	    '  myprop: myvalue',
	    '  myprop2: myvalue2']);
is_output ($svk, 'propdel', ['--quiet', 'myprop', "$copath/A"],
	   []);
is_output ($svk, 'propdel', ['myprop', "$copath/A"],
	   [__(" M  $copath/A")]);
is_output ($svk, 'pl', ['-v', "$copath/A"],
	   [__("Properties on $copath/A:"),
	    '  myprop2: myvalue2']);
is_output ($svk, 'pl', ['-v', "//A"],
	   ["Properties on //A:",
	    '  myprop: myvalue']);

$svk->commit ('-m', 'commit', $copath);
is_output ($svk, 'pl', ['-v', "//A"],
	   ["Properties on //A:",
	    '  myprop2: myvalue2']);
is_output ($svk, 'ps', ['-m', 'direct', 'direct', 'directly', '//A'],
	   ['Committed revision 4.']);
is_output ($svk, 'ps', ['-m', 'direct', 'direct', 'directly', '//A/foo'],
	   ['Committed revision 5.']);
#	   [' M  A']);
is_output_like ($svk, 'ps', ['-m', 'direct', 'direct', 'directly', '//A/non'],
		qr'Filesystem has no item');
is_output ($svk, 'pl', ['-v', "//A"],
	   ["Properties on //A:",
	    '  direct: directly',
	    '  myprop2: myvalue2']);

is_output ($svk, 'propdel', ['-m', 'direct', 'direct','//A'],
	   ['Committed revision 6.']);
#	   [' M  A']);
$svk->update ($copath);
is_output ($svk, 'pl', ['-v', "//A"],
	   ["Properties on //A:",
	    '  myprop2: myvalue2']);

is_output ($svk, 'pl', ['-v', '-r1', '//A'],
	   []);
is_output ($svk, 'pl', ['-v', '-r1', "$copath/A"],
	   []);
is_output ($svk, 'pl', ['-v', '-r2', '//A'],
	   ["Properties on //A:",
	    '  myprop: myvalue']);
is_output ($svk, 'pl', ['-v', '-r2', "$copath/A"],
	   ["Properties on //A:",
	    '  myprop: myvalue']);

set_editor(<< 'TMP');
$_ = shift;
open _ or die $!;
@_ = ("prepended_prop\n", <_>);
close _;
unlink $_;
open _, '>', $_ or die $!;
print _ @_;
close _;
TMP

is_output ($svk, 'pe', ['-r2', 'newprop', "$copath/A"],
	   [qr'not allowed']);

is_output ($svk, 'pe', ['newprop', "$copath/A"],
	   ['Waiting for editor...',
	    __(" M  $copath/A")]);

is_output ($svk, 'pl', ['-v', "$copath/A"],
	   [__("Properties on $copath/A:"),
	    '  myprop2: myvalue2',
	    '  newprop: prepended_prop',
	    '']);
is_output ($svk, 'pe', ['myprop2', "$copath/A"],
	   ['Waiting for editor...',
	    __(" M  $copath/A")]);
is_output ($svk, 'pl', ['-v', "$copath/A"],
	   [__("Properties on $copath/A:"),
	    '  myprop2: prepended_prop',
	    'myvalue2',
	    '  newprop: prepended_prop',
	    '']);

$svk->commit ('-m', 'commit after propedit', $copath);

is_output ($svk, 'pe', ['-m', 'commit with pe', 'pedirect', "//A"],
	   ['Waiting for editor...',
	    'Committed revision 8.']);

is_output ($svk, 'pl', ['-v', "$copath/A"],
	   [__("Properties on $copath/A:"),
	    '  myprop2: prepended_prop',
	    'myvalue2',
	    '  newprop: prepended_prop',
	    '']);

$svk->update ($copath);

is_output ($svk, 'pl', ['-v', "$copath/A"],
	   [__("Properties on $copath/A:"),
	    '  myprop2: prepended_prop',
	    'myvalue2',
	    '  newprop: prepended_prop', '',
	    '  pedirect: prepended_prop', '']);
chdir ("$copath/A");

is_output ($svk, 'pl', ['-v'],
	   [__("Properties on .:"),
	    '  myprop2: prepended_prop',
	    'myvalue2',
	    '  newprop: prepended_prop', '',
	    '  pedirect: prepended_prop',
	    '']);

is_output ($svk, 'pg', ['myprop2'], ['prepended_prop', 'myvalue2']);
is_output ($svk, 'pg', ['-r1', 'myprop2'], []);
is_output ($svk, 'pg', ['nosuchprop'], []);

