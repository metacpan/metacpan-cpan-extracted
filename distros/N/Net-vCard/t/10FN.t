
use Test::More qw(no_plan);

use Net::vCard;

my $cards=Net::vCard->loadFile( "t/apple_abook_1.vcf" );

$card=$cards->[0];
is ( $card->{'FN'}{'val'}, "Testy Tester");
is ( $card->FN, "Testy Tester");

