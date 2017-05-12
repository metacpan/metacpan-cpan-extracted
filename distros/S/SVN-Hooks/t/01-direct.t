# -*- cperl -*-

use strict;
use warnings;
use lib 't';
use Test::More;

require "test-functions.pl";

if (can_svn()) {
    plan tests => 2;
}
else {
    plan skip_all => 'Cannot find or use svn commands.';
}

my $t = reset_repo();

set_hook(<<'EOS');
START_COMMIT {
    my ($repos_path, $username, $capabilities) = @_;

    length $username
	or die "Empty username not allowed to commit.\n";
};

PRE_COMMIT {
    my ($svnlook) = @_;

    foreach my $added ($svnlook->added()) {
        warn "= $added\n";
	$added !~ /\.(exe|o|jar|zip)$/
	    or die "Please, don't commit binary files such as '$added'.\n";
    }
};
EOS

my $txtfile = catfile($t, 'wc', 'file.txt');

work_ok('setup', <<"EOS");
echo txt >$txtfile
svn add -q --no-auto-props $txtfile
svn ci -mx $txtfile
EOS

my $zipfile = catfile($t, 'wc', 'file.zip');

work_nok('binary' => 'Please, don\'t commit binary files', <<"EOS");
echo txt >$zipfile
svn add -q --no-auto-props $zipfile
svn ci -mx $zipfile
EOS

