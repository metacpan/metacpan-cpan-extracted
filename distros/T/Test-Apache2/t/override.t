use strict;
use warnings;
use Test::More tests => 1;
use Test::Apache2;

ok(defined Apache2::ServerUtil::server_root);
