# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use warnings;
use strict;

use Test::More tests => 3;
BEGIN { use_ok('Net::Amazon') };

use Net::Amazon;
use File::Spec;
#use Log::Log4perl qw(:easy);
#Log::Log4perl->easy_init($DEBUG);

my $CANNED = "canned";
$CANNED = File::Spec->catfile("t", "canned") unless -d $CANNED;
$CANNED = File::Spec->catfile("../t", "canned") unless -d $CANNED;

######################################################################
# Successful textstream fetch
######################################################################

canned("all.xml");

my $ua = Net::Amazon->new(
    associate_tag => 'YOUR_AMZN_ASSOCIATE_TAG',
    token       => 'YOUR_AMZN_TOKEN',
    secret_key  => 'YOUR_AMZN_SECRET_KEY',
);

# Response is of type Net::Amazon::Textstream::Response
my $resp = $ua->search(
    all => "perl",
);

ok($resp->is_success(), "Successful fetch");

######################################################################
# Check result
######################################################################
my @properties = $resp->properties();
my $result;

foreach (@properties) {
    $result .= $_->as_string();
}

like($result, qr/Randal Schwartz/, "single product line");

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
__END__

