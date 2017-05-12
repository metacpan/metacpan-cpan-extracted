###########################################
# Keyword search tests
# Mike Schilli, 2004 (m@perlmeister.com)
###########################################
use warnings;
use strict;

use Test::More tests => 25;
use Net::Amazon;
use Net::Amazon::Request::Seller;
#use Log::Log4perl qw(:easy);
#Log::Log4perl->easy_init($DEBUG);

################################################################
# Setup
################################################################
  my($TESTDIR) = map { -d $_ ? $_ : () } qw(t ../t .);
  require "$TESTDIR/init.pl";
  my $CANNED = "$TESTDIR/canned";
################################################################
  canned($CANNED, "seller.xml");
################################################################

my $ua = Net::Amazon->new(
    associate_tag => 'YOUR_ASSOCIATE_TAG',
    token       => 'YOUR_AMZN_TOKEN',
    secret_key  => 'YOUR_AMZN_SECRET_KEY',
    #response_dump => 1,
);

my $req = Net::Amazon::Request::Seller->new(
    seller  => 'A2GXAGU54VOP7',
);

my $resp = $ua->request(
    $req,
);

ok($resp->is_success(), "Successful response");
ok(defined $resp->result(), "Defined seller result");
is($resp->result()->as_string(), "brick_road_books (brick_road_books): 10",
   "Seller result");
is($resp->result()->StoreId(), "A23JJ2BNHZMFCO", "StoreId accessor");
is($resp->result()->SellerId(), "A23JJ2BNHZMFCO", "SellerId accessor");
is($resp->result()->as_string(), "brick_road_books (brick_road_books): 10",
   "Seller as_string()");

# listings
my @listings = $resp->result()->listings();

is($listings[0]->ExchangeStartDate(), "2008-09-19",
   "Listing 1 Start Date");
is($listings[0]->ExchangeEndDate(), "",
   "Listing 1 End Date");
is($listings[1]->ExchangeStartDate(), "2008-09-19",
   "Listing 2 Start Date");
is($listings[1]->ExchangeEndDate(), "",
   "Listing 2 End Date");

is($listings[0]->ExchangeAsin(), "0376055723", "listings 1 Asin");
like($listings[0]->ExchangeTitle(), qr/National Parks of the West/, "listings 1 Title");
is($listings[0]->ListingId(), "1221T896306", "listings 1 listingsId");
is($listings[0]->ExchangeId(), "Y11M5526205M1732079", "listings 1 ExchangeId");
is($listings[0]->ExchangeQuantityAllocated(), "1", "listings 1 ExchangeQuantityAllocated");
is($listings[0]->ExchangeQuantity(), "1", "listings 1 ExchangeQuantity");
is($listings[0]->ExchangeCondition(), "used", "listings 1 ExchangeCondition");
is($listings[0]->ExchangeConditionType(), "good", "listings 1 ExchangeConditionType");
is($listings[0]->ExchangeSubCondition(), "good", "listings 1 ExchangeSubCondition");
is($listings[0]->ExchangeStatus(), "Open", "listings 1 ExchangeStatus");
is($listings[0]->ExchangePrice(), '$4.05', "listings 1 ExchangePrice");
is($listings[0]->ExchangeCurrencyCode(), "USD", "listings 1 ExchangeCurrencyCode");
is($listings[0]->ExchangeAmount(), "405", "listings 1 ExchangeAmount");
is($listings[0]->ExchangeSellerId(), "A23JJ2BNHZMFCO", "listings 1 ExchangeSellerId");
is($listings[0]->ExchangeSellerNickname(), "brick_road_books", "listings 1 ExchangeSellerNickname");
