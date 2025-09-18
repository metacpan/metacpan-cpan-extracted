#!perl -w

use strict;

# use lib 'lib';
use Test::Most tests => 4;
use Test::NoWarnings;

BEGIN { use_ok('Object::Configure') }

ok(defined(Object::Configure::configure('Object::Configure')));
ok(ref(Object::Configure::configure('Object::Configure')) eq 'HASH');
