#!perl
use strict;
use warnings;
use 5.10.1;

BEGIN { chdir 't' if -d 't'; }
use lib '../lib';

use Test::More; END { done_testing; }
use Test::Exception;

use NetObj::MacAddress;

my $mac = NetObj::MacAddress->new('012MZk'); # 6 bytes raw MAC address

is($mac->to_string('base16'), '3031324d5a6b',      'formatting with raw hex');

BEGIN { use_ok('NetObj::MacAddress::Formatter::Colons'); }
is($mac->to_string('colons'), '30:31:32:4d:5a:6b', 'formatting with colons');

BEGIN { use_ok('NetObj::MacAddress::Formatter::Dashes'); }
is($mac->to_string('dashes'), '30-31-32-4D-5A-6B', 'formatting with dashes');

BEGIN { use_ok('NetObj::MacAddress::Formatter::Dots'); }
is($mac->to_string('dots'),   '3031.324d.5a6b',    'formatting with dots');
is($mac->to_string('DOTS'),   '3031.324d.5a6b',    'formatting with DOTS');
is($mac->to_string('dOtS'),   '3031.324d.5a6b',    'formatting with dOtS');


throws_ok(
    sub { $mac->to_string('%') }, # '%' should not be a valid formatter name
    qr{no formatter},
    'invalid formatter name throws exception',
);
