# -*- cperl -*-

use strict;
use warnings;
use lib 't';
use Test::More;

require "test-functions.pl";

if (not can_svn()) {
    plan skip_all => 'Cannot find or use svn commands.';
}
elsif (! eval {require SVN::Notify}) {
    plan skip_all => 'Need SVN::Notify.';
}
else {
    plan tests => 1;
}

my $t    = reset_repo();
my $wc   = catdir($t, 'wc');

set_hook(<<'EOS');
use SVN::Hooks::Notify;
EOS

sub work {
    my $file = catfile($wc, $_[0]);
    <<"EOS";
echo txt >$file
svn add -q --no-auto-props $file
svn ci -mmessage $wc
EOS
}

set_conf(<<'EOS');
NOTIFY_DEFAULTS();
NOTIFY(to_email_map => {'dontmatch' => 'none@nowhere.com'});
EOS

work_ok('load and config', work('f'));
