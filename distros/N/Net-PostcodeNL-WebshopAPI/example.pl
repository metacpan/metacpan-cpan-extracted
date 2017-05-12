use lib 'lib';

use Net::PostcodeNL::WebshopAPI;
use Data::Dumper;

my $api = Net::PostcodeNL::WebshopAPI->new(
    api_key    => '',
    api_secret => '',
);

my $zipcode = '';
my $number = '';
my $addition = '';

print Dumper($api->lookup($zipcode, $number, $addition));

