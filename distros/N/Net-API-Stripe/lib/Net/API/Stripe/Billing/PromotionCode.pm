package Net::API::Stripe::Billing::PromotionCode;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Net::API::Stripe::Product::PromotionCode );
    use vars qw( $VERSION );
    our( $VERSION ) = 'v0.2.0';
};

use strict;
use warnings;

sub restrictions { return( shift->_set_get_class( 'restrictions',
{
  currency_options        => {
                               definition => { minimum_amount => { type => "number" } },
                               type => "class",
                             },
  first_time_transaction  => { type => "boolean" },
  minimum_amount          => { type => "number" },
  minimum_amount_currency => { type => "scalar" },
}, @_ ) ); }

1;

__END__

