#
# This file tests the schema used during testing
# It's a sanity check to make sure we're still testing against
# the data we think we have
#
use strict;
use warnings;  

use Test::More 1.302015;
use lib qw(t/lib);
use TDCSTest;

# evil globals
my ($schema, $artist, $cd, $track, $shop, $audiophile, $person);

$schema = TDCSTest->init_schema();

ok(defined $schema, q{schema object defined});

$artist = $schema->resultset('Artist')->find(1);
is($artist->name, q{Perlfish},
    q{Artist name is Perlfish});
is($artist->person->first_name, q{Chisel},
    q{Artist's person name is Chisel});

$artist = $schema->resultset('Artist')->find(2);
is($artist->name, q{Fall Out Code},
    q{Artist name is Fall Out Code});
is($artist->person->first_name, q{Chisel},
    q{Artist's person name is Chisel});

$artist = $schema->resultset('Artist')->find(3);
is($artist->name, q{Inside Outers},
    q{Artist name is Inside Outers});
is($artist->person->first_name, q{Chisel},
    q{Artist's person name is Chisel});

$artist = $schema->resultset('Artist')->find(4);
is($artist->name, q{Chisel},
    q{Artist name is Chisel});
is($artist->person->first_name, q{Chisel},
    q{Artist's person name is Chisel});

$cd = $schema->resultset('CD')->find(1);
is($cd->title, q{Something Smells Odd},
    q{CD title is Something Smells Odd});
is($cd->year, 1999,
    q{CD year is 1999});
is($cd->artist->name, q{Perlfish},
    q{CD artist is Perlfish});

$cd = $schema->resultset('CD')->find(2);
is($cd->title, q{Always Strict},
    q{CD title is Always Strict});
is($cd->year, 2001,
    q{CD year is 2001});
is($cd->artist->name, q{Perlfish},
    q{CD artist is Perlfish});

$cd = $schema->resultset('CD')->find(3);
is($cd->title, q{Refactored Again},
    q{CD title is Refactored Again});
is($cd->year, 2002,
    q{CD year is 2002});
is($cd->artist->name, q{Fall Out Code},
    q{CD artist is Fall Out Code});

$cd = $schema->resultset('CD')->find(4);
is($cd->title, q{Tocata in Chisel},
    q{CD title is Tocata in Chisel});
is($cd->year, 2011,
    q{CD year is 2011});
is($cd->artist->name, q{Chisel},
    q{CD artist is Chisel});


$track = $schema->resultset('Track')->find(1);
is($track->title, q{Chisel Suite (part 1)},
    q{Track title is Chisel Suite (part 1)});
is($track->position, 1,
    q{Track position is 1});
is($track->cd->title, q{Tocata in Chisel},
    q{Track CD is Tocata in Chisel});

$track = $schema->resultset('Track')->find(2);
is($track->title, q{Chisel Suite (part 2)},
    q{Track title is Chisel Suite (part 2)});
is($track->position, 2,
    q{Track position is 2});
is($track->cd->title, q{Tocata in Chisel},
    q{Track CD is Tocata in Chisel});

$track = $schema->resultset('Track')->find(3);
is($track->title, q{Chisel Suite (part 3)},
    q{Track title is Chisel Suite (part 3)});
is($track->position, 3,
    q{Track position is 3});
is($track->cd->title, q{Tocata in Chisel},
    q{Track CD is Tocata in Chisel});

$shop = $schema->resultset('Shop')->find(1);
is($shop->name, q{Potify}, q{Shop name is 'Potify'});

$shop = $schema->resultset('Shop')->find(2);
is($shop->name, q{iTunez}, q{Shop name is 'iTunez'});

$shop = $schema->resultset('Shop')->find(3);
is($shop->name, q{Media Mangler}, q{Shop name is 'Media Mangler'});

$person = $schema->resultset('Person')->find(1);
is($person->first_name, q{Chisel}, q{Person first_name is 'Chisel'});

$person = $schema->resultset('Person')->find(2);
is($person->first_name, q{Darius}, q{Person first_name is 'Darius'});

$audiophile = $schema->resultset('Audiophile')->find(1);
is($audiophile->first_name, q{Chisel}, q{Audiophile first_name (proxied) is 'Chisel'});

$audiophile = $schema->resultset('Audiophile')->find(2);
is($audiophile->first_name, q{Darius}, q{Audiophile first_name (proxied) is 'Darius'});

done_testing;
