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
    use_ok( 'Net::API::Stripe::Billing::CreditNote' ) || BAIL_OUT( "Unable to load perl module 'Net::API::Stripe::Billing::CreditNote'" );
};
can_ok( 'Net::API::Stripe::Billing::CreditNote', 'amount' );
can_ok( 'Net::API::Stripe::Billing::CreditNote', 'created' );
can_ok( 'Net::API::Stripe::Billing::CreditNote', 'currency' );
can_ok( 'Net::API::Stripe::Billing::CreditNote', 'customer' );
can_ok( 'Net::API::Stripe::Billing::CreditNote', 'customer_balance_transaction' );
can_ok( 'Net::API::Stripe::Billing::CreditNote', 'discount_amount' );
can_ok( 'Net::API::Stripe::Billing::CreditNote', 'discount_amounts' );
can_ok( 'Net::API::Stripe::Billing::CreditNote', 'id' );
can_ok( 'Net::API::Stripe::Billing::CreditNote', 'invoice' );
can_ok( 'Net::API::Stripe::Billing::CreditNote', 'lines' );
can_ok( 'Net::API::Stripe::Billing::CreditNote', 'livemode' );
can_ok( 'Net::API::Stripe::Billing::CreditNote', 'memo' );
can_ok( 'Net::API::Stripe::Billing::CreditNote', 'metadata' );
can_ok( 'Net::API::Stripe::Billing::CreditNote', 'number' );
can_ok( 'Net::API::Stripe::Billing::CreditNote', 'object' );
can_ok( 'Net::API::Stripe::Billing::CreditNote', 'out_of_band_amount' );
can_ok( 'Net::API::Stripe::Billing::CreditNote', 'pdf' );
can_ok( 'Net::API::Stripe::Billing::CreditNote', 'reason' );
can_ok( 'Net::API::Stripe::Billing::CreditNote', 'refund' );
can_ok( 'Net::API::Stripe::Billing::CreditNote', 'status' );
can_ok( 'Net::API::Stripe::Billing::CreditNote', 'subtotal' );
can_ok( 'Net::API::Stripe::Billing::CreditNote', 'subtotal_excluding_tax' );
can_ok( 'Net::API::Stripe::Billing::CreditNote', 'tax_amounts' );
can_ok( 'Net::API::Stripe::Billing::CreditNote', 'total' );
can_ok( 'Net::API::Stripe::Billing::CreditNote', 'total_excluding_tax' );
can_ok( 'Net::API::Stripe::Billing::CreditNote', 'type' );
can_ok( 'Net::API::Stripe::Billing::CreditNote', 'voided_at' );
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
my $json_file = $sample_dir->child( 'credit_note.json' ) ||
    BAIL_OUT( $sample_dir->error );
if( $json_file->exists )
{
    if( !$json_file->can_read )
    {
        my $rel = $json_file->relative;
        BAIL_OUT( "Unable to read json file $rel for Stripe class 'credit_note'" );
    }
    elsif( !$json_file->is_empty )
    {
        $code = $json_file->load_json ||
            BAIL_OUT( "Failed to load json data for Stripe class 'credit_note': " . $json_file->error );
    }
}
my $obj = scalar( keys( %$code ) ) ? Net::API::Stripe::Billing::CreditNote->new( $code ) : Net::API::Stripe::Billing::CreditNote->new;
isa_ok( $obj => 'Net::API::Stripe::Billing::CreditNote' );

done_testing();

__END__

