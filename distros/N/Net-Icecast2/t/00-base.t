use warnings;
use strict;
use Test::More;

plan tests => 3;

    use_ok( 'Net::Icecast2' );
    use_ok( 'Net::Icecast2::Admin' );
    use_ok( 'Net::Icecast2::Mount' );

done_testing;
