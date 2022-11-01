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
    use_ok( 'Net::API::Stripe::Connect::Person' ) || BAIL_OUT( "Unable to load perl module 'Net::API::Stripe::Connect::Person'" );
};
can_ok( 'Net::API::Stripe::Connect::Person', 'account' );
can_ok( 'Net::API::Stripe::Connect::Person', 'address' );
can_ok( 'Net::API::Stripe::Connect::Person', 'address_kana' );
can_ok( 'Net::API::Stripe::Connect::Person', 'address_kanji' );
can_ok( 'Net::API::Stripe::Connect::Person', 'created' );
can_ok( 'Net::API::Stripe::Connect::Person', 'dob' );
can_ok( 'Net::API::Stripe::Connect::Person', 'email' );
can_ok( 'Net::API::Stripe::Connect::Person', 'first_name' );
can_ok( 'Net::API::Stripe::Connect::Person', 'first_name_kana' );
can_ok( 'Net::API::Stripe::Connect::Person', 'first_name_kanji' );
can_ok( 'Net::API::Stripe::Connect::Person', 'full_name_aliases' );
can_ok( 'Net::API::Stripe::Connect::Person', 'future_requirements' );
can_ok( 'Net::API::Stripe::Connect::Person', 'gender' );
can_ok( 'Net::API::Stripe::Connect::Person', 'id' );
can_ok( 'Net::API::Stripe::Connect::Person', 'id_number_provided' );
can_ok( 'Net::API::Stripe::Connect::Person', 'id_number_secondary_provided' );
can_ok( 'Net::API::Stripe::Connect::Person', 'last_name' );
can_ok( 'Net::API::Stripe::Connect::Person', 'last_name_kana' );
can_ok( 'Net::API::Stripe::Connect::Person', 'last_name_kanji' );
can_ok( 'Net::API::Stripe::Connect::Person', 'maiden_name' );
can_ok( 'Net::API::Stripe::Connect::Person', 'metadata' );
can_ok( 'Net::API::Stripe::Connect::Person', 'nationality' );
can_ok( 'Net::API::Stripe::Connect::Person', 'object' );
can_ok( 'Net::API::Stripe::Connect::Person', 'phone' );
can_ok( 'Net::API::Stripe::Connect::Person', 'political_exposure' );
can_ok( 'Net::API::Stripe::Connect::Person', 'registered_address' );
can_ok( 'Net::API::Stripe::Connect::Person', 'relationship' );
can_ok( 'Net::API::Stripe::Connect::Person', 'requirements' );
can_ok( 'Net::API::Stripe::Connect::Person', 'ssn_last_4_provided' );
can_ok( 'Net::API::Stripe::Connect::Person', 'verification' );
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
my $json_file = $sample_dir->child( 'person.json' ) ||
    BAIL_OUT( $sample_dir->error );
if( $json_file->exists )
{
    if( !$json_file->can_read )
    {
        my $rel = $json_file->relative;
        BAIL_OUT( "Unable to read json file $rel for Stripe class 'person'" );
    }
    elsif( !$json_file->is_empty )
    {
        $code = $json_file->load_json ||
            BAIL_OUT( "Failed to load json data for Stripe class 'person': " . $json_file->error );
    }
}
my $obj = scalar( keys( %$code ) ) ? Net::API::Stripe::Connect::Person->new( $code ) : Net::API::Stripe::Connect::Person->new;
isa_ok( $obj => 'Net::API::Stripe::Connect::Person' );

done_testing();

__END__

