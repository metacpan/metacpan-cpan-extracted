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
use Net::Amazon::Request::Actor;

################################################################
# Setup
################################################################
  my($TESTDIR) = map { -d $_ ? $_ : () } qw(t ../t .);
  require "$TESTDIR/init.pl";
  my $CANNED = "$TESTDIR/canned";
################################################################
  canned($CANNED, "actor.xml");
################################################################

my $ua = Net::Amazon->new(
    associate_tag => 'YOUR_ASSOCIATE_TAG',
    token         => 'YOUR_AMZN_TOKEN',
    secret_key    => 'YOUR_AMZN_SECRET_KEY',
    #response_dump => 1,
);

my $req = Net::Amazon::Request::Actor->new(
    actor => "Sandler",
);

   # Response is of type Net::Amazon::Artist::Response
my $resp = $ua->request($req);

ok($resp->is_success(), "Request successful");
my @properties = $resp->properties();
is(scalar @properties, 10, "10 movies");

my $i = 1;

like($resp->as_string(), qr/Zookeeper.*?Gilmore/s, "Examine Movies");

my @starring = $properties[$i]->starring();

is($properties[$i]->actor, "Jennifer Aniston", "Check actor");
is($starring[$i], "Adam Sandler", "Check starring");
is($properties[$i]->director, "Dennis Dugan", "Check director");
like($properties[$i]->title, qr/Just Go With.*/, "Check title");
is($properties[$i]->studio, "Columbia Pictures", "Check studio");
is($properties[$i]->ReleaseDate, "2011-06-07", "Check release date");
#is($properties[$i]->theatrical_release_date, "1998", "Check theatrical release date");
is($properties[$i]->media, "DVD", "Check media");
is($properties[$i]->Media, "DVD", "Check Media");
is($properties[$i]->nummedia, 1, "Check nummedia");
is($properties[$i]->NumMedia, 1, "Check NumMedia");
is($properties[$i]->upc, "043396376793", "Check UPC");
like($properties[$i]->mpaa_rating, qr/PG\-13/, "Check MPAA rating");
is($properties[$i]->region_code, 1, "Check region code");
is($properties[$i]->label, "Columbia Pictures", "Check label");
is($properties[$i]->running_time, "117", "Check running time");
is($properties[$i]->publisher, "Columbia Pictures", "Check publisher");
is($properties[$i]->ean, "0043396376793", "Check ean");
is($properties[$i]->feature, "AC-3", "Check feature");
is(scalar($properties[$i]->features), 9, "Check number of features");

