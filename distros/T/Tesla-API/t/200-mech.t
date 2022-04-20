use warnings;
use strict;
use feature 'say';

use Tesla::API;
use Test::More;

my $t = Tesla::API->new(unauthenticated => 1);

my $m = $t->mech;

is
    ref $m,
    'WWW::Mechanize',
    "mech() returns a WWW::Mechanize object ok";

done_testing();