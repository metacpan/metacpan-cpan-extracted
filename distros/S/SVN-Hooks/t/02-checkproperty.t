# -*- cperl -*-

use strict;
use warnings;
use lib 't';
use Test::More;

require "test-functions.pl";

if (can_svn()) {
    plan tests => 20;
}
else {
    plan skip_all => 'Cannot find or use svn commands.';
}

my $t = reset_repo();

set_hook(<<'EOS');
use SVN::Hooks::CheckProperty;
EOS

set_conf(<<'EOS');
CHECK_PROPERTY();
EOS

my $file = catfile($t, 'wc', 'file');

work_nok('conf: no first arg', 'CHECK_PROPERTY: first argument must be a STRING or a qr/Regexp/', <<"EOS");
echo txt >$file
svn add -q --no-auto-props $file
svn ci -mx $file
EOS

set_conf(<<'EOS');
CHECK_PROPERTY(bless({}, 'Nothing'));
EOS

work_nok('conf: wrong first arg', 'CHECK_PROPERTY: first argument must be a STRING or a qr/Regexp/', <<"EOS");
svn ci -mx $file
EOS

set_conf(<<'EOS');
CHECK_PROPERTY('string');
EOS

work_nok('conf: no second arg', 'CHECK_PROPERTY: second argument must be a STRING', <<"EOS");
svn ci -mx $file
EOS

set_conf(<<'EOS');
CHECK_PROPERTY('s', qr/asdf/);
EOS

work_nok('conf: wrong second arg', 'CHECK_PROPERTY: second argument must be a STRING', <<"EOS");
svn ci -mx $file
EOS

set_conf(<<'EOS');
CHECK_PROPERTY('s', 's', bless({}, 'Nothing'));
EOS

work_nok('conf: wrong third arg', 'CHECK_PROPERTY: third argument must be undefined, or a NUMBER, or a STRING, or a qr/Regexp/', <<"EOS");
svn ci -mx $file
EOS

set_conf(<<'EOS');
CHECK_PROPERTY('file1', 'prop');
CHECK_PROPERTY('file2', 'prop', 0);
CHECK_PROPERTY('file3', 'prop', 1);
CHECK_PROPERTY('file4', 'prop', 'value');
CHECK_PROPERTY('file5', 'prop', qr/^value$/);
CHECK_PROPERTY(qr/file6/, 'prop');
EOS

work_nok('check(string, string, undef) fail', 'property prop must be set for: file1', <<"EOS");
echo txt >${file}1
svn add -q --no-auto-props ${file}1
svn ci -mx ${file}1
EOS

work_ok('check(string, string, undef) succeed', <<"EOS");
svn ps prop x ${file}1
svn ci -mx ${file}1
EOS

work_nok('check(string, string, false) fail', 'property prop must not be set for: file2', <<"EOS");
echo txt >${file}2
svn add -q --no-auto-props ${file}2
svn ps prop x ${file}2
svn ci -mx ${file}2
EOS

work_ok('check(string, string, false) succeed', <<"EOS");
svn pd prop ${file}2
svn ci -mx ${file}2
EOS

work_nok('check(string, string, true) fail', 'property prop must be set for: file3', <<"EOS");
echo txt >${file}3
svn add -q --no-auto-props ${file}3
svn ci -mx ${file}3
EOS

work_ok('check(string, string, true) succeed', <<"EOS");
svn ps prop x ${file}3
svn ci -mx ${file}3
EOS

work_nok('check(string, string, string) fail because not set',
	 'property prop must be set to "value" for: file4', <<"EOS");
echo txt >${file}4
svn add -q --no-auto-props ${file}4
svn ci -mx ${file}4
EOS

work_nok('check(string, string, string) fail because of wrong value',
	 'property prop must be set to "value" and not to "x" for: file4', <<"EOS");
svn ps prop x ${file}4
svn ci -mx ${file}4
EOS

work_ok('check(string, string, string) succeed', <<"EOS");
svn ps prop value ${file}4
svn ci -mx ${file}4
EOS

work_nok('check(string, string, regex) fail because not set',
	 qr/property prop must be set and match "\(\?(?:-xism|\^):\^value\$\)" for: file5/, <<"EOS");
echo txt >${file}5
svn add -q --no-auto-props ${file}5
svn ci -mx ${file}5
EOS

work_nok('check(string, string, regex) fail because of wrong value',
	 qr/property prop must match "\(\?(?:-xism|\^):\^value\$\)" but is "x" for: file5/, <<"EOS");
svn ps prop x ${file}5
svn ci -mx ${file}5
EOS

work_ok('check(string, string, regex) succeed', <<"EOS");
svn ps prop value ${file}5
svn ci -mx ${file}5
EOS

work_nok('check(regex, string, undef) fail', 'property prop must be set for: file6', <<"EOS");
echo txt >${file}6
svn add -q --no-auto-props ${file}6
svn ci -mx ${file}6
EOS

work_ok('check(regex, string, undef) succeed', <<"EOS");
svn ps prop x ${file}6
svn ci -mx ${file}6
EOS

work_ok('succeed because dont match file name', <<"EOS");
echo txt >${file}NOMATCH
svn add -q --no-auto-props ${file}NOMATCH
svn ci -mx ${file}NOMATCH
EOS

