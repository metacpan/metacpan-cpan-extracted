use strict;
use warnings;
use Test::More tests => 4;
use Photography::DX;

is(Photography::DX->new(speed => 400)->contacts_row_1, '100110', 'okay for speed 400');
is(Photography::DX->new(speed => 5)->contacts_row_1,   '100100', 'okay for custom 5');

is(Photography::DX->new(contacts_row_1 => '100110')->speed, 400, 'okay for speed 400 (reverse)');
is(Photography::DX->new(contacts_row_1 => '100100')->speed, 5,   'okay for custom 5 (reverse)');
