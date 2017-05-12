use utf8;

use Test::More qw(no_plan);

use Net::vCard;

my $cards=Net::vCard->loadFile( "t/apple_abook_1.vcf", "t/apple_abook_utf.vcf" );

is ( scalar(@$cards), 2, "Both loaded" );

is ( $cards->[0]{'N'}{'givenName'}, "Testy", "First card reasonable");
is ( $cards->[1]{'N'}{'givenName'}, "جاي", "Second card reasonable");

