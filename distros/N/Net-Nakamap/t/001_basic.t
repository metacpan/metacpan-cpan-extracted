use strict;
use warnings;

use Test::More;

use Net::Nakamap;

my $client_id     = 'this_is_client_id';
my $client_secret = 'this_is_client_secret';

my $nakamap = Net::Nakamap->new(
    client_id     => $client_id,
    client_secret => $client_secret,
);

ok $nakamap;
is $nakamap->client_id,     $client_id;
is $nakamap->client_secret, $client_secret;
isa_ok $nakamap->ua,        'LWP::UserAgent';

done_testing;
