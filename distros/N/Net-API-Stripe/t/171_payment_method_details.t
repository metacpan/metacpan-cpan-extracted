#!perl
# This file has been automatically generated on 2022-10-12T17:14:19+0900 by scripts/check_stripe.pl.
# Any modification will be lost next time it is generated again.
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use vars qw( $DEBUG );
    use Test::More qw( no_plan );
    use Module::Generic::File qw( file );
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

use strict;
use warnings;

BEGIN
{
    use_ok( 'Net::API::Stripe::Payment::Method::Details' ) || BAIL_OUT( "Unable to load perl module 'Net::API::Stripe::Payment::Method::Details'" );
};
can_ok( 'Net::API::Stripe::Payment::Method::Details', 'ach_credit_transfer' );
can_ok( 'Net::API::Stripe::Payment::Method::Details', 'ach_debit' );
can_ok( 'Net::API::Stripe::Payment::Method::Details', 'acss_debit' );
can_ok( 'Net::API::Stripe::Payment::Method::Details', 'affirm' );
can_ok( 'Net::API::Stripe::Payment::Method::Details', 'afterpay_clearpay' );
can_ok( 'Net::API::Stripe::Payment::Method::Details', 'alipay' );
can_ok( 'Net::API::Stripe::Payment::Method::Details', 'au_becs_debit' );
can_ok( 'Net::API::Stripe::Payment::Method::Details', 'bacs_debit' );
can_ok( 'Net::API::Stripe::Payment::Method::Details', 'bancontact' );
can_ok( 'Net::API::Stripe::Payment::Method::Details', 'blik' );
can_ok( 'Net::API::Stripe::Payment::Method::Details', 'boleto' );
can_ok( 'Net::API::Stripe::Payment::Method::Details', 'card' );
can_ok( 'Net::API::Stripe::Payment::Method::Details', 'card_present' );
can_ok( 'Net::API::Stripe::Payment::Method::Details', 'customer_balance' );
can_ok( 'Net::API::Stripe::Payment::Method::Details', 'eps' );
can_ok( 'Net::API::Stripe::Payment::Method::Details', 'fpx' );
can_ok( 'Net::API::Stripe::Payment::Method::Details', 'giropay' );
can_ok( 'Net::API::Stripe::Payment::Method::Details', 'grabpay' );
can_ok( 'Net::API::Stripe::Payment::Method::Details', 'ideal' );
can_ok( 'Net::API::Stripe::Payment::Method::Details', 'interac_present' );
can_ok( 'Net::API::Stripe::Payment::Method::Details', 'klarna' );
can_ok( 'Net::API::Stripe::Payment::Method::Details', 'konbini' );
can_ok( 'Net::API::Stripe::Payment::Method::Details', 'link' );
can_ok( 'Net::API::Stripe::Payment::Method::Details', 'multibanco' );
can_ok( 'Net::API::Stripe::Payment::Method::Details', 'oxxo' );
can_ok( 'Net::API::Stripe::Payment::Method::Details', 'p24' );
can_ok( 'Net::API::Stripe::Payment::Method::Details', 'paynow' );
can_ok( 'Net::API::Stripe::Payment::Method::Details', 'promptpay' );
can_ok( 'Net::API::Stripe::Payment::Method::Details', 'sepa_debit' );
can_ok( 'Net::API::Stripe::Payment::Method::Details', 'sofort' );
can_ok( 'Net::API::Stripe::Payment::Method::Details', 'stripe_account' );
can_ok( 'Net::API::Stripe::Payment::Method::Details', 'type' );
can_ok( 'Net::API::Stripe::Payment::Method::Details', 'us_bank_account' );
can_ok( 'Net::API::Stripe::Payment::Method::Details', 'wechat' );
can_ok( 'Net::API::Stripe::Payment::Method::Details', 'wechat_pay' );
my $parent = file( __FILE__ )->parent;
my $sample_dir = $parent->child( 'sample' ) ||
    BAIL_OUT( $parent->error );
if( !$sample_dir->exists )
{
    BAIL_OUT( "Sample directory '${sample_dir}' does not exists." );
}
elsif( !$sample_dir->finfo->can_exec )
{
    BAIL_OUT( "Lacking permission for user $> to enter the sample directory '${sample_dir}'." );
}
my $code = {};
$code->{debug} = $DEBUG if( $DEBUG );
my $json_file = $sample_dir->child( 'payment_method_details.json' ) ||
    BAIL_OUT( $sample_dir->error );
if( $json_file->exists )
{
    if( !$json_file->can_read )
    {
        my $rel = $json_file->relative;
        BAIL_OUT( "Unable to read json file $rel for Stripe class 'payment_method_details'" );
    }
    elsif( !$json_file->is_empty )
    {
        $code = $json_file->load_json ||
            BAIL_OUT( "Failed to load json data for Stripe class 'payment_method_details': " . $json_file->error );
    }
}
my $obj = scalar( keys( %$code ) ) ? Net::API::Stripe::Payment::Method::Details->new( $code ) : Net::API::Stripe::Payment::Method::Details->new;
isa_ok( $obj => 'Net::API::Stripe::Payment::Method::Details' );

done_testing();

__END__

