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
use SVN::Hooks::AllowPropChange;
EOS

my $file = catfile($t, 'wc', 'file');

work_ok('setup', <<"EOS");
echo txt >$file
svn add -q --no-auto-props $file
svn ci -mx $file
EOS

set_conf(<<'EOS');
ALLOW_PROP_CHANGE({});
EOS

work_nok('invalid argument' => 'ALLOW_PROP_CHANGE: invalid argument', <<"EOS");
svn ps svn:log --revprop -r 1 message $repo
EOS

set_conf(<<"EOS");
ALLOW_PROP_CHANGE(qr/./);
EOS

work_nok('unknowk property' => 'ALLOW_PROP_CHANGE: the revision property svn:xpto cannot be changed.', <<"EOS");
svn ps svn:xpto --force --revprop -r 1 value $repo
EOS

work_nok('cannot delete' => 'ALLOW_PROP_CHANGE: revision properties can only be modified, not added or deleted.', <<"EOS");
svn pd svn:log --revprop -r 1 $repo
EOS

# Grok the author name
ok(my $author = get_author($t), 'grok author');

set_conf(<<"EOS");
ALLOW_PROP_CHANGE('svn:log' => 'x$author');
EOS

work_nok('deny user' => 'ALLOW_PROP_CHANGE: you are not allowed to change property svn:log.', <<"EOS");
svn ps svn:log --revprop -r 1 value $repo
EOS

set_conf(<<"EOS");
ALLOW_PROP_CHANGE('svn:log' => '$author');
EOS

work_ok('can modify', <<"EOS");
svn ps svn:log --revprop -r 1 value $repo
EOS

set_conf(<<"EOS");
ALLOW_PROP_CHANGE('svn:log' => qr/./);
EOS

work_ok('can modify with regexp', <<"EOS");
svn ps svn:log --revprop -r 1 value2 $repo
EOS

set_conf(<<'EOS');
ALLOW_PROP_CHANGE(qr/./ => qr/^,/);
EOS

work_nok('deny user with regexp' => 'ALLOW_PROP_CHANGE: you are not allowed to change property svn:log.', <<"EOS");
svn ps svn:log --revprop -r 1 value3 $repo
EOS

