# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use warnings;
use strict;

use Test::More tests => 17;
BEGIN { use_ok('Net::Amazon') };

use Net::Amazon::Request::ISBN;
use Net::Amazon::Response::ISBN;
use File::Spec;

my $CANNED = "canned";
$CANNED = File::Spec->catfile("t", "canned") unless -d $CANNED;

#Only for debugging
#use Log::Log4perl qw(:easy);
#Log::Log4perl->easy_init($DEBUG);

######################################################################
# Successful ISBN fetch
######################################################################

canned("isbn.xml");

my $ua = Net::Amazon->new(
    associate_tag => 'YOUR_AMZN_ASSOCIATE_TAG',
    token       => 'YOUR_AMZN_TOKEN',
    secret_key  => 'YOUR_AMZN_SECRET_KEY',
);

my $req = Net::Amazon::Request::ISBN->new(
    isbn => '0439784549',
);

   # Response is of type Net::Amazon::Response::ISBN
my $resp = $ua->request($req);

ok($resp->is_success(), "Successful fetch");
like($resp->as_string(), qr#Harry Potter and the Half-Blood Prince#, "Found Rowling");

######################################################################
# Parameters
######################################################################
my $p = ($resp->properties)[0];
is($p->Asin(), "0439784549", "ASIN is 0439784549");
is($p->title(), "Harry Potter and the Half-Blood Prince (Book 6)", "Title is Harry Potter and the Half-Blood Prince (Book 6)");
is($p->Title(), "Harry Potter and the Half-Blood Prince (Book 6)", "Title is Harry Potter and the Half-Blood Prince (Book 6)");
is($p->author(), "J.K. Rowling", "Author is J.K. Rowling");
is($p->publisher(), "Scholastic, Inc.", "Publisher is Scholastic, Inc.");

######################################################################
# non-US locale  (13-digit ISBN)
######################################################################

canned("isbn-de.xml");

$ua = Net::Amazon->new(
    associate_tag => 'YOUR_AMZN_ASSOCIATE_TAG',
    token       => 'YOUR_AMZN_TOKEN',
    secret_key  => 'YOUR_AMZN_SECRET_KEY',
    locale      => 'de',
);

$req = Net::Amazon::Request::ISBN->new(
    isbn => '9783570009222',
);

   # Response is of type Net::Amazon::Response::ISBN
$resp = $ua->request($req);

ok($resp->is_success(), "Successful fetch");
like($resp->as_string(), qr#Der Ausflug#, "Found Der Ausflug");

######################################################################
# Parameters
######################################################################
$p = ($resp->properties)[0];
is($p->Asin(), "357000922X", "ASIN is 357000922X");
is($p->title(), "Der Ausflug", "Title is Der Ausflug");
is($p->Title(), "Der Ausflug", "Title is Der Ausflug");
is($p->author(), "Renate Dorrestein", "Author is Renate Dorrestein");
is($p->numpages(), "314", "Number of pages is 314");
is($p->ean(), "9783570009222", "EAN is 9783570009222");
is($p->isbn(), "357000922X", "ISBN is 357000922X");

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
