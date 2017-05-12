# -*- perl -*-

# t/002_search.t - check module loading

use lib './t/';
use Test::More tests => 7;
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
my $response = $pa->search('cats');
isa_ok($response,'Net::PicApp::Response');

ok( $response->rss_link eq 'http://www.picapp.com/Feed/cats.rss', "RSS Link is correct?" );
ok( $response->record_count == 200, "Record count is 200? " . $response->record_count );
ok( $response->total_records > 1, "Total records > 1? " . $response->total_records );

my $c = 0;
my @images = $response->images();
ok( @images );
ok( $#images == 199, "Number of images is 199? " . $#images );
