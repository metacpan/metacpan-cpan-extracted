# -*- cperl -*-

use strict;
use warnings;
use lib 't';
use Test::More;

require "test-functions.pl";

if (can_svn()) {
    plan tests => 3;
}
else {
    plan skip_all => 'Cannot find or use svn commands.';
}

my $t = reset_repo();

set_hook(<<'EOS');
use SVN::Hooks::CheckCapability;
EOS

set_conf(<<'EOS');
CHECK_CAPABILITY();
EOS

my $file = catfile($t, 'wc', 'file');

work_ok('setup', <<"EOS");
echo txt >$file
svn add -q --no-auto-props $file
svn ci -mx $file
EOS

set_conf(<<'EOS');
CHECK_CAPABILITY('nonexistent-capability');
EOS

work_nok('conf: nonexistent capability', 'CHECK_CAPABILITY: Your subversion client does not support', <<"EOS");
echo asdf >>$file
svn ci -mx $file
EOS

set_conf(<<'EOS');
CHECK_CAPABILITY('mergeinfo');
EOS

if (`svn help` =~ /\bmergeinfo\b/) {
    work_ok('has mergeinfo', <<"EOS");
echo asdf >>$file
svn ci -mx $file
EOS
}
else {
    work_nok('do not has mergeinfo', 'CHECK_CAPABILITY: Your subversion client does not support', <<"EOS");
echo asdf >>$file
svn ci -mx $file
EOS
}
