use strict;
use warnings;

use Test::AnyEvent::Time tests => 1;
use Test::More;

note("Timeout is always error");
time_cmp_ok sub {
    my $cv = shift;
    my $w; $w = AE::timer 5, undef, sub {
        undef $w;
        $cv->send();
    };
}, ">", 1, 2;

