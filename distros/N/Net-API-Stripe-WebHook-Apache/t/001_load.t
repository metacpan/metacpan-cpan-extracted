# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

BEGIN
{
    # use_ok( 'Net::API::Stripe::WebHook' );
	use Test::Mock::Apache2;
    use Test::More tests => 1;
    use_ok( 'Net::API::Stripe::WebHook::Apache' );
}



