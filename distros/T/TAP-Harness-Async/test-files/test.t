#!perl
use strict;
use warnings;
use Test::More tests => 4;
ok(1, 'is true');
pass('does pass');
note 'is comment';
fail('we fail');
is('x', 'y', 'try to mismatch');
done_testing();
