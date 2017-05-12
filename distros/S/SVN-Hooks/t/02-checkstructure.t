# -*- cperl -*-

use strict;
use warnings;
use lib 't';
use Test::More;

require "test-functions.pl";

if (can_svn()) {
    plan tests => 13;
}
else {
    plan skip_all => 'Cannot find or use svn commands.';
}

my $t    = reset_repo();
my $wc   = catdir($t, 'wc');
my $file = catfile($wc, '_');

set_hook(<<'EOS');
use SVN::Hooks::CheckStructure;
EOS

set_conf(<<'EOS');
CHECK_STRUCTURE(
    [
	_invalid_rhs => 'invalid rhs',
	_deny => 0,
	_allow => 1,
	_file => 'FILE',
	_dir => 'DIR',
	sub1 => [
	    sub2 => [
		sub3 => [
		],
	    ],
	],
	qr/regex/ => [
	    _just => 1,
	    0 => 'custom error message',
	],
	1 => 'DIR',
    ],
);
EOS

work_nok('invalid_rhs', 'syntax error: unknown string spec (invalid rhs)', <<"EOS");
echo txt >${file}invalid_rhs
svn add -q --no-auto-props ${file}invalid_rhs
svn ci -mx ${file}invalid_rhs
EOS

work_nok('deny 0', 'invalid path', <<"EOS");
echo txt >${file}deny
svn add -q --no-auto-props ${file}deny
svn ci -mx ${file}deny
EOS

work_ok('allow 1', <<"EOS");
echo txt >${file}allow
svn add -q --no-auto-props ${file}allow
svn ci -mx ${file}allow
EOS

work_nok('is not file', 'the component (_file) should be a FILE in', <<"EOS");
mkdir ${file}file
svn add -q --no-auto-props ${file}file
svn ci -mx ${file}file
EOS

work_ok('is file', <<"EOS");
svn rm -q --force ${file}file
echo txt >${file}file
svn add -q --no-auto-props ${file}file
svn ci -mx ${file}file
EOS

work_nok('is not dir', 'the component (_dir) should be a DIR in', <<"EOS");
echo txt >${file}dir
svn add -q --no-auto-props ${file}dir
svn ci -mx ${file}dir
EOS

work_ok('is dir', <<"EOS");
svn rm -q --force ${file}dir
mkdir ${file}dir
svn add -q --no-auto-props ${file}dir
svn ci -mx ${file}dir
EOS

my $sub1 = catdir($wc, 'sub1');
my $sub2 = catdir($sub1, 'sub2');
my $sub3 = catdir($sub2, 'sub3');

work_ok('allow sub', <<"EOS");
mkdir $sub1 $sub2 $sub3
svn add -q --no-auto-props $sub1
svn ci -mx $sub1
EOS

my $deny = catfile($sub2, '_deny');

work_nok('deny sub', 'the component (_deny) is not allowed in', <<"EOS");
echo txt >$deny
svn add -q --no-auto-props $deny
svn ci -mx $deny
EOS

my $preregexsuf = catdir($wc, 'preregexsuf');
my $just        = catfile($preregexsuf, '_just');

work_ok('regex allow', <<"EOS");
mkdir $preregexsuf
echo txt >$just
svn add -q --no-auto-props $preregexsuf
svn ci -mx $preregexsuf
EOS

my $no = catfile($preregexsuf, 'no');

work_nok('0 error', 'custom error message', <<"EOS");
echo txt >$no
svn add -q --no-auto-props $no
svn ci -mx $no
EOS

work_nok('deny else', 'the component (_else) should be a DIR in', <<"EOS");
echo txt >${file}else
svn add -q --no-auto-props ${file}else
svn ci -mx ${file}else
EOS

work_ok('deny else', <<"EOS");
svn rm -q --force ${file}else
mkdir ${file}else
svn add -q --no-auto-props ${file}else
svn ci -mx ${file}else
EOS

