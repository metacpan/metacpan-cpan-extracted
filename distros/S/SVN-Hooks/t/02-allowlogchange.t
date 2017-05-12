# -*- cperl -*-

use strict;
use warnings;
use lib 't';
use Test::More;

require "test-functions.pl";

if (can_svn()) {
    plan tests => 9;
}
else {
    plan skip_all => 'Cannot find or use svn commands.';
}

my $t = reset_repo();
my $repo = URI::file->new(catdir($t, 'repo'));

set_hook(<<'EOS');
use SVN::Hooks::AllowLogChange;
EOS

my $wc   = catdir($t, 'wc');
my $file = catfile($wc, 'file');

work_ok('setup', <<"EOS");
echo txt >$file
svn add -q --no-auto-props $file
svn ci -mx $file
EOS

set_conf(<<'EOS');
ALLOW_LOG_CHANGE({});
EOS

work_nok('invalid argument' => 'ALLOW_LOG_CHANGE: invalid argument', <<"EOS");
svn ps svn:log --revprop -r 1 message $repo
EOS

set_conf(<<"EOS");
ALLOW_LOG_CHANGE();
EOS

work_nok('nothing but svn:log' => 'ALLOW_LOG_CHANGE: the revision property svn:xpto cannot be changed.', <<"EOS");
svn ps svn:xpto --force --revprop -r 1 value $repo
EOS

work_nok('cannot delete' => 'ALLOW_LOG_CHANGE: a revision log can only be modified, not added or deleted.', <<"EOS");
svn pd svn:log --revprop -r 1 $repo
EOS

# Grok the author name
ok(my $author = get_author($t), 'grok author');

set_conf(<<"EOS");
ALLOW_LOG_CHANGE('x$author');
EOS

work_nok('deny user' => 'ALLOW_LOG_CHANGE: you are not allowed to change a revision log.', <<"EOS");
svn ps svn:log --revprop -r 1 value $repo
EOS

set_conf(<<"EOS");
ALLOW_LOG_CHANGE('$author');
EOS

work_ok('can modify', <<"EOS");
svn ps svn:log --revprop -r 1 value $repo
EOS

set_conf(<<"EOS");
ALLOW_LOG_CHANGE(qr/./);
EOS

work_ok('can modify with regexp', <<"EOS");
svn ps svn:log --revprop -r 1 value2 $repo
EOS

set_conf(<<'EOS');
ALLOW_LOG_CHANGE(qr/^,/);
EOS

work_nok('deny user with regexp' => 'ALLOW_LOG_CHANGE: you are not allowed to change a revision log.', <<"EOS");
svn ps svn:log --revprop -r 1 value3 $repo
EOS

