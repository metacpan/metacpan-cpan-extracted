use strict;
use warnings;

use Test::Most;
use Number::Phone::AU;

note "new with no args"; {
    throws_ok { Number::Phone::AU->new(); }
        qr/The number is undefined/,
        "no arguments, no object";
}


note "new with obviously bad args"; {
    throws_ok { Number::Phone::AU->new({}); }
        qr/The number is a reference/,
        "bad arguments, no object";
}


note "new with valid number"; {
    my $number = Number::Phone::AU->new( "+61 3 1234 5678" );

    isa_ok $number, "Number::Phone::AU";
}


done_testing();
