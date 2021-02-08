use strict; use warnings;
use Test::Most 'die';

use Net::Google::CivicInformation::Representatives;

plan skip_all => 'Set $ENV{GOOGLE_API_KEY} to run live tests' unless $ENV{GOOGLE_API_KEY};

my $client = new_ok('Net::Google::CivicInformation::Representatives', [], 'obj instantiated with api key from env');

throws_ok(
    sub { $client->representatives_for_address },
    qr/Too few arguments/,
    'Throws with no method arg provided',
);

throws_ok(
    sub { $client->representatives_for_address("") },
    qr/Must not be empty/,
    'Throws with empty string provided',
);

throws_ok(
    sub { $client->representatives_for_address( city => 'Gotham' ) },
    qr/Too many arguments/,
    'Throws with more than one arg',
);

ok( my $res = $client->representatives_for_address("Ain't gonna work"), 'Made call');
ok( ref($res) eq 'HASH',                                                'Got a hashref');
ok( $res->{error},                                                      'Error is in response' );
is( $res->{error}{code}, 400,                                           'Error code is 400' );
like( $res->{error}{message}, qr/Failed to parse address/,              'Error message is ok');

ok( my $res2 = $client->representatives_for_address('1 5th Ave NY NY'), 'Made call');
ok( ref($res2) eq 'HASH',                                               'Got a hashref');
ok( ref($res2->{officials}) eq 'ARRAY',                                 '`officials` is an arrayref`');
like( $res2->{officials}[0]{title}, qr/President of the United States/, 'First official is the pres.');

done_testing;