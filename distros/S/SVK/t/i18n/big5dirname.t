#!/usr/bin/perl -w
use strict;
use SVK::Util qw( to_native from_native);
use SVK::Test;
#plan skip_all => "Only needed to test on win32" unless IS_WIN32;

use POSIX qw(setlocale LC_CTYPE);
setlocale (LC_CTYPE, $ENV{LC_CTYPE} = 'zh_TW.Big5')
    or plan skip_all => 'cannot set locale to zh_TW.Big5';
plan skip_all => "darwin wants all filenames in utf8." if $^O eq 'darwin';

plan tests => 10;
our $output;

my $big5dir = "\x{b7}\x{7c}\x{b1}\x{e0}"; # meeting , contains a '|' character
my $file = "\x{a4}\x{a4}\x{a4}\x{e5}.txt"; # Chinese
my $file2 = "\x{b6}\x{7d}\x{b7}\x{7c}.txt"; # meeting
mkpath ["t/checkout/filenames/$big5dir"], 0, 0700 unless -d "t/checkout/filenames/$big5dir";

my ($xd, $svk) = build_test('dirname_enc');
my ($copath, $corpath) = get_copath();
my ($repospath, $path, $repos) = $xd->find_repos ('/dirname_enc/', 1);
sub copath { SVK::Path::Checkout->copath($copath, @_) }

$svk->checkout ('//', $copath);

my $filename = $file;
overwrite_file ("$copath/$file", "new file to add\n");
overwrite_file ("$copath/$file2", "new file2 to add\n");
chdir($copath);

is_output ($svk, 'add', [ $file],
           ['A   '.$file]);
is_output ($svk, 'add', [ $file2],
           ['A   '.$file2]);
chdir('..');
is_output($svk, 'ci', [-m => 'commit single checkout', $big5dir],
          ['Committed revision 1.']);
chdir($big5dir);
append_file($file, "change single file\n");

from_native($filename);
append_file($file, "utf8 filename: $filename\n");
is_output($svk, 'diff', [$file],
          ['=== '.$filename,
           '==================================================================',
           "--- $file\t(revision 1)",
           "+++ $file\t(local)",
           '@@ -1 +1,3 @@',
           ' new file to add',
           '+change single file',
           '+utf8 filename: '.$filename,
          ]);
is_output($svk, 'ci', [-m => 'commit single checkout', $file],
          ['Committed revision 2.']);

chdir ('../../../../');
$svk->update ('-r', 1, $copath);
chdir($copath);
is_file_content ("$file", "new file to add\n");

overwrite_file ("$file",
                "hihi\n");
our $answer = [ 'd', 'y' ];
chdir ('../../../../');
$svk->update ($copath); # XXX use is_ouptut to compare conflict diff header
ok ($output =~ m/1 conflict found\./, 'conflict');

$svk->revert ($copath);
$svk->resolved ($copath);
$svk->update ($copath); # XXX use is_ouptut to compare conflict diff header
append_file("$copath/$file2", "big5 filename: $file2\n");
chdir($copath);
chdir('..');
$filename = "$big5dir/$file2";
from_native($filename);
is_output($svk, 'diff', ["$big5dir/$file2"],
          ['=== '.$filename,
           '==================================================================',
           "--- $big5dir/$file2\t(revision 2)",
           "+++ $big5dir/$file2\t(local)",
           '@@ -1 +1,2 @@',
           ' new file2 to add',
           '+big5 filename: '.$file2,
          ]);
is_output($svk, 'ci', [-m => 'commit diff checkout', $big5dir],
          ['Committed revision 3.']);

chdir('../../../');
$svk->update ('-r', 2, $copath);
append_file("$copath/$file2", "big5 filename: $file2\n");
$svk->update ($copath); 
ok ($output =~ m#g   t/checkout/filenames/$big5dir/$file2#, 'merged');
