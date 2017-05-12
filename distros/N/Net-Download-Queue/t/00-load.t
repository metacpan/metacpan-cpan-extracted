use Test::More tests => 1;

use lib "../lib";

BEGIN {
    use_ok( 'Net::Download::Queue' );
}

#diag( "Testing Net::Download::Queue $Net::Download::Queue::VERSION" );
