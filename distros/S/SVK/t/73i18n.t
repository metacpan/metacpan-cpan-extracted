#!/usr/bin/perl -w
use strict;
use Cwd;
use File::Path;
use SVK::Test;
use POSIX qw(setlocale LC_CTYPE);
setlocale (LC_CTYPE, $ENV{LC_CTYPE} = 'zh_TW.Big5')
    or plan skip_all => 'cannot set locale to zh_TW.Big5';
setlocale (LC_CTYPE, $ENV{LC_CTYPE} = 'en_US.UTF-8')
    or plan skip_all => 'cannot set locale to en_US.UTF-8';;
plan skip_all => "darwin wants all filenames in utf8." if $^O eq 'darwin';

plan tests => 54;
our ($answer, $output);

my $utf8 = SVK::Util::get_encoding;
ok($utf8 =~ m/utf-?8/);

my ($xd, $svk) = build_test();
my ($copath, $corpath) = get_copath ('i18n');

my $tree = create_basic_tree ($xd, '//');

$svk->checkout ('//A', $copath);

append_file ("$copath/Q/qu", "some changes\n");

my $msg = "\x{ab}\x{eb}"; # Chinese hate in big5
my $msgutf8 = '恨';

set_editor(<< "TMP");
\$_ = shift;
open _ or die \$!;
\@_ = ("I $msg software\n", <_>);
close _;
unlink \$_;
open _, '>', \$_ or die \$!;
print _ \@_;
close _;
TMP
is_output ($svk, 'cp', [-m => $msg, '--encoding', 'big5', '//A' => '//A-cp'],
	   ['Committed revision 3.']);

my $oldwd = Cwd::getcwd;
chdir ($copath);
is_output ($svk, 'commit', [],
	   ['Waiting for editor...',
	    qr'Commit message saved in (.*)\.',
	    "Can't decode commit message as $utf8.", "try --encoding.",
	   ]);
chdir ($oldwd);
is_output ($svk, 'commit', [$copath, '--encoding', 'big5'],
	   ['Waiting for editor...',
	    'Committed revision 4.']);
is_output_like ($svk, 'log', [-r4 => $copath],
		qr/\Q$msgutf8\E/);

is_output ($svk, 'mkdir', [-m => $msg, '--encoding', 'big5', "//A/$msgutf8-dir"],
	   ["Can't decode path as big5-eten."]);
is_output ($svk, 'mkdir', [-m => $msg, '--encoding', 'big5', "//A/$msg-dir"],
	   ['Committed revision 5.']);
$svk->up ($copath);
ok (-e "$copath/$msgutf8-dir");
overwrite_file ("$copath/$msgutf8-dir/newfile", "new file\n");
overwrite_file ("$copath/$msgutf8-dir/newfile2", "new file\n");
overwrite_file ("$copath/$msgutf8-dir/$msg", "new file\n"); # nasty file
is_output ($svk, 'add', ["$copath/$msgutf8-dir/$msg"],
	   [__"Can't decode path as $utf8."]);
is_output ($svk, 'add', ["$copath/$msgutf8-dir/newfile2"],
	   [__"$msg: Can't decode path as $utf8.",
	    __"A   $copath/$msgutf8-dir/newfile2"]);
is_output ($svk, 'st', [$copath],
	   [__"$msg: Can't decode path as $utf8.",
	    __"?   $copath/$msgutf8-dir/newfile",
	    __"A   $copath/$msgutf8-dir/newfile2"]);
is_output ($svk, 'ci', ['--import', '-m', 'hate', $copath],
	   [__"$msg: Can't decode path as $utf8."],
	   'import with bizzare filename is fatal.');
is_output ($svk, 'add', ["$copath/$msgutf8-dir"],
	   [__"$msg: Can't decode path as $utf8.",
	    __"A   $copath/$msgutf8-dir/newfile"]);
is_output ($svk, 'ls', ["//A/$msgutf8-dir"],
	   []);
is_output ($svk, 'ls', ["//A"],
	   ['Q/', 'be', "$msgutf8-dir/"]);
is_output ($svk, 'ls', ["//A/$msg-dir"],
	   ["Can't decode path as $utf8."]);
#### BEGIN big5 enivonrment
setlocale (LC_CTYPE, $ENV{LC_CTYPE} = 'zh_TW.Big5');
is_output_like ($svk, 'log', [-r4 => '//'],
		qr/\Q$msg\E/);
is_output_like ($svk, 'log', [-vr5 => '//'],
		qr/\Q$msg-dir\E/);

rmtree [$copath];
is_output ($svk, 'checkout', ['//A', $copath],
	   ["Syncing //A(/A) in $corpath to 5.",
	    __"A   $copath/Q",
	    __"A   $copath/Q/qu",
	    __"A   $copath/Q/qz",
	    __"A   $copath/be",
	    __"A   $copath/$msg-dir"], 'checkout reports files in native encoding');

ok (-e "$copath/$msg-dir", 'file checked out in filename of native encoding');
ok (!-e "$copath/$msgutf8-dir", 'not utf8');

overwrite_file ("$copath/$msg-dir/$msg", "with big5 filename\n");
is_output ($svk, 'st', [$copath],
	   [__"?   $copath/$msg-dir/$msg"]);
is_output ($svk, 'st', ["$copath/$msg-dir"],
	   [__"?   $copath/$msg-dir/$msg"]);
is_output ($svk, 'add', ["$copath/$msg-dir/$msg"],
	   [__"A   $copath/$msg-dir/$msg"]);

is_output ($svk, 'commit', ["$copath/$msg-dir"],
	   ['Waiting for editor...',
	    'Committed revision 6.']);
is_output ($svk, 'st', [$copath],
	   [], 'clean checkout after commit');
is_output ($svk, 'st', ["$copath/$msg-dir"],
	   [], 'clean checkout after commit');
is_output ($svk, 'rm', ["$copath/$msg-dir/$msg"],
	   [__"D   $copath/$msg-dir/$msg"]);
overwrite_file ("$copath/$msg-dir/$msg", "with big5 filename, replaced\n");
is_output ($svk, 'add', ["$copath/$msg-dir/$msg"],
	   [__"R   $copath/$msg-dir/$msg"]);
is_output ($svk, 'commit', ["$copath/$msg-dir"],
	   ['Waiting for editor...',
	    'Committed revision 7.']);
is_output ($svk, 'rm', ["$copath/$msg-dir/$msg"],
	   [__"D   $copath/$msg-dir/$msg"]);
is_output ($svk, 'commit', ["$copath/$msg-dir"],
	   ['Waiting for editor...',
	    'Committed revision 8.']);
is_output ($svk, 'mv', ["$copath/be" => "$copath/be-$msg"],
	   [__("A   $copath/be-$msg"),
	    __("D   $copath/be")]);
mkdir("$copath/sto");
overwrite_file ("$copath/sto/$msg", "with big5 filename\n");

is_output ($svk, 'commit', [-m => 'commit it', "$copath/be-$msg"],
	   ['Committed revision 9.']);

is_output ($svk, 'add', ["$copath/sto"],
	   [__("A   $copath/sto"),
	    __("A   $copath/sto/$msg")]);

is_output ($svk, 'commit', [-m => 'commit it', "$copath/sto"],
	   ['Committed revision 10.']);

is_output ($svk, 'cp', ["$copath/sto", "$copath/orz"],
	   [__("A   $copath/orz"),
	    __("A   $copath/orz/$msg")]);
is_output($svk, 'st', [$copath],
	   [__("A + $copath/orz"),
	    __("D   $copath/be")]);

is_output ($svk, 'revert', [-R => "$copath"],
	   [__("Reverted $copath/orz"),
	    __("Reverted $copath/be")]);
rmtree ["$copath/orz"];
is_output($svk, 'rm', ["$copath/sto"],
	   [__("D   $copath/sto"),
	    __("D   $copath/sto/$msg")]);

is_output($svk, 'st', ["$copath/sto"],
	   [__("D   $copath/sto"),
	    __("D   $copath/sto/$msg")]);

is_output($svk, 'revert', [-R => "$copath/sto"],
	   [__("Reverted $copath/sto"),
	    __("Reverted $copath/sto/$msg")]);

append_file("$copath/be-$msg", 'fooo');
is_output ($svk, 'ps', [foo => 'bar', "$copath/be-$msg"],
	   [__(" M  $copath/be-$msg")]);

is_output ($svk, 'revert', [-R => "$copath"],
	   [__("Reverted $copath/be-$msg")]);
is_output ($svk, 'mv', ["$copath/be-$msg", "$copath/$msg-dir"],
	   [__("A   $copath/$msg-dir/be-$msg"),
	    __("D   $copath/be-$msg")]);
is_output( $svk, 'st', [$copath],
	   [__("A + $copath/$msg-dir/be-$msg"),
	    __("D   $copath/be-$msg")]);
is_output ($svk, 'revert', [-R => "$copath"],
	   [__("Reverted $copath/$msg-dir/be-$msg"),
	    __("Reverted $copath/be-$msg")]);
unlink("$copath/$msg-dir/be-$msg");
$svk->cp (-m => "$msg hate", -r6 => '//A' => '//A-cp2');
$svk->smerge ('-I', '//A' => '//A-cp2');
is_output_like ($svk, 'log', [-r11 => '//'],
		qr/\Q$msg\E/);
is_output_like ($svk, 'log', [-r12 => '//'],
		qr/\Q$msg\E/);

is_output ($svk, 'st', ["$copath/$msg-dir"],
	   [], 'clean checkout after commit');
is_output ($svk, 'ls', ["//A/$msgutf8-dir"],
	   ["Can't decode path as big5-eten."]);
is_output ($svk, 'ls', ["//A"],
	   ['Q/', 'be', "be-$msg", "sto/", "$msg-dir/"]);
is_output ($svk, 'ls', ["//A/$msg-dir"],
	   []);

#### BEGIN latin-1 enivonrment
setlocale (LC_CTYPE, $ENV{LC_CTYPE} = 'en_US.ISO8859-1');
rmtree [$copath];
TODO: {
local $TODO = 'gracefully handle characters not in this locale';
is_output ($svk, 'checkout', ['//A', $copath],
	   ["Syncing //A(/A) in $corpath to 7.",
	    __"A   $copath/Q",
	    __"A   $copath/Q/qu",
	    __"A   $copath/Q/qz",
	    __"A   $copath/be",
	    __"    $copath/?-dir - skipped"],
	   'gracefully handle characters not in this locale');
}

# reset
setlocale (LC_CTYPE, $ENV{LC_CTYPE} = 'en_US.UTF-8');
