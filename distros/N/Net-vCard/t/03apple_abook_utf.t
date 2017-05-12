use utf8;

use Test::More qw(no_plan);


use Net::vCard;

my $cards=Net::vCard->loadFile( "t/apple_abook_utf.vcf" );

is( scalar(@$cards), 1, "One card loaded");
my $card=$cards->[0];

is ( $card->{'N'}{'givenName'}, "جاي");
is ( $card->{'N'}{'familyName'}, "لاورينس");

use Data::Dumper;
# print Dumper $cards;
