use strict;
use warnings;
use t::scan::Util;

test(<<'TEST'); # RRA/Tie-ShadowHash-1.00/ShadowHash.pm
    while (!@result && $self->{EACH} < @{ $self->{SOURCES} }) {
    }
TEST

done_testing;
