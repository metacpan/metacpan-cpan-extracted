# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use warnings;
use strict;

use Test::More tests => 37;
BEGIN { use_ok('Net::Amazon') };

#use Log::Log4perl qw(:easy);
#Log::Log4perl->easy_init($INFO);

use Net::Amazon::Request::ASIN;
use Net::Amazon::Response::ASIN;
use File::Spec;

my $CANNED = "canned";
$CANNED = File::Spec->catfile("t", "canned") unless -d $CANNED;

if(! exists $ENV{NET_AMAZON_LIVE_TESTS}) {
    for(map { File::Spec->catfile($CANNED, $_) }
        qw(asin_pp.xml asin_err.xml 
           asin_mua.xml asin_cd.xml asin_cdm.xml dvd.xml)) {
        open FILE, "<$_" or die "Cannot open $_";
        my $data = join '', <FILE>;
        close FILE;
        push @Net::Amazon::CANNED_RESPONSES, $data;
    }
}

######################################################################
# Successful ASIN fetch
######################################################################
my $ua = Net::Amazon->new(
    associate_tag => 'YOUR_AMZN_ASSOCIATE_TAG',
    token       => 'YOUR_AMZN_TOKEN',
    secret_key  => 'YOUR_AMZN_SECRET_KEY',
);

my $req = Net::Amazon::Request::ASIN->new(
    asin  => '0201360683'
);

   # Response is of type Net::Amazon::ASIN::Response
my $resp = $ua->request($req);

ok($resp->is_success(), "Successful fetch");
like($resp->as_string(), qr/Schilli/, "Found Perl Power");

######################################################################
# Error fetching ASIN
######################################################################
$req = Net::Amazon::Request::ASIN->new(
    asin  => '123'
);

   # Response is of type Net::Amazon::ASIN::Response
$resp = $ua->request($req);

ok($resp->is_error(), "Error reported correctly");
like($resp->message(), qr/not a valid value/, "Invalid ASIN reported correctly");

######################################################################
# Multiple Authors
######################################################################
$req = Net::Amazon::Request::ASIN->new(
    asin  => '0201633612'
);

   # Response is of type Net::Amazon::ASIN::Response
$resp = $ua->request($req);

ok($resp->is_success(), "Found Gamma");
my($book) = $resp->properties();
like(join('&', $book->authors()), 
     qr#Gamma.*?Vlissides#,
     "Found multiple authors");
is($book->numpages(), 416, "Checkiing numpages");
is($book->dewey_decimal(), "", "Checkiing dewey_decimal");

my @similar = $book->similar_asins();
is(scalar @similar, 0, "No similar items on this item");

######################################################################
# properties() in scalar context
######################################################################
$book = $resp->properties();
like(join('&', $book->authors()), 
     qr#Erich Gamma&Richard Helm&Ralph Johnson&John Vlissides#,
     "Found multiple authors");

######################################################################
# Net::Amazon::Property::Book accessors
######################################################################
like($book->title, qr/^Design Patterns/, "Title");
like($book->ProductName, qr/^Design Patterns/, "ProductName");
is($book->year, "1994", "Year");
is($book->publication_date, "1994-11-10");
like($book->OurPrice, qr/\$/, "Amazon Price");
is($book->ListPrice, '$59.99', "List Price");
is($book->CurrencyCode, "USD");
is($book->binding, "Hardcover", "Binding");

# check RawListPrice eq ListPrice without the 
# dollar sign and decimal point
my $ListPrice = $book->ListPrice;
$ListPrice =~ s/\$//;
$ListPrice =~ s/\.//;

is($book->RawListPrice, $ListPrice);

######################################################################
# Successful ASIN fetch of a music CD
######################################################################
$req = Net::Amazon::Request::ASIN->new(
    asin  => 'B00007M84Q',
    mode  => 'music',
);

   # Response is of type Net::Amazon::ASIN::Response
$resp = $ua->request($req);

ok($resp->is_success(), "Successful fetch");
like($resp->as_string(), qr/Zwan/, "Found Zwan");

######################################################################
# Net::Amazon::Property::Music accessors
######################################################################
my($cd) = $resp->properties();
is($cd->album, "Mary Star of the Sea", "Album");
is($cd->artist, "Zwan", "Artist");
is($cd->year, "2003", "Year");
like($cd->OurPrice, qr/\$/, "Amazon Price");
like($cd->ListPrice, qr/\$/, "List Price");

######################################################################
# Net::Amazon::Property::Music item with two artists
######################################################################
$req = Net::Amazon::Request::ASIN->new(
    asin  => 'B00005A46I',
    mode  => 'music',
);

   # Response is of type Net::Amazon::ASIN::Response
$resp = $ua->request($req);

ok($resp->is_success(), "Successful fetch");
like($resp->as_string(), qr(Anne Sofie von Otter/Elvis Costello), 
     "Found Otter/Costello");
($cd) = $resp->properties();
is($cd->artist(), "Anne Sofie von Otter", "artist() on mult artists");
is(join('#', $cd->artists()), "Anne Sofie von Otter#Elvis Costello",
    "artists() with mult artists");

######################################################################
# Net::Amazon::Property::DVD item with two artists
######################################################################
$req = Net::Amazon::Request::ASIN->new(
    asin  => '6305181772',
);

   # Response is of type Net::Amazon::ASIN::Response
$resp = $ua->request($req);

ok($resp->is_success(), "Successful fetch");
like($resp->as_string(), qr(Mission Impossible), 
     "Found Mission Impossible");
my ($dvd) = $resp->properties();

is($dvd->director(), undef, "director() finds first director");
like($dvd->SalesRank(), qr/^[\d,]+$/, "Checking SalesRank");
#is(join('#', $dvd->directors()), "", "directors() finds first director");

# XXX: this information is not readily available in AWS4
# like(join('#', $dvd->starring()), qr/Tom Cruise#Jon Voight#Emmanuelle B/, 
#      "starring() finds actors");

is($resp->total_results, 1, "Total of 1");

######################################################################
# Illegal request type
######################################################################
eval {$req = Net::Amazon::Request::ASIN->new(asin  => "6305181772",
                                             type  => "whackamole");};
like($@, qr/Unknown type/, "Check illegal request type");
