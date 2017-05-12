#!/usr/bin/perl -w
use strict;
use Test::More tests => 27;
use SVK::Test;

my ($xd, $svk) = build_test();

my $tree = create_basic_tree ($xd, '//');
my ($copath, $corpath) = get_copath ('keyword');
our $output;
$svk->checkout ('//', $copath);

is_file_content ("$copath/A/be",
		 "\$Rev: 1 \$ \$Revision: 1 \$\n\$FileRev: #1 \$\nfirst line in be\n2nd line in be\n",
		 'basic Id');
append_file ("$copath/A/be", "some more\n");
append_file ("$copath/A/be", "my \$Rev = \$Revision ? \$Revision : \$VERSION;\n");
$svk->ps ('svn:executable', 'on', "$copath/A/be");
ok (_x("$copath/A/be"), 'svn:excutable effective after ps');
$svk->commit ('-m', 'some modifications', $copath);
ok (_x("$copath/A/be"), 'take care of svn:executable after commit');

my $newcontent = "\$Rev: 3 \$ \$Revision: 3 \$\n\$FileRev: #2 \$\nfirst line in be\n2nd line in be\nsome more\nmy \$Rev = \$Revision ? \$Revision : \$VERSION;\n";

is_file_content ("$copath/A/be", $newcontent, 'commit Id');

append_file ("$copath/A/be", "some more\n");
$svk->revert ("$copath/A/be");
is_file_content ("$copath/A/be", $newcontent, 'commit Id');

ok (_x("$copath/A/be"), 'take care of svn:executable after revert');
append_file ("$copath/A/be", "some more\n");
$svk->commit ('-m', 'some more modifications', $copath);

is_file_content ("$copath/A/be",
		 "\$Rev: 4 \$ \$Revision: 4 \$\n\$FileRev: #3 \$\nfirst line in be\n2nd line in be\nsome more\nmy \$Rev = \$Revision ? \$Revision : \$VERSION;\nsome more\n");
$svk->update ('-r', 3, $copath);
ok (_x("$copath/A/be"), 'take care of svn:executable after update');
is_file_content ("$copath/A/be", $newcontent, 'commit Id');

my $cofile = __"$copath/A/be";
is_output_like ($svk, 'update', ['-r', 2, $copath], qr|^UU  \Q$cofile\E$|m,
		'keyword does not cause merge');

ok (not_x("$copath/A/be"), 'take care of removing svn:executable after update');
overwrite_file ("$copath/A/foo", "\$Rev: 999 \$");
$svk->add ("$copath/A/foo");
$svk->commit ('-m', 'adding a file', $copath);

is_file_content ("$copath/A/foo", "\$Rev: 999 \$", 'commit unreverted ref');
append_file ("$copath/A/foo", "some more\n");
$svk->ps ('svn:keywords', 'Rev', "$copath/A/foo");
$svk->commit ('-m', 'appending a file and change props', $copath);
is_file_content ("$copath/A/foo", "\$Rev: 6 \$some more\n");
is_output ($svk, 'st', ["$copath/A/foo"], [], 'commit does keyword expansion - rev');
append_file ("$copath/A/foo", "<!-- \$Id\$ -->\n");
$svk->ps ('svn:keywords', 'Rev Id', "$copath/A/foo");
$svk->commit ('-m', 'test $Id$', $copath);
is_output ($svk, 'st', ["$copath/A/foo"], [], 'commit does keyword expansion - id');

my ($CR, $LF, $CRLF) = ("\015", "\012", "\015\012");
my $Native = (
    ($^O =~ /^(?:MSWin|cygwin|dos|os2)/) ? $CRLF :
    ($^O =~ /^MacOS/) ? $CR : $LF
);

mkdir ("$copath/le");
overwrite_file_raw ("$copath/le/dos", "dos$CR");
overwrite_file_raw ("$copath/le/unix", "unix$CR");
overwrite_file_raw ("$copath/le/mac", "mac$CRLF");
overwrite_file_raw ("$copath/le/native", "native$Native");
overwrite_file_raw ("$copath/le/na", "na$CR");
overwrite_file_raw ("$copath/le/mixed", "mixed$CRLF...endings$CR...");
$svk->add ("$copath/le");
$svk->ps ('svn:eol-style', 'CRLF', "$copath/le/dos");
$svk->ps ('svn:eol-style', 'native', "$copath/le/native");
$svk->ps ('svn:eol-style', 'LF', "$copath/le/unix");
$svk->ps ('svn:eol-style', 'CR', "$copath/le/mac");
$svk->ps ('svn:eol-style', 'NA', "$copath/le/na");
$svk->commit ('-m', 'test line ending', $copath);

is_file_content_raw ("$copath/le/na", "na$CR");
SKIP: {
# we don't update eolstyle=native files on lf-platforms,
# or eolstyle=crlf files on crlf-platforms.
# this should be done with checkout_delta/commit harvesting
# the translated md5 to decide if they should be updated.
skip 'fix inconsistent eol-style after commit', 3;

is_file_content_raw ("$copath/le/dos", "dos$CRLF");
is_file_content_raw ("$copath/le/unix", "unix$LF");
is_file_content_raw ("$copath/le/mac", "mac$CR");
}

is_file_content_raw ("$copath/le/native", "native$Native");

$svk->ps ('svn:eol-style', 'CRLF', "$copath/le/native");
$svk->commit ('-m', 'test line ending', $copath);
is_file_content_raw ("$copath/le/native", "native$CRLF");


is_output ($svk, 'ps', ['svn:eol-style', 'native', "$copath/le/mixed"],
	   [__"File $copath/le/mixed has inconsistent newlines."]);
overwrite_file_raw ("$copath/le/mixed", '');
is_output ($svk, 'ps', ['svn:eol-style', 'native', "$copath/le/mixed"],
	   [__" M  $copath/le/mixed"]);
overwrite_file_raw ("$copath/le/mixed", "mixed$CRLF...endings$CR...");

$svk->commit ('-m', 'test line ending', $copath);
SKIP: {
skip 'fix inconsistent eol-style after commit', 1;
is_file_content_raw ("$copath/le/mixed", "mixed$Native...endings$Native...");
}

overwrite_file_raw ("$copath/le/mixed2", '');
$svk->add ("$copath/le");
$svk->ci (-m => 'some mixed le in repository', $copath );
$svk->cp (-m => 'tmp', '//le' => '//le2');
overwrite_file_raw ("$copath/le/mixed2", "mixed$CRLF...endings$CR...");
$svk->ci (-m => 'some mixed le in repository', $copath );
$svk->up ($copath);
$svk->ps ('svn:eol-style', 'native', "$copath/le2/mixed2");
$svk->ci (-m => 'some mixed le in repository', $copath );

$svk->sm (-m => 'move eol prop around', -f => '//le2');

$svk->up ($copath);
# XXX: need to do rmcache here to make the file properly modified
$svk->admin ('rmcache');
is_output ($svk, 'st', [$copath],
	   [__"M   $copath/le/mixed2"]);

rmtree [$copath];

$svk->checkout ('//', $copath);
$svk->admin ('rmcache');
is_output ($svk, 'st', [$copath],
	   [__"M   $copath/le/mixed2"]);

$svk->commit (-m => 'fix eol', $copath);
$svk->admin ('rmcache');
is_output ($svk, 'st', [$copath], []);
