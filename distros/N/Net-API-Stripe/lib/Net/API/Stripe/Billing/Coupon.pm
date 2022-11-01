package Net::API::Stripe::Billing::Coupon;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Net::API::Stripe::Product::Coupon );
    use vars qw( $VERSION );
    our( $VERSION ) = 'v0.102.0';
};

use strict;
use warnings;

sub currency_options { return( shift->_set_get_object( 'currency_options', 'Net::API::Stripe::Product::Coupon', @_ ) ); }

1;

__END__

