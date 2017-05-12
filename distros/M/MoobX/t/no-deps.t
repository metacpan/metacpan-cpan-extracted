use strict;
use warnings;

use Test::More;
use Test::Warn;

use MoobX;

my $foo :Observable = 2;

my $obs = observer {
    1 + 2;
};

my $o2 = observer {
    1 + $foo;
};

warning_like {
    my $x = 1 + $obs
} qr/MoobX observer doesn't observe anything.*line 20/,
    '$obs triggers warning';

warning_is {
    my $x = 1 + $o2
} undef,
    '$o2 is fine';

$MoobX::WARN_NO_DEPS = 0;

warning_is {
    my $x = 1 + $obs;
} undef,
    'warning is hushed';

done_testing;

