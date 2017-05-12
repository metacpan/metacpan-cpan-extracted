# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use warnings;
use strict;

use Test::More tests => 19;
BEGIN { use_ok('Net::Amazon') };

use Net::Amazon::Request::UPC;
use Net::Amazon::Response::UPC;
use File::Spec;

my $CANNED = "canned";
$CANNED = File::Spec->catfile("t", "canned") unless -d $CANNED;

#Only for debugging
#use Log::Log4perl qw(:easy);
#Log::Log4perl->easy_init($DEBUG);

######################################################################
# Successful UPC fetch
######################################################################

canned("upc_zwan.xml");

my $ua = Net::Amazon->new(
    associate_tag => 'YOUR_AMZN_ASSOCIATE_TAG',
    token       => 'YOUR_AMZN_TOKEN',
    secret_key  => 'YOUR_AMZN_SECRET_KEY',
);

my $req = Net::Amazon::Request::UPC->new(
    upc  => '093624843627',
    mode => 'music',
);

   # Response is of type Net::Amazon::Response::UPC
my $resp = $ua->request($req);

ok($resp->is_success(), "Successful fetch");
like($resp->as_string(), qr#Mary Star of the Sea#, "Found Zwan");
like($resp->as_string(), qr#Zwan#, "Found Zwan");

######################################################################
# Parameters
######################################################################
my $p = ($resp->properties)[0];
is($p->artist(), "Zwan", "Artist is Zwan");
is($p->album(), "Mary Star of the Sea", "Album is Mary Star of the Sea");
is($p->year(), "2003", "Year is 2003");
is($p->label(), "Reprise / Wea", "Label is Reprise / Wea");
is($p->studio(), "Reprise / Wea", "Studio is Reprise / Wea");
is($p->ean(), "0093624843627", "EAN is 0093624843627");
is($p->NumMedia(), 1, "NumMedia is 1");
is($p->nummedia(), 1, "nummedia is 1");
is($p->Media(), "Audio CD", "Media is Audio CD");
is($p->media(), "Audio CD", "media is Audio CD");
is($p->binding(), "Audio CD", "binding is Audio CD");
is($p->Binding(), "Audio CD", "Binding is Audio CD");
is($p->upc(), "093624843627", "UPC is 093624843627");
is($p->ASIN(), "B00007M84Q", "ASIN is B00007M84Q");
is($p->Asin(), "B00007M84Q", "Asin is B00007M84Q");

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
