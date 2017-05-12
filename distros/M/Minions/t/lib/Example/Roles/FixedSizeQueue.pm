package Example::Roles::FixedSizeQueue;

use Minions
    interface => [qw( push pop size )],

    construct_with  => {
        max_size => { 
            assert => { positive_int => sub { $_[0] =~ /^\d+$/ && $_[0] > 0 } }, 
        },
    }, 

    implementation => 'Example::Roles::Acme::FixedSizeQueue_v1',
;

1;
