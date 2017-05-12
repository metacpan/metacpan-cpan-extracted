#########################
# Artist Search tests
#########################
use warnings;
use strict;

use Test::More tests => 23;
BEGIN { use_ok('Net::Amazon') };

#use Log::Log4perl qw(:easy);
#Log::Log4perl->easy_init($INFO);

use Net::Amazon;
use Net::Amazon::Request::Director;

################################################################
# Setup
################################################################
  my($TESTDIR) = map { -d $_ ? $_ : () } qw(t ../t .);
  require "$TESTDIR/init.pl";
  my $CANNED = "$TESTDIR/canned";
################################################################
  canned($CANNED, "director.xml");
################################################################

my $ua = Net::Amazon->new(
    associate_tag => 'YOUR_AMZN_ASSOCIATE_TAG',
    token         => 'YOUR_AMZN_TOKEN',
    secret_key    => 'YOUR_AMZN_SECRET_KEY',
    #response_dump => 1,
);

my $req = Net::Amazon::Request::Director->new(
    director => "miyazaki",
);

   # Response is of type Net::Amazon::Artist::Response
my $resp = $ua->request($req);

ok($resp->is_success(), "Request successful");
my @properties = $resp->properties();
is(scalar @properties, 10, "10 movies");

like($resp->as_string(), qr/Totoro.*?Ponyo/s, "Examine Movies");

my $i = 1;
my @starring = $properties[$i]->starring();

is($properties[$i]->actor, "Hitoshi Takagi", "Check actor");
is($starring[0], "Hitoshi Takagi", "Check starring");
is($properties[$i]->director, "Hayao Miyazaki", "Check director");
like($properties[$i]->title, qr/My Neighbor Totoro/, "Check title");
is($properties[$i]->studio, "Disney Presents Studio Ghibli", "Check studio");
is($properties[$i]->ReleaseDate, "2010-03-02", "Check release date");
is($properties[$i]->media, "DVD", "Check media");
is($properties[$i]->Media, "DVD", "Check Media");
is($properties[$i]->nummedia, 2, "Check nummedia");
is($properties[$i]->NumMedia, 2, "Check NumMedia");
is($properties[$i]->upc, "786936791716", "Check UPC");
like($properties[$i]->mpaa_rating, qr/G \(General Audience\)/, "Check MPAA rating");
is($properties[$i]->region_code, 1, "Check region code");
is($properties[$i]->label, "Disney Presents Studio Ghibli", "Check label");
is($properties[$i]->running_time, "86", "Check running time");
is($properties[$i]->publisher, "Disney Presents Studio Ghibli", "Check publisher");
is($properties[$i]->ean, "0786936791716", "Check ean");
is($properties[$i]->feature, "Animated", "Check feature");
is(scalar($properties[$i]->features), 8, "Check number of features");

