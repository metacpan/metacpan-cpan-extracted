use strict;
use warnings;

use Test::More 'no_plan';

ok(1, 'escape some of these chars: !@#$%^++_)(*&^%$#@!><');
like('a<b>c', qr/<b>/, 'contains <b> in the <output>');
is('a<b>c', '<html><body><h1>eeek</h1></body></html>', '<html> in the diag messages..');

