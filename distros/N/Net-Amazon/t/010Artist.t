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
use Net::Amazon::Request::Artist;

################################################################
# Setup
################################################################
  my($TESTDIR) = map { -d $_ ? $_ : () } qw(t ../t .);
  require "$TESTDIR/init.pl";
  my $CANNED = "$TESTDIR/canned";
################################################################
  canned($CANNED, "artist.xml");
################################################################

my $ua = Net::Amazon->new(
    associate_tag => 'YOUR_AMZN_ASSOCIATE_TAG',
    token         => 'YOUR_AMZN_TOKEN',
    secret_key  => 'YOUR_AMZN_SECRET_KEY',
    # response_dump => 1,
);

my $req = Net::Amazon::Request::Artist->new(
    artist  => "Zwan",
);

   # Response is of type Net::Amazon::Artist::Response
my $resp = $ua->request($req);

ok($resp->is_success(), "Request successful");
my @properties = $resp->properties();
is(scalar @properties, 9, "9 hits");

like($resp->as_string(), qr/Honestly.*?Honestly.*?Honestly/s, "Examine Hits");

@properties = $resp->properties();
is($properties[0]->ListPrice, '$13.96', "Check list price");
is($properties[0]->OurPrice, '$11.24', "Check our price");
is($properties[0]->SuperSaverShipping, 1, "Check super saver shipping");
is($properties[0]->artist, "Zwan", "Check artist");
is($properties[0]->album, "Mary Star of the Sea", "Check album");
is($properties[0]->Title, "Mary Star of the Sea", "Check Title");
is($properties[0]->nummedia, "1", "Check nummedia");
is($properties[0]->media, "Audio CD", "Check media");
is($properties[0]->label, "Reprise / Wea", "Check label");
is($properties[0]->publisher, "Reprise / Wea", "Check publisher");
is($properties[0]->studio, "Reprise / Wea", "Check studio");
is($properties[0]->upc, "093624843627", "Check upc");
is($properties[0]->ean, "0093624843627", "Check ean");
is($properties[0]->release_date, "2003-01-28", "Check release_date");
is($properties[0]->label, "Reprise / Wea", "Check label");
my @tracks = $properties[0]->tracks;
is(scalar(@tracks), 14, "Check number of tracks");
is($tracks[1], "Settle Down", "Check tracks one");
is($tracks[8], "Endless Summer", "Check tracks nine");
is($tracks[13], "Come With Me", "Check tracks fourteen");

