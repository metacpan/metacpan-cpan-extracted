#!/usr/bin/perl -w
use strict;
use SVK::Test;
plan tests => 70;

our $output;
my ($xd, $svk) = build_test();
my ($copath, $corpath) = get_copath ('commit');
my ($repospath, undef, $repos) = $xd->find_repos ('//', 1);

our $answer = 'c';

sub set_editor_foo
{
set_editor(<< 'TMP');
$_ = shift;
open _ or die $!;
# remove foo from the targets
@_ = grep !/foo/, <_>;
# simulate some editing, for --template test
s/monkey/gorilla/g for @_;
s/birdie/parrot/g for @_;
close _;
unlink $_;
open _, '>', $_ or die $!;
print _ @_;
close _;
print @_;
TMP
}

sub set_editor_verbose
{
set_editor(<< 'TMP');
$_ = shift;
open _ or die $!;
# remove foo from the targets
@_ = grep !/foo/, <_>;

die "Doesn't include unversioned file"
    unless grep {/verbose/} @_;

# simulate some editing, for --template test
s/monkey/gorilla/g for @_;
s/birdie/parrot/g for @_;
close _;
unlink $_;
open _, '>', $_ or die $!;
print _ @_;
close _;
print @_;
TMP
}

sub set_editor_verbose_add
{
set_editor(<< 'TMP');
$_ = shift;
open _ or die $!;
# remove foo from the targets
@_ = grep !/foo/, <_>;

# transparently add anything with verbose in the filename
for (@_) { s/^\? (?= .* verbose $ )/A/mx }

# simulate some editing, for --template test
s/monkey/gorilla/g for @_;
s/birdie/parrot/g for @_;
close _;
unlink $_;
open _, '>', $_ or die $!;
print _ @_;
close _;
print @_;
TMP
}
set_editor_foo();

$svk->checkout ('//', $copath);
is_output_like ($svk, 'commit', [], qr'not a checkout path');
chdir ($copath);
mkdir ('A');
mkdir ('A/deep');
mkdir ('A/deep/la');
overwrite_file ("A/foo", "foobar");
overwrite_file ("A/foo~", "foobar");
overwrite_file ("A/bar", "foobar");
overwrite_file ("A/deep/baz", "foobar");
overwrite_file ("A/deep/la/no", "foobar");

is_output ($svk, 'commit', [], ['No targets to commit.'], 'commit - no target');
$svk->add ('A');
$svk->commit ('-m', 'foo');
is_deeply($xd->{checkout}{sticky}, {});

is_output ($svk, 'status', [], []);
overwrite_file ("A/deep/baz", "fnord");
overwrite_file ("A/bar", "fnord");
overwrite_file ("A/deep/la/no", "fnord");
overwrite_file ("A/deep/X", "fnord");
overwrite_file ("A/deep/new", "fnord");
$svk->add ('A/deep/new');
$svk->ps ('dirprop', 'myvalue', 'A');
is_output ($svk, 'commit', ['-N', '-m', 'trying -N', 'A'],
	   ['Committed revision 2.']);
is_output ($svk, 'pl', ['-v', 'A'],
	   ['Properties on A:',
	    '  dirprop: myvalue']);
is_output ($svk, 'status', [],
	   [__('M   A/bar'),
	    __('M   A/deep/baz'),
	    __('M   A/deep/la/no'),
	    __('?   A/deep/X'),
	    __('A   A/deep/new')],
	   'commit -N');
$svk->commit ('-m', 'commit from deep anchor', 'A/deep');

$svk->update ('-r', 1);
overwrite_file ("A/barnew", "fnord");
$svk->add ('A/barnew');
$svk->commit ('-m', 'nonconflict new file', 'A/barnew');
overwrite_file ("A/deep/baz", "foobar\nmodified");
is_output ($svk, 'commit', ['-m', 'conflicted new file'],
	   [qr'Transaction is out of date: .*',
	    "Please update checkout first."],
	  'commit - need update');
$svk->revert ('A/deep/baz');
overwrite_file ("A/deep/new", "this is bad");
$svk->add ('A/deep/new');
is_output ($svk, 'commit', ['-m', 'conflicted new file'],
	   [qr'Item already exists.*',
	    "Please update checkout first."],
	  'commit - need update');
$svk->revert ('A/deep/new');
unlink ('A/deep/new');
is_output ($svk, 'status', [], [__('M   A/bar'),
				__('?   A/deep/X')]);

is_deeply ([$xd->{checkout}->find ($corpath, {revision => qr/.*/})],
	   [$corpath, __"$corpath/A/barnew"]);

$svk->rm ('A/foo');
$svk->commit ('-m', 'rm something', 'A/foo');
is_deeply ([$xd->{checkout}->find ($corpath, {revision => qr/.*/})],
	   [$corpath, __("$corpath/A/barnew"), __("$corpath/A/foo")]);
append_file ("A/bar", "this is bad");
is_output ($svk, 'commit', [-m => 'commit after certain rm', 'A'],
	   ['Committed revision 6.']);
is_output ($svk, 'st', [],
	   [__('?   A/deep/X')]);

SKIP: {
skip 'SVN::Mirror not installed', 1
    unless HAS_SVN_MIRROR;
# The '--sync' and '--merge' below would have no effect.
is_output ($svk, 'update', ['--sync', '--merge', $corpath], [
            "Syncing //(/) in $corpath to 6.",
            __"A   $corpath/A/deep/new",
            __"U   $corpath/A/deep/baz",
            __"U   $corpath/A/deep/la/no",
            __" U  $corpath/A",
           ]);
}
$svk->update ($corpath) unless HAS_SVN_MIRROR;
$svk->commit ('-m', 'the rest');

is_deeply ([$xd->{checkout}->find ($corpath, {revision => qr/.*/})], [$corpath]);
$svk->rm ('A/deep/la');
$svk->commit ('-m', 'remove something deep');
is_deeply ([$xd->{checkout}->find ($corpath, {revision => qr/.*/})], [$corpath]);

is_output ($svk, 'status', [],
	   [__('?   A/deep/X')]);

unlink ('A/barnew');
mkdir ('A/forimport');
overwrite_file ("A/forimport/foo", "fnord");
overwrite_file ("A/forimport/bar", "fnord");
overwrite_file ("A/forimport/baz", "fnord");
overwrite_file ("A/forimport/ss..", "fnord");

# XXX - This doesn't output anything!?!
is_output ($svk, 'commit', ['-C', '--import', '-m', 'commit --import',
			    'A/forimport', 'A/forimport/foo', 'A/forimport/bar', 'A/forimport/baz',
			    'A/barnew', 'A/forimport/ss..'],
	   []);

is_output ($svk, 'commit', ['--import', '-m', 'commit --import',
			    'A/forimport', 'A/forimport/foo', 'A/forimport/bar', 'A/forimport/baz',
			    'A/barnew', 'A/forimport/ss..'],
	   ['Committed revision 8.']);

is_output ($svk, 'status', [],
	   [__('?   A/deep/X')]);

is_output ($svk, 'commit', ['--import', '-m', 'commit --import monkey', '--template', 'A/deep/X'],
	   ['Waiting for editor...',
	    'Committed revision 9.']);

is_output_like ($svk, 'log', [-r => 9, 'A/deep/X'],
		qr/commit --import gorilla/, 'template works for commit --import');

is_output ($svk, 'status', [], []);
unlink ('A/forimport/foo');

is_output ($svk, 'commit', ['--import', '-m', 'commit --import', 'A/forimport/foo'],
	   ['Committed revision 10.']);
mkdir ('A/newdir');
overwrite_file ("A/newdir/bar", "fnord");
is_output ($svk, 'commit', ['--import', '-m', 'commit --import', 'A/newdir/bar'],
	   ['Committed revision 11.']);
is_output ($svk, 'status', [], [], 'import finds anchor');
# XXX: uncomment this to see post-commit subdir checkout optimization bug
#$svk->update ('-r9');

overwrite_file ("A/foo", "foobar");
overwrite_file ("A/bar", "foobar");
$svk->add("A/foo", "A/bar");
$svk->commit ('-m', 'foo');

append_file ("A/foo", "foobar2");
append_file ("A/bar", "foobar2");
$svk->ps ('bar', 'foo', '.');
is_output ($svk, 'commit', ['-m', 'bozo', 'A/bar', '.'],
	   ['Committed revision 13.']);
is_output ($svk, 'status', [],
	   [], 'commit A/bar . means .' );
is_output ($svk, 'pl', ['-v', '.'],
	   ['Properties on .:',
	    '  bar: foo']);
append_file ("A/bar", "foobar2");
append_file ("A/foo", "foobar2");
$svk->ps ('bar', 'bozo', '.');
is_output ($svk, 'commit', ['-N', '-m', 'bozo', 'A/bar', '.'],
	   ['Committed revision 14.']);
is_output ($svk, 'status', [],
	   [__('M   A/foo')]);
is_output ($svk, 'pl', ['-v', '.'],
	   ['Properties on .:',
	    '  bar: bozo']);

append_file ("A/bar", "foobar2");
$svk->ps ('bar', 'foo', '.');

is_output ($svk, 'st', [],
	   [__('M   A/bar'),
	    __('M   A/foo'),
	    ' M  .']);

is_output ($svk, 'commit', [],
	   ['Waiting for editor...',
	    'Committed revision 15.']);

is_output ($svk, 'pl', ['-v', '.'],
	   ['Properties on .:',
	    '  bar: foo']);
is_output ($svk, 'st', [],
	   [__('M   A/foo')]);

is_output ($svk, 'commit', [],
	   ['Waiting for editor...',
	    'No targets to commit.'], 'target edited to empty');
is_output ($svk, 'st', [],
	   [__('M   A/foo')]);

# test verbose with one unversioned file {{{
set_editor_verbose();

overwrite_file("A/verbose", "this is for testing that verbose commits (those including ? files) work");

is_output ($svk, 'status', [],
	   [__('M   A/foo'),
        __('?   A/verbose')]);

is_output ($svk, 'commit', [],
	   ['Waiting for editor...',
	    'No targets to commit.'], 'target edited to empty');

overwrite_file("A/oof", "ouchies!");
$svk->add("A/oof");
is_output ($svk, 'commit', [],
	   ['Waiting for editor...',
	    'Committed revision 16.'], 'commit message included unversioned A/verbose');
is_output ($svk, 'status', [],
	   [__('M   A/foo'),
        __('?   A/verbose')]);
unlink "A/verbose";
# }}}
# test verbose with an unversioned subdirectory {{{
mkdir ('A/deep/verbose');
overwrite_file("A/deep/verbose/uno", "fun fun");
overwrite_file("A/deep/verbose/dos", "fun *squared*");

is_output ($svk, 'status', [],
	   [ __('?   A/deep/verbose'),
         __('M   A/foo')]);

is_output ($svk, 'commit', [],
	   ['Waiting for editor...',
	    'No targets to commit.'], 'target edited to empty');

overwrite_file("A/oof", "oh ok");
is_output ($svk, 'commit', [],
	   ['Waiting for editor...',
	    'Committed revision 17.'], 'commit message included unversioned subdir A/verbose/ and its two unversioned files');

is_output ($svk, 'status', [],
	   [__('?   A/deep/verbose'),
        __('M   A/foo')]);

unlink "A/deep/verbose/uno";
unlink "A/deep/verbose/dos";
rmdir "A/deep/verbose/";
# }}}

# test transparent adds with verbose commits {{{
set_editor_verbose_add();

overwrite_file("A/verbose", "this is for testing that verbose commits (those including ? files) work");

is_output ($svk, 'status', [],
	   [__('M   A/foo'),
        __('?   A/verbose')]);

is_output ($svk, 'commit', [],
	   ['Waiting for editor...', __('A   A/verbose'),
	    'Committed revision 18.'], 'we got a commit by replacing a ? with an A');

is_output ($svk, 'status', [],
	   [__('M   A/foo')]);

overwrite_file("A/verbose", "you know the drill");

is_output ($svk, 'status', [],
	   [__('M   A/foo'),
        __('M   A/verbose')]);
$svk->revert('A/verbose');
# }}}

set_editor_foo();

append_file ("A/foo", "foobar2");
is_output ($svk, 'status', [],
	   [__('M   A/foo')]);

$svk->ps ('foo', 'bar', '.');
is_output ($svk, 'status', [],
	   [__('M   A/foo'),
	    ' M  .']);
$svk->commit;

is_output ($svk, 'status', [],
	   [__('M   A/foo')]);
is_output ($svk, 'pl', ['-v', '.'],
	   ['Properties on .:',
	    '  bar: foo',
	    '  foo: bar']);

overwrite_file ("A/bar", "foobar");
$svk->pd ('bar', '.');
is_output ($svk, 'st', [],
	   [__('M   A/bar'),
	    __('M   A/foo'),
	    ' M  .']);
$svk->commit;
is_output ($svk, 'status', [],
	   [__('M   A/foo')]);

$svk->revert ('-R');
append_file ("A/bar", "foobar2");
is_output ($svk, 'commit', [],
	   ['Waiting for editor...',
	    'Committed revision 21.'], 'buffer unmodified');
$answer = 'a';
append_file ("A/bar", "foobar2");
is_output ($svk, 'commit', [],
	   ['Waiting for editor...',
	    'Aborted.'], 'buffer unmodified');

overwrite_file ('svk-commit', 'my log message');

is_output ($svk, 'commit', [-F => 'svk-commit', -m => 'hate'],
	   ["Can't use -F with -m."]);

is_output ($svk, 'commit', [-F => 'svk-commit'],
	   ['Committed revision 22.'], 'commit with -F');

is_output_like ($svk, 'log', [-r => 22],
		qr/my log message/);

append_file ("A/bar", "please be changed");
is_output($svk, 'commit', [-m => "i like a monkey\nand a birdie", '--template'],
          ["Waiting for editor...",
	   "Committed revision 23."], 'commit with -m and --template');

is_output_like ($svk, 'log', [-r => 23],
		qr/i like a gorilla/, 'first line successfully edited from template');

is_output_like ($svk, 'log', [-r => 23],
		qr/and a parrot/, 'second line successfully edited from template');

append_file ("A/bar", "changed some more");
overwrite_file ('svk-commit', "this time it's a birdie\nalso a monkey");

is_output($svk, 'commit', [-F => 'svk-commit', '--template'],
          ["Waiting for editor...",
	   "Committed revision 24."], 'commit with -F and --template');

is_output_like ($svk, 'log', [-r => 24],
		qr/this time it's a parrot/, 'first line successfully edited from template');

is_output_like ($svk, 'log', [-r => 24],
		qr/also a gorilla/, 'second line successfully edited from template');

overwrite_file("changeme", 'to be committed with revprop');
$svk->add("changeme");

is_output($svk, 'commit', [-m => 'with revprop', '--set-revprop', 'fnord=baz'],
          ["Committed revision 25."], 'fnord');

is_output(
    $svk, 'pl', ['-r' => 25, '--revprop'],
    ['Unversioned properties on revision 25:',
     '  fnord',
     '  svn:author',
     '  svn:date',
     '  svn:log',
    ],
);
