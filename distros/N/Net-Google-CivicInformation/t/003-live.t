use strict; use warnings;
use Test::More;
use Test::Exception;

use Net::Google::CivicInformation::Representatives;

plan skip_all => 'Set $ENV{GOOGLE_API_KEY} to run live tests' unless $ENV{GOOGLE_API_KEY};

my $client = new_ok('Net::Google::CivicInformation::Representatives', [], 'obj instantiated with api key from env');



done_testing;