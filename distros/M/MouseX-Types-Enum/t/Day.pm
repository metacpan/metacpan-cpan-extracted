package Day;

use strict;
use warnings FATAL => 'all';
use MouseX::Types::Enum qw/
    Sun
    Mon
    Tue
    Wed
    Thu
    Fri
    Sat
/;

__PACKAGE__->meta->make_immutable;

1;