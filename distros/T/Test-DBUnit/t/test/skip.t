use strict;
use warnings;
use Test::More;
use Test::DBUnit dsn => 'dbi:mysqel:localhost:1521/FAKE_INSTANCE', username => 'user', password => undef;
plan tests => 1;
ok(1);