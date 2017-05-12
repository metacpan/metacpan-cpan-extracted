# test script for: https://rt.cpan.org/Ticket/Display.html?id=46086
use strict;
use warnings;

use Test::More 0.88;
use Test::Warnings; # adds a no-warnings test before done_testing

BEGIN {
    package OnlyUsedOnce;
    use strict;
    use warnings;
    use MooseX::Singleton;
}

BEGIN { OnlyUsedOnce->initialize; }

my $s = OnlyUsedOnce->instance;

done_testing;
