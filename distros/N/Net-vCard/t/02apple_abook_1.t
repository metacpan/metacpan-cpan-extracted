
use Test::More qw(no_plan);


use Net::vCard;

my $cards=Net::vCard->loadFile( "t/apple_abook_1.vcf" );

is( scalar(@$cards), 1, "One card loaded");
my $card=$cards->[0];
is ( $card->{'N'}{'givenName'}, "Testy");
is ( $card->{'N'}{'familyName'}, "Tester");

