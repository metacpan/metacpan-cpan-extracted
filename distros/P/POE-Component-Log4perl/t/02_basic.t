use strict;
use Test::More tests => 1;

BEGIN {
    eval { require Log::Log4perl; };
    my $skip_all = ( $@ ) ? 1 : 0;

    SKIP: {
        skip "POE::Component::Log4perl requires Log::Log4perl", 2
                if $skip_all;
                
        use_ok( 'POE::Component::Log4perl' );        
    }
}
