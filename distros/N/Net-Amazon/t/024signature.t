#########################
# Signature Test
#########################
use warnings;
use strict;
use utf8; # Needed to include utf8 strings
use Encode;

use Test::More tests => 6;
BEGIN { use_ok('Net::Amazon') };

#use Log::Log4perl qw(:easy);
#Log::Log4perl->easy_init($INFO);

use Net::Amazon;
use Net::Amazon::Request::Title;
use URI;

################################################################
# Setup
################################################################
  my($TESTDIR) = map { -d $_ ? $_ : () } qw(t ../t .);
  require "$TESTDIR/init.pl";
  my $CANNED = "$TESTDIR/canned";
################################################################
  canned($CANNED, "title.xml");
################################################################

my $ua = Net::Amazon->new(
    associate_tag => 'YOUR_AMZN_ASSOCIATE_TAG',
    token         => 'YOUR_AMZN_TOKEN',
    secret_key    => 'YOUR_AMZN_SECRET_KEY',
    #response_dump => 1,
);

my $test_url = encode('utf8', 'http://webservices.amazon.com/onca/xml?Service=AWSECommerceService&AWSAccessKeyId=YOUR_AMZN_TOKEN&Operation=ItemSearch&Keywords=Bublé&SearchIndex=Music&ResponseGroup=ItemAttributes,Offers&Version=2009-03-31&Timestamp=2009-06-02T16:31:39Z');
my $uri = $ua->_sign_request(URI->new($test_url));
is($uri->as_string, 'http://webservices.amazon.com/onca/xml?AWSAccessKeyId=YOUR_AMZN_TOKEN&Keywords=Bubl%C3%A9&Operation=ItemSearch&ResponseGroup=ItemAttributes%2COffers&SearchIndex=Music&Service=AWSECommerceService&Timestamp=2009-06-02T16%3A31%3A39Z&Version=2009-03-31&Signature=RkYJYZyrZ8LVc%2F4cIBYmW2GyX9xfQj6UtBm7LiqJfd0%3D', "Request with UTF-8 signed properly");

$test_url = 'http://webservices.amazon.com/onca/xml?Service=AWSECommerceService&AWSAccessKeyId=YOUR_AMZN_TOKEN&Operation=ItemSearch&Keywords=Ayn%20Rand&SearchIndex=Music&ResponseGroup=ItemAttributes,Offers&Version=2009-03-31&Timestamp=2009-06-02T16:31:39Z';
$uri = $ua->_sign_request(URI->new($test_url));
is($uri->as_string, 'http://webservices.amazon.com/onca/xml?AWSAccessKeyId=YOUR_AMZN_TOKEN&Keywords=Ayn%20Rand&Operation=ItemSearch&ResponseGroup=ItemAttributes%2COffers&SearchIndex=Music&Service=AWSECommerceService&Timestamp=2009-06-02T16%3A31%3A39Z&Version=2009-03-31&Signature=azs6N9v73IPR19uxWms72y7TWFHp4QLBMbQIX9%2FRK1o%3D', "Request with space signed properly");


my $req = Net::Amazon::Request::Title->new(
    title => "cagliostro",
);

   # Response is of type Net::Amazon::Artist::Response
my $resp = $ua->request($req);

ok($resp->is_success(), "Request successful");
my @properties = $resp->properties();
is(scalar @properties, 10, "Number of Titles");

like($resp->as_string(), qr/Faulks.*?Cagliostro/s, "Examine Movies");

#my @starring = $properties[$i]->starring();
# is($properties[0]->actor, "Yasuo Yamada", "Check actor");
# is($starring[0], "Yasuo Yamada", "Check starring");
# is($properties[0]->director, "Hayao Miyazaki", "Check director");
# like($properties[0]->title, qr/Castle of Cagliostro/, "Check title");
# is($properties[0]->studio, "Manga Video", "Check studio");
# is($properties[0]->ReleaseDate, "1991-04-03", "Check release date");
# is($properties[0]->media, "DVD", "Check media");
# is($properties[0]->Media, "DVD", "Check Media");
# is($properties[0]->nummedia, 1, "Check nummedia");
# is($properties[0]->NumMedia, 1, "Check NumMedia");
# is($properties[0]->upc, "013138206695", "Check UPC");
# like($properties[0]->mpaa_rating, qr/PG/, "Check MPAA rating");
# is($properties[0]->region_code, '', "Check region code");
# is($properties[0]->label, "Manga Video", "Check label");
# is($properties[0]->running_time, "109", "Check running time");
# is($properties[0]->publisher, "Manga Video", "Check publisher");
# is($properties[0]->ean, "0013138206695", "Check ean");
# is($properties[0]->feature, "Color", "Check feature");
# is(scalar($properties[0]->features), 5, "Check number of features");
# 
