package Example::Delegates::Queue;

use Minions
    interface => [qw( push pop size )],

    implementation => 'Example::Delegates::Acme::Queue_v1',
;

1;
