use strict;
use Test::More tests => 3;

BEGIN {
    eval { require Spread; };
    my $skip_all = ( $@ ) ? 1 : 0;

    SKIP: {
        skip "Spread::Messaging requires Spread", 2
                if $skip_all;

        use_ok( 'Spread::Messaging' );        
        use_ok( 'Spread::Messaging::Content' );
        use_ok( 'Spread::Messaging::Transport' );
    }
}
