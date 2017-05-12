package Example::Synopsis::Counter;

use Minions
    interface => [ qw( next ) ],
    implementation => 'Example::Synopsis::Acme::Counter';

1;
