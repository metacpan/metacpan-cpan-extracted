use strict;
use warnings;
use Test::More tests => 1;
ok(1, 'this is ok');
note 'this is a note';
diag 'this is a diag';
fail('this is a failure');
pass('this is a pass');
done_testing;

