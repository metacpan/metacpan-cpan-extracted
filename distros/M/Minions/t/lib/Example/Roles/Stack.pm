package Example::Roles::Stack;

use Minions
    interface => [qw( push pop size )],

    implementation => 'Example::Roles::Acme::Stack_v1',
;

1;

