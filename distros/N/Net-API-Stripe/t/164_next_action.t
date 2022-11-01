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
    use_ok( 'Net::API::Stripe::Payment::Intent::NextAction' ) || BAIL_OUT( "Unable to load perl module 'Net::API::Stripe::Payment::Intent::NextAction'" );
};
can_ok( 'Net::API::Stripe::Payment::Intent::NextAction', 'alipay_handle_redirect' );
can_ok( 'Net::API::Stripe::Payment::Intent::NextAction', 'boleto_display_details' );
can_ok( 'Net::API::Stripe::Payment::Intent::NextAction', 'card_await_notification' );
can_ok( 'Net::API::Stripe::Payment::Intent::NextAction', 'display_bank_transfer_instructions' );
can_ok( 'Net::API::Stripe::Payment::Intent::NextAction', 'konbini_display_details' );
can_ok( 'Net::API::Stripe::Payment::Intent::NextAction', 'oxxo_display_details' );
can_ok( 'Net::API::Stripe::Payment::Intent::NextAction', 'paynow_display_qr_code' );
can_ok( 'Net::API::Stripe::Payment::Intent::NextAction', 'promptpay_display_qr_code' );
can_ok( 'Net::API::Stripe::Payment::Intent::NextAction', 'redirect_to_url' );
can_ok( 'Net::API::Stripe::Payment::Intent::NextAction', 'type' );
can_ok( 'Net::API::Stripe::Payment::Intent::NextAction', 'use_stripe_sdk' );
can_ok( 'Net::API::Stripe::Payment::Intent::NextAction', 'verify_with_microdeposits' );
can_ok( 'Net::API::Stripe::Payment::Intent::NextAction', 'wechat_pay_display_qr_code' );
can_ok( 'Net::API::Stripe::Payment::Intent::NextAction', 'wechat_pay_redirect_to_android_app' );
can_ok( 'Net::API::Stripe::Payment::Intent::NextAction', 'wechat_pay_redirect_to_ios_app' );
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
my $json_file = $sample_dir->child( 'next_action.json' ) ||
    BAIL_OUT( $sample_dir->error );
if( $json_file->exists )
{
    if( !$json_file->can_read )
    {
        my $rel = $json_file->relative;
        BAIL_OUT( "Unable to read json file $rel for Stripe class 'next_action'" );
    }
    elsif( !$json_file->is_empty )
    {
        $code = $json_file->load_json ||
            BAIL_OUT( "Failed to load json data for Stripe class 'next_action': " . $json_file->error );
    }
}
my $obj = scalar( keys( %$code ) ) ? Net::API::Stripe::Payment::Intent::NextAction->new( $code ) : Net::API::Stripe::Payment::Intent::NextAction->new;
isa_ok( $obj => 'Net::API::Stripe::Payment::Intent::NextAction' );

done_testing();

__END__

