use strict;
use Test::More tests => 1;

BEGIN { use_ok 'Pod::HTMLEmbed' }


no warnings 'uninitialized', 'once';

diag "Soft dependency versions:";

eval{ require Any::Moose };
diag "    Any::Moose: $Any::Moose::VERSION";

if ($Any::Moose::PREFERRED eq 'Moose') {
    eval { require Moose };
    diag "    Moose: $Moose::VERSION";
}
else {
    eval{ require Mouse };
    diag "    Mouse: $Mouse::VERSION";
}

