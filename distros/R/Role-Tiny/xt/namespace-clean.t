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

BEGIN {
    package Local::Role2;
    use Role::Tiny;
    use namespace::clean;
    sub foo { 1 };
}

BEGIN {
    package Local::Role2;
    use Role::Tiny;
}

# this may not be ideal, but we'll test it since it is done explicitly
ok !defined &Local::Role2::with, 'subs are not re-exported';

done_testing();
