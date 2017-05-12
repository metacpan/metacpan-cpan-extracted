use Test::More tests => 9;

use 5.20.0;

use MoobX;

use List::AllUtils qw/ first /;

observable my @foo;
@foo = 1..10;

my $value = observer { first { $_ > 2 } @foo };

is $value => 3;

$foo[1] = 5;

is $value => 5;

observable( my $bar = 3 );

my $i;
my $auto = autorun {
    pass if $foo[0] < $bar;
    ++$i;
};

# one pass as it get initialized for the first time
is $auto => 1, 'init';

$bar -= 5;  # no pass, -2 < 1
is $auto => 2;

$foo[0] = -100;  # pass
is $auto => 3;

$bar = 0; # pass again
is $auto => 4;


