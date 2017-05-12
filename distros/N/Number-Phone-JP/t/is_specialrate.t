use strict;
use Test::More tests => 1 + 11;
use Test::Requires qw( Number::Phone );
use_ok('Number::Phone::JP');

ok(! Number::Phone->new('+810112345678')->is_specialrate, 'checking for 001 12345678');
ok(! Number::Phone->new('+810912012345678')->is_specialrate, 'checking for 009120 12345678');
ok(! Number::Phone->new('+816033001234')->is_specialrate, 'checking for 060 33001234');
ok(! Number::Phone->new('+81120000123')->is_specialrate, 'checking for 0120 000123');
ok(! Number::Phone->new('+81112001234')->is_specialrate, 'checking for 011 2001234');
ok(! Number::Phone->new('+815010001234')->is_specialrate, 'checking for 050 10001234');
ok(! Number::Phone->new('+818010012345')->is_specialrate, 'checking for 080 10012345');
ok(! Number::Phone->new('+812046012345')->is_specialrate, 'checking for 020 46012345');
ok(! Number::Phone->new('+817050112345')->is_specialrate, 'checking for 070 50112345');
ok(  Number::Phone->new('+81990500123')->is_specialrate, 'checking for 0990 500123');
ok(! Number::Phone->new('+81570000123')->is_specialrate, 'checking for 0570 000123');
