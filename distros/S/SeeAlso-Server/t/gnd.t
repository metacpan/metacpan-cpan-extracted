#!perl -Tw

use strict;

my @valid = ('95980479X','95980479-X','040303187',
    '95980479-1','04030318-4','40160440', # SWD/GKD
    '118601121','118578537','118562347',
);
my @invalid = ("118601123","123");
my @prefixes = ("est ","PND","GND ","gkd ","swd ","pnd","http://d-nb.info/gnd/","0","000");

my $sum = (@valid + @invalid + @prefixes + 1);

use Test::More qw(no_plan);;

use SeeAlso::Identifier::GND;

my $gnd = SeeAlso::Identifier::GND->new();
is( $gnd->normalized(), "", "empty GND");
is( $gnd->value(), "", "empty GND");
ok( !$gnd->indexed() && !$gnd->valid(), "empty GND" );

foreach my $n (@valid) {
    $gnd->value( $n );
    ok( $gnd->valid, "GND '$n' tested as valid" );
    ok( $gnd->indexed, "GND '$n' indexed tested as valid" );
}

$gnd->value("040160440");
is ( $gnd->indexed, "40160440", "indexed value" );

foreach my $n (@invalid) {
    $gnd = SeeAlso::Identifier::GND->new($n);
    ok( !$gnd->valid, "GND '$n' tested as invalid" );
    is( $gnd->indexed, undef, "GND '$n' indexed tested as invalid" );
}

$gnd = SeeAlso::Identifier::GND->new("GND 118601121");

foreach my $p (@prefixes) {
    $gnd->value( $p . "118601121" );
    is( $gnd->normalized, "http://d-nb.info/gnd/118601121", "possible prefix '$p'");
    is( $gnd->canonical, "http://d-nb.info/gnd/118601121", "canonical value" );
}

