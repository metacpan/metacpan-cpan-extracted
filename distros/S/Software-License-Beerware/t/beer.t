use strict;
use warnings;
use Test::More tests => 4;

my $beer = 'Software::License::Beerware';
require_ok $beer;

my $license = $beer->new({ holder => "Drinker" });

like($license->name, qr/BEER-WARE/);
is($beer->meta_name, 'unrestricted');
is($license->holder, 'Drinker');

