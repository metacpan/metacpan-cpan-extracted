use strict;
use warnings;
use Test::More;

BEGIN {
    package My::Does::Basic;
    $INC{'My/Does/Basic.pm'} = 1;

    use Role::Tiny;

    requires 'turbo_charger';

    sub no_conflict {
        return "My::Does::Basic::no_conflict";
    }
}

BEGIN {
    package My::Example;
    $INC{'My/Example.pm'} = 1;

    use Role::Tiny 'with';

    with 'My::Does::Basic';

    sub new { bless {} => shift }

    sub turbo_charger {}
    $My::Example::foo = 1;
    sub foo() {}
}

use My::Example;
can_ok 'My::Example', 'no_conflict';
is +My::Example->no_conflict, 'My::Does::Basic::no_conflict',
    '... and it should return the correct value';

done_testing;
