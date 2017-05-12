# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use warnings;
use strict;

use Test::More tests => 13;
BEGIN { use_ok('Net::Amazon') };

use Net::Amazon::Request::EAN;
use Net::Amazon::Response::EAN;
use File::Spec;

my $CANNED = "canned";
$CANNED = File::Spec->catfile("t", "canned") unless -d $CANNED;

#Only for debugging
#use Log::Log4perl qw(:easy);
#Log::Log4perl->easy_init($DEBUG);

######################################################################
# Successful EAN fetch
######################################################################

canned("ean.xml");

my $ua = Net::Amazon->new(
    associate_tag => 'YOUR_AMZN_ASSOCIATE_TAG',
    token       => 'YOUR_AMZN_TOKEN',
    secret_key  => 'YOUR_AMZN_SECRET_KEY',
    locale      => 'uk',
);

my $req = Net::Amazon::Request::EAN->new(
    ean => '5035822647633',
);

   # Response is of type Net::Amazon::Response::ISBN
my $resp = $ua->request($req);

ok($resp->is_success(), "Successful fetch");
like($resp->as_string(), qr#U-Turn#, "Found U-Turn");

######################################################################
# Parameters
######################################################################
my $p = ($resp->properties)[0];
is($p->Asin(), "B00004CXLB", "ASIN is B00004CXLB");
is($p->SalesRank(), "21838", "SalesRank is 21838");
is($p->actor(), "Sean Penn", "Actor is Sean Penn");
is($p->ean(), "5024165771907", "EAN is 5024165771907");
is($p->director(), "Oliver Stone", "Director is Oliver Stone");
like($p->label(), qr#Sony Pictures#, "Label is Sony Pictures");
is($p->region_code(), '2', "Region Code is 2");
is($p->running_time(), "119", "Running Time is 119");
like($p->studio(), qr#Sony Pictures Home#, "Studio is Sony Pictures");
like($p->title(), qr#U-Turn#, "Title is U-Turn");

######################################################################
# handle canned responses
######################################################################
sub canned {
    my($file) = @_;

    if(! exists $ENV{NET_AMAZON_LIVE_TESTS} ) {
        $file = File::Spec->catfile($CANNED, $file);
        open FILE, "<$file" or die "Cannot open $file";
        my $data = join '', <FILE>;
        close FILE;
        push @Net::Amazon::CANNED_RESPONSES, $data;
    }
}
