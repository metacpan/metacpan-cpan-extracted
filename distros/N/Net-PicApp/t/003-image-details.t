# -*- perl -*-

# t/003_image-details.t - check get image details

use lib './t/';
use Test::More tests => 6;
use TestUtil qw(apikey);

my $key = apikey();

BEGIN {
    use_ok( 'Net::PicApp' );
}

my $pa = Net::PicApp->new(
    {
        apikey     => $key,
    }
);
my $response = $pa->get_image_details(93804);
isa_ok($response,'Net::PicApp::Response');

my $i = $response->images();
isa_ok($i,"Net::PicApp::Image");
ok( $i->{imageTitle} eq 'Siberian tiger walking in snow', "Image title is 'Siberian tiger walking in snow'?" . $i->{imageTitle} );

my @keywords = $i->keywords();
ok(@keywords);
ok( $#keywords == 19, "Keywords is 19? " . $#keywords );
