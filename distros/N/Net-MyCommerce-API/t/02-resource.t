#!perl -T

use lib qw( ../lib );

use Test::More tests => 3;

BEGIN {
    use_ok( 'Net::MyCommerce::API::Resource' ) || print "Bail out!
";
}

my $resource = Net::MyCommerce::API::Resource->new();
my ($error, $result) = $resource->request();
my ($errtype) = split(/:/,$error);
isa_ok( $resource, 'Net::MyCommerce::API::Resource' );
ok( $errtype eq 'invalid_client', "Error type okay" ); 
 


