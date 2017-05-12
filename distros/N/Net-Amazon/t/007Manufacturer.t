# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use warnings;
use strict;

use Test::More tests => 3;
BEGIN { use_ok('Net::Amazon') };

use Net::Amazon::Request::Manufacturer;
use Net::Amazon::Response::Manufacturer;
use File::Spec;

my $CANNED = "canned";
$CANNED = File::Spec->catfile("t", "canned") unless -d $CANNED;

#Only for debugging
#use Log::Log4perl qw(:easy);
#Log::Log4perl->easy_init($DEBUG);

######################################################################
# Successful Manufacturer fetch
######################################################################

canned("manufacturer.xml");

my $ua = Net::Amazon->new(
    associate_tag => 'YOUR_AMZN_ASSOCIATE_TAG',
    token       => 'YOUR_AMZN_TOKEN',
    secret_key  => 'YOUR_AMZN_SECRET_KEY',
);

my $req = Net::Amazon::Request::Manufacturer->new(
    manufacturer  => 'Disney',
);

   # Response is of type Net::Amazon::Manufacturer::Response
my $resp = $ua->request($req);

ok($resp->is_success(), "Successful fetch");

######################################################################
# Parameters
######################################################################
my $p = ($resp->properties)[-1];
like($p->manufacturer(), qr/Disney/, "Manufacturer is Disney");

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
