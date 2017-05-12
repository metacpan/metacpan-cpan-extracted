use strict;
use warnings;

use Test::More;

plan tests => 1;

use Net::ACME::X ();

unlike(
    join(' ', sort keys %INC),
    qr<overload\.pm>,
    'overload.pm is not loaded at compile time',
);
