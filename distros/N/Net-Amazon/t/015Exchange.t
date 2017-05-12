###########################################
# Tests for Exchange requests
# Mike Schilli, 2004 (m@perlmeister.com)
###########################################
use warnings;
use strict;

use Test::More tests => 17;
use Net::Amazon;
use Net::Amazon::Result::Seller::Listing;
use Log::Log4perl qw(:easy);
#Log::Log4perl->easy_init($DEBUG);

################################################################
# Setup
################################################################
  my($TESTDIR) = map { -d $_ ? $_ : () } qw(t ../t .);
  require "$TESTDIR/init.pl";
  my $CANNED = "$TESTDIR/canned";
################################################################
  canned($CANNED, "exchange.xml");
################################################################

my $ua = Net::Amazon->new(
    associate_tag => 'YOUR_AMZN_ASSOCIATE_TAG',
    token       => 'YOUR_AMZN_TOKEN',
    secret_key  => 'YOUR_AMZN_SECRET_KEY',
    #response_dump => 1,
);

# Get a request object
my $resp = $ua->search(exchange => 'Y04Y3424291Y2398445');

ok($resp->is_success(), "Successful response");
ok(defined $resp->result(), "Defined seller result");

like($resp->result()->as_string(), qr/^Setting the Mould.*?\(0393023826\)/,
   "Exchange result as string");

my $listing = $resp->result();

is($listing->ExchangeStartDate(), "2003-12-20", 
   "Listing Exchange Start Date");

is($listing->ExchangeAsin(), "0393023826", 
   "Listing Exchange Asin");

is($listing->ExchangeConditionType(), "verygood", 
   "Listing ExchangeConditionType");

is($listing->ExchangeSellerId(), "A23JJ2BNHZMFCO", 
    "Listing ExchangeSellerId");

is($listing->ExchangeEndDate(), "2006-12-04",
    "Listing ExchangeEndDate");

is($listing->ExchangePrice(), '$10.58', 
    "Listing ExchangePrice");

# These functions require a separate search to get this value, use SellerLookup
# is($listing->ExchangeSellerRating(), "4.7", 
#     "Listing ExchangeSellerRating");
# is($listing->ExchangeSellerCountry(), "", 
#     "Listing ExchangeSellerCountry");
# is($listing->ExchangeSellerState(), "", 
#     "Listing ExchangeSellerState");

# Not sure if these are even available!
# is($listing->ExchangeFeaturedCategory(), "68297", 
#     "Listing ExchangeFeaturedCategory");
# is($listing->ExchangeAvailability(), "Usually ships in 1-2 business days",
#     "Listing ExchangeAvailability");
# is($listing->ExchangeOfferingType(), "used", 
#     "Listing ExchangeOfferingType");
# is($listing->ExchangeDescription(), "Title: Bold Visions for the Garden: Basics, Magic & Inspiration\n: Hartlage, Richard W.\n", "Listing ExchangeDescription");

is($listing->ExchangeStatus(), "Open", 
    "Listing ExchangeStatus");

is($listing->ExchangeId(), "Y01Y4725136Y4353165", 
    "Listing ExchangeId");

is($listing->ExchangeTitle(), "Setting the Mould: The United States and Britain 1945-50  by Edmonds, Robin",
    "Listing ExchangeTitle");

is($listing->ExchangeQuantityAllocated(), "1", 
    "Listing ExchangeQuantityAllocated");

is($listing->ExchangeQuantity(), "1", 
    "Listing ExchangeQuantity");

is($listing->ExchangeSellerNickname(), "brick_road_books", 
    "Listing ExchangeSellerNickname");

is($listing->ListingId(), "1220R554328", 
    "Listing ListingId");

is($listing->ExchangeCondition(), "collectible", 
    "Listing ExchangeCondition");
