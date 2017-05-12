use warnings; use strict;
use Test::More tests => 4;

BEGIN { require_ok("Math::BigInt"); }

use Object::Import Math::BigInt::;
is(new("0x100"), "256");

use Object::Import Math::BigInt->new("100"), prefix => "h";
is(hbmul(2), "200");
is(has_hex(), "0xc8");

__END__
