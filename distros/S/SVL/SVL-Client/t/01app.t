use Test::More tests => 2;
use_ok( Catalyst::Test, 'SVL::Client' );

ok( request('/')->is_success );
