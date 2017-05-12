# -*- cperl -*-

use strict;
use warnings;
use lib 't';
use Test::More;

require "test-functions.pl";

if (can_svn()) {
    plan tests => 5;
}
else {
    plan skip_all => 'Cannot find or use svn commands.';
}

my $t = reset_repo();

set_hook(<<'EOS');
use SVN::Hooks::CheckLog;
EOS

set_conf(<<'EOS');
CHECK_LOG();
EOS

my $file = catfile($t, 'wc', 'file.txt');

work_nok('miss regexp' => 'first argument must be a qr', <<"EOS");
echo txt >$file
svn add -q --no-auto-props $file
svn ci -mx $file
EOS

set_conf(<<'EOS');
CHECK_LOG(qr/./, []);
EOS

work_nok('invalid second arg' => 'second argument must be', <<"EOS");
svn ci -mx $file
EOS

set_conf(<<'EOS');
CHECK_LOG(qr/without error/);
CHECK_LOG(qr/with error/, 'Error Message');
EOS

work_nok('dont match without error' => 'log message must match', <<"EOS");
svn ci -mx $file
EOS

work_nok('dont match with error', 'Error Message', <<"EOS");
svn ci -m"without error" $file
EOS

work_ok('match all', <<"EOS");
svn ci -m"without error with error" $file
EOS
