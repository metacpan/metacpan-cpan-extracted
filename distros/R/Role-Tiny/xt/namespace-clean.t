use strict;
use warnings;
use Test::More;

use namespace::autoclean ();

BEGIN {
    package Local::Role;
    use Role::Tiny;
    sub foo { 1 };
}

BEGIN {
    package Local::Class;
    use namespace::autoclean;
    use Role::Tiny::With;
    with qw( Local::Role );
};

can_ok 'Local::Class', 'foo';
can_ok 'Local::Class', 'does';

done_testing();
