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
    use_ok( 'Net::API::Stripe::Payment::Method' ) || BAIL_OUT( "Unable to load perl module 'Net::API::Stripe::Payment::Method'" );
};
can_ok( 'Net::API::Stripe::Payment::Method', 'acss_debit' );
can_ok( 'Net::API::Stripe::Payment::Method', 'affirm' );
can_ok( 'Net::API::Stripe::Payment::Method', 'afterpay_clearpay' );
can_ok( 'Net::API::Stripe::Payment::Method', 'alipay' );
can_ok( 'Net::API::Stripe::Payment::Method', 'au_becs_debit' );
can_ok( 'Net::API::Stripe::Payment::Method', 'bacs_debit' );
can_ok( 'Net::API::Stripe::Payment::Method', 'bancontact' );
can_ok( 'Net::API::Stripe::Payment::Method', 'billing_details' );
can_ok( 'Net::API::Stripe::Payment::Method', 'blik' );
can_ok( 'Net::API::Stripe::Payment::Method', 'boleto' );
can_ok( 'Net::API::Stripe::Payment::Method', 'card' );
can_ok( 'Net::API::Stripe::Payment::Method', 'card_present' );
can_ok( 'Net::API::Stripe::Payment::Method', 'created' );
can_ok( 'Net::API::Stripe::Payment::Method', 'customer' );
can_ok( 'Net::API::Stripe::Payment::Method', 'customer_balance' );
can_ok( 'Net::API::Stripe::Payment::Method', 'eps' );
can_ok( 'Net::API::Stripe::Payment::Method', 'fpx' );
can_ok( 'Net::API::Stripe::Payment::Method', 'giropay' );
can_ok( 'Net::API::Stripe::Payment::Method', 'grabpay' );
can_ok( 'Net::API::Stripe::Payment::Method', 'id' );
can_ok( 'Net::API::Stripe::Payment::Method', 'ideal' );
can_ok( 'Net::API::Stripe::Payment::Method', 'interac_present' );
can_ok( 'Net::API::Stripe::Payment::Method', 'klarna' );
can_ok( 'Net::API::Stripe::Payment::Method', 'konbini' );
can_ok( 'Net::API::Stripe::Payment::Method', 'link' );
can_ok( 'Net::API::Stripe::Payment::Method', 'livemode' );
can_ok( 'Net::API::Stripe::Payment::Method', 'metadata' );
can_ok( 'Net::API::Stripe::Payment::Method', 'object' );
can_ok( 'Net::API::Stripe::Payment::Method', 'oxxo' );
can_ok( 'Net::API::Stripe::Payment::Method', 'p24' );
can_ok( 'Net::API::Stripe::Payment::Method', 'paynow' );
can_ok( 'Net::API::Stripe::Payment::Method', 'promptpay' );
can_ok( 'Net::API::Stripe::Payment::Method', 'radar_options' );
can_ok( 'Net::API::Stripe::Payment::Method', 'sepa_debit' );
can_ok( 'Net::API::Stripe::Payment::Method', 'sofort' );
can_ok( 'Net::API::Stripe::Payment::Method', 'type' );
can_ok( 'Net::API::Stripe::Payment::Method', 'us_bank_account' );
can_ok( 'Net::API::Stripe::Payment::Method', 'wechat_pay' );
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
my $json_file = $sample_dir->child( 'payment_method.json' ) ||
    BAIL_OUT( $sample_dir->error );
if( $json_file->exists )
{
    if( !$json_file->can_read )
    {
        my $rel = $json_file->relative;
        BAIL_OUT( "Unable to read json file $rel for Stripe class 'payment_method'" );
    }
    elsif( !$json_file->is_empty )
    {
        $code = $json_file->load_json ||
            BAIL_OUT( "Failed to load json data for Stripe class 'payment_method': " . $json_file->error );
    }
}
my $obj = scalar( keys( %$code ) ) ? Net::API::Stripe::Payment::Method->new( $code ) : Net::API::Stripe::Payment::Method->new;
isa_ok( $obj => 'Net::API::Stripe::Payment::Method' );

done_testing();

__END__

