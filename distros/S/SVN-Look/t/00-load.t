use strict;
use warnings;
use lib 't';
use Test::More;

require "test-functions.pl";

if (can_svn()) {
    plan tests => 1;
}
else {
    plan skip_all => 'Cannot find or use svn commands.';
}

require_ok('SVN::Look');
