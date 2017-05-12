package TypeLibrary;
our $VERSION = '0.01';


use MooseX::Types -declare => [qw/
    EvenInt
/];

use MooseX::Types::Moose qw/Int/;

subtype EvenInt,
    as Int,
    where { $_ % 2 == 0 };

1;
