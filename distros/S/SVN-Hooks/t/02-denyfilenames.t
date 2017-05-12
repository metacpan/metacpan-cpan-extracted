# -*- cperl -*-

use strict;
use warnings;
use lib 't';
use Test::More;

require "test-functions.pl";

if (can_svn()) {
    plan tests => 14;
}
else {
    plan skip_all => 'Cannot find or use svn commands.';
}

my $t    = reset_repo();
my $wc   = catdir($t, 'wc');
my $file = catfile($wc, 'file');

set_hook(<<'EOS');
use SVN::Hooks::DenyFilenames;
EOS

set_conf(<<'EOS');
DENY_FILENAMES('string');
EOS

work_nok('cant parse config', 'DENY_FILENAMES: got "string" while expecting a qr/Regex/ or a', <<"EOS");
echo txt >$file
svn add -q --no-auto-props $file
svn ci -mx $file
EOS

set_conf(<<'EOS');
DENY_FILENAMES(qr/[^a-z0-9]/i, qr/substring/, [qr/custommessage/ => 'custom message']);
EOS

work_ok('valid', <<"EOS");
svn ci -mx $file
EOS

work_nok('invalid', 'DENY_FILENAMES: filename not allowed: file', <<"EOS");
echo txt >${file}_
svn add -q --no-auto-props ${file}_
svn ci -mx ${file}_
EOS

my $withsubstringinthemiddle = catfile($wc, 'withsubstringinthemiddle');
work_nok('second invalid', 'DENY_FILENAMES: filename not allowed: withsubstringinthemiddle', <<"EOS");
echo txt >$withsubstringinthemiddle
svn add -q --no-auto-props $withsubstringinthemiddle
svn ci -mx $withsubstringinthemiddle
EOS

my $withcustommessage = catfile($wc, 'withcustommessage');
work_nok('custom message', 'DENY_FILENAMES: custom message: withcustommessage', <<"EOS");
echo txt >$withcustommessage
svn add -q --no-auto-props $withcustommessage
svn ci -mx $withcustommessage
EOS

# PER PATH

set_conf(<<'EOS');
DENY_FILENAMES_PER_PATH('string');
EOS

work_nok('odd config', 'DENY_FILENAMES_PER_PATH: got odd number of arguments', <<"EOS");
svn revert -q ${file}_ $withsubstringinthemiddle $withcustommessage
echo newtxt >$file
svn add -q --no-auto-props $file
svn ci -mx $file
EOS

set_conf(<<'EOS');
DENY_FILENAMES_PER_PATH('bogus' => qr/check/);
EOS

work_nok('no regex', 'DENY_FILENAMES_PER_PATH: rule prefix isn\'t a Regexp.', <<"EOS");
svn ci -mx $file
EOS

set_conf(<<'EOS');
DENY_FILENAMES([qr/c/ => 'no c']);
DENY_FILENAMES_PER_PATH(qr:^A: => qr/a/, qr:^B: => [qr/b/ => 'no b']);
EOS

my $adir = catdir($wc, 'A');
my $bdir = catdir($wc, 'B');
my $cdir = catdir($wc, 'C');
work_ok('valid', <<"EOS");
svn mkdir $adir $bdir $cdir
svn ci -mx -q $wc
svn ci -mx $file
EOS

my $afile = catfile($adir, 'a');
work_nok('invalid a', 'filename not allowed', <<"EOS");
echo txt >$afile
svn add -q --no-auto-props $afile
svn ci -mx $afile
EOS

my $avalid = catfile($adir, 'vld');
work_ok('valid a', <<"EOS");
svn revert $afile
echo txt >$avalid
svn add -q --no-auto-props $avalid
svn ci -mx $avalid
EOS

my $bfile = catfile($bdir, 'b');
work_nok('invalid b', ': no b:', <<"EOS");
echo txt >$bfile
svn add -q --no-auto-props $bfile
svn ci -mx $bfile
EOS

my $bvalid = catfile($bdir, 'vld');
work_ok('valid b', <<"EOS");
svn revert $bfile
echo txt >$bvalid
svn add -q --no-auto-props $bvalid
svn ci -mx $bvalid
EOS

my $cfile = catfile($cdir, 'c');
work_nok('invalid c', ': no c:', <<"EOS");
echo txt >$cfile
svn add -q --no-auto-props $cfile
svn ci -mx $cfile
EOS

my $cvalid = catfile($cdir, 'vld');
work_ok('valid c', <<"EOS");
svn revert $cfile
echo txt >$cvalid
svn add -q --no-auto-props $cvalid
svn ci -mx $cvalid
EOS

