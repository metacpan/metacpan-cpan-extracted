# -*- cperl -*-

use strict;
use warnings;
use lib 't';
use Test::More;

require "test-functions.pl";

if (can_svn()) {
    plan tests => 10;
}
else {
    plan skip_all => 'Cannot find or use svn commands.';
}

my $t    = reset_repo();
my $wc   = catdir($t, 'wc');
my $file = catfile($wc, 'file');

set_hook(<<'EOS');
use SVN::Hooks::DenyChanges;
EOS

set_conf(<<'EOS');
DENY_ADDITION('string');
EOS

work_nok('conf: no regex', 'DENY_CHANGES: all arguments must be qr/Regexp/', <<"EOS");
echo txt >$file
svn add -q --no-auto-props $file
svn ci -mx $file
EOS

set_conf(<<'EOS');
DENY_ADDITION(qr/add/, qr/addmore/);
DENY_DELETION(qr/del/);
DENY_UPDATE  (qr/upd/);
EOS

my $add = catfile($wc, 'add');
my $addmore = catfile($wc, 'addmore');
my $del = catfile($wc, 'del');
my $upd = catfile($wc, 'upd');

work_nok('deny add', 'Cannot add:', <<"EOS");
echo txt >$add
svn add -q --no-auto-props $add
svn ci -mx $add
EOS

work_nok('deny second arg', 'Cannot add:', <<"EOS");
echo txt >$addmore
svn add -q --no-auto-props $addmore
svn ci -mx $addmore
EOS

work_ok('add del upd', <<"EOS");
echo txt >$del
echo txt >$upd
svn add -q --no-auto-props $del $upd
svn ci -mx $del $upd
EOS

work_nok('deny del', 'Cannot delete:', <<"EOS");
svn rm -q $del
svn ci -mx $del
EOS

work_nok('deny upd', 'Cannot update:', <<"EOS");
echo adsf >$upd
svn ci -mx $upd
EOS

work_ok('update f', <<"EOS");
echo adsf >$file
svn ci -mx $file
EOS

work_ok('del f', <<"EOS");
svn del -q $file
svn ci -mx $file
EOS

# Grok the author name
ok(my $author = get_author($t), 'grok author');

set_conf(<<"EOS");
DENY_ADDITION(qr/add/);
DENY_EXCEPT_USERS('$author');
EOS

work_ok('except user', <<"EOS");
echo txt >$add
svn add -q --no-auto-props $add
svn ci -mx $add
EOS
