use strict;
use warnings;
use Test::More tests=>3;

BEGIN {
  use_ok('Proliphix');
}

my $therm = new Proliphix(ip=>'127.0.0.1', password=>'');
isa_ok($therm,'Proliphix','Module instantiated');
$therm->connect();
isa_ok($therm->ua,'LWP::UserAgent','HTTP Ability');
