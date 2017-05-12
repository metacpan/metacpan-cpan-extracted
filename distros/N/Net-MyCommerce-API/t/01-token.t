#!perl -T

use lib qw( ../lib );

use Test::More tests => 3;

BEGIN {
    use_ok( 'Net::MyCommerce::API::Token' ) || print "Bail out!
";
}

my $token = Net::MyCommerce::API::Token->new();
my ($error, $result) = $token->lookup();
my ($errtype) = split(/:/,$error);
isa_ok( $token, 'Net::MyCommerce::API::Token' );
ok( $errtype eq 'invalid_client', "Error type okay" );

