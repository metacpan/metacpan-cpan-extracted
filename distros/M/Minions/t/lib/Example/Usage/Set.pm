package Example::Usage::Set;

use Minions
    interface => [qw( add has )],

    implementation => 'Example::Usage::ArraySet',
    ;
1;
