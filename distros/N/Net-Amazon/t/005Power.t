# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use warnings;
use strict;

use Test::More qw(no_plan);
BEGIN { use_ok('Net::Amazon') };

#use Log::Log4perl qw(:easy);
#Log::Log4perl->easy_init({level => $DEBUG, file => ">out"});

use Net::Amazon;
use File::Spec;

my $CANNED = "canned";
$CANNED = File::Spec->catfile("t", "canned") unless -d $CANNED;

if(! exists $ENV{NET_AMAZON_LIVE_TESTS}) {
    for(map { File::Spec->catfile($CANNED, $_) }
        qw(power.xml power_sorted.xml power_empty.xml power.xml)) {
        open FILE, "<$_" or die "Cannot open $_";
        my $data = join '', <FILE>;
        close FILE;
        push @Net::Amazon::CANNED_RESPONSES, $data;
    }
}

######################################################################
# Successful Power search
######################################################################
my $ua = Net::Amazon->new(
    associate_tag => 'YOUR_AMZN_ASSOCIATE_TAG',
    token       => 'YOUR_AMZN_TOKEN',
    secret_key  => 'YOUR_AMZN_SECRET_KEY',
);

my $resp = $ua->search(
    power => "author: randal schwartz and author: tom phoenix",
    mode  => "books",
);

ok($resp->is_success(), "Successful Power fetch");
like($resp->as_string(), qr/0596004788/, "Found 1");
like($resp->as_string(), qr/0596102062/, "Found 2");
like($resp->as_string(), qr/0596004788/, "Found 3");
like($resp->as_string(), qr/2841772012/, "Found 4");
is($resp->total_results(), 4, "Found 4 total results");

######################################################################
# Power search with different sorting method
######################################################################
$ua = Net::Amazon->new(
    associate_tag => 'YOUR_AMZN_ASSOCIATE_TAG',
    token       => 'YOUR_AMZN_TOKEN',
    secret_key  => 'YOUR_AMZN_SECRET_KEY',
);

$resp = $ua->search(
    power => "author: randal schwartz and author: tom phoenix",
    mode  => "books",
    sort  => "pricerank",
);

ok($resp->is_success(), "Successful sorted power fetch");
my @prices;
for($resp->properties()) {
    my $p = $_->ListPrice();
    next unless $p;
    $p =~ s|^\$||;
    push @prices, $p;
}
my @sorted_prices = sort { $a <=> $b } @prices;
# CMB: it depends upon the price under consideration.
#is("@prices", "@sorted_prices", "Sorted by Price");

######################################################################
# Power search with empty result
######################################################################
$ua = Net::Amazon->new(
    associate_tag => 'YOUR_AMZN_ASSOCIATE_TAG',
    token       => 'YOUR_AMZN_TOKEN',
    secret_key  => 'YOUR_AMZN_SECRET_KEY',
);

$resp = $ua->search(
    power => "author: randal schwartz and author: mike schilli",
    mode  => "books",
);

ok(!$resp->is_success(), "Power fetch came back empty");

######################################################################
# Similar products (could be with any other search, not just 'power')
######################################################################
$ua = Net::Amazon->new(
    associate_tag => 'YOUR_AMZN_ASSOCIATE_TAG',
    token       => 'YOUR_AMZN_TOKEN',
    secret_key  => 'YOUR_AMZN_SECRET_KEY',
);

$resp = $ua->search(
    power => "author: randal schwartz and author: mike schilli",
    mode  => "books",
);

my @expected = qw(
0596003137
0596003749
0596002890
0596002815
0596004788
0596001738
0596004567
0596526741
0596003137
0596002890
0596003137
0596001738
1884777791
0596004567
1565926994
);

for my $item ($resp->properties()) {
    for my $asin ($item->similar_asins()) {
        my $e = shift @expected;
        #print STDERR "ASIN=$asin, EXPECTED=$e\n";
        last unless is($asin, $e, "Get expected similar product");
    }
}

is(scalar @expected, 0, "Got all expected similar products");
