# -*- perl -*-

use Test::More tests => 1;
use Net::SMS::Mollie 0.02;

# Create the object and set some defaults
my $m = Net::SMS::Mollie->new(username => 'user', password => 'admin');

can_ok($m, 'ua');
