#########################
# MP3Downloads Search tests
#########################
use warnings;
use strict;

use Test::More tests => 17;
BEGIN { use_ok('Net::Amazon') };

#use Log::Log4perl qw(:easy);
#Log::Log4perl->easy_init($INFO);

use Net::Amazon;
use Net::Amazon::Request::MP3Downloads;

################################################################
# Setup
################################################################
  my($TESTDIR) = map { -d $_ ? $_ : () } qw(t ../t .);
  require "$TESTDIR/init.pl";
  my $CANNED = "$TESTDIR/canned";
################################################################
  canned($CANNED, "mp3downloads.xml");
################################################################

my $ua = Net::Amazon->new(
    associate_tag => 'YOUR_AMZN_ASSOCIATE_TAG',
    token         => 'YOUR_AMZN_TOKEN',
    secret_key    => 'YOUR_AMZN_SECRET_KEY',
    max_pages     => 1,
    # response_dump => 1,
);

my $req = Net::Amazon::Request::MP3Downloads->new(
    title => "Hand in My Pocket",
);

#Response is of type Net::Amazon::Response::MP3Downloads
my $resp = $ua->request($req);

ok($resp->is_success(), "Request successful");
my @properties = $resp->properties();
is(scalar @properties, 10, "10 mp3 downloads");

like($resp->as_string(), qr/Alanis.*?Hand In My Pocket.*?2008.*?0.99/s, "Examine response as_string()");

@properties = $resp->properties();
is($properties[0]->binding, 'MP3 Download', "Check binding");
is($properties[0]->artists, 1, "Check artists size");
my @artists = $properties[0]->artists();
is($artists[0], 'Alanis Morissette', "Check artists");
is($properties[0]->artist, 'Alanis Morissette', "Check artist");
is($properties[0]->genre, 'pop-music', "Check genre");
is($properties[0]->label, 'Maverick', "Check label");
is($properties[0]->manufacturer, '', "Check manufacturer");
is($properties[0]->publisher, 'Maverick', "Check binding");
is($properties[0]->release_date, '2008-12-23', "Check release date");
is($properties[0]->running_time, 221, "Check running time");
is($properties[0]->studio, 'Maverick', "Check studio");
is($properties[0]->title, 'Hand In My Pocket', "Check title");
is($properties[0]->track_sequence, 4, "Check track sequence");
