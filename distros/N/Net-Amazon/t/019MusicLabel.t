#########################
# MusicLabel Search tests
#########################
use warnings;
use strict;

use Test::More tests => 14;
BEGIN { use_ok('Net::Amazon') };

#use Log::Log4perl qw(:easy);
#Log::Log4perl->easy_init($INFO);

use Net::Amazon;
use Net::Amazon::Request::MusicLabel;

################################################################
# Setup
################################################################
  my($TESTDIR) = map { -d $_ ? $_ : () } qw(t ../t .);
  require "$TESTDIR/init.pl";
  my $CANNED = "$TESTDIR/canned";
################################################################
  canned($CANNED, "musiclabel.xml");
################################################################

my $ua = Net::Amazon->new(
    associate_tag => 'YOUR_AMZN_ASSOCIATE_TAG',
    token         => $ENV{AMAZON_TOKEN},
    secret_key    => 'YOUR_AMZN_SECRET_KEY',
    max_pages     => 1,
    #response_dump => 1,
);

my $req = Net::Amazon::Request::MusicLabel->new(
    musiclabel => "Arista",
);

   # Response is of type Net::Amazon::MusicLabel::Response
my $resp = $ua->request($req);

ok($resp->is_success(), "Request successful");
my @properties = $resp->properties();
is(scalar @properties, 10, "10 records");

like($resp->as_string(), qr/Jackson.*?Carrie Underwood/s, "Examine records");

for ($resp->properties()) {
    like(lc($_->label()), qr/arista/, "Check label");
}
