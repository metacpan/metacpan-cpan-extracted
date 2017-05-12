use strict;
use warnings;

use Number::Phone;
use Number::Phone::FR;

use lib 't/lib';
use Numeros;

use Test::More tests =>
      (4*@Numeros::ok + 3*@Numeros::intl)
    + 2*@Numeros::intl
    + 3*@Numeros::ko
    + 2*(@Numeros::lignes * @Numeros::prefixes)
    + 9*(@Numeros::lignes_geo * @Numeros::prefixes)
    + 5*(@Numeros::network)
    + 7*(@Numeros::lignes_mobiles * @Numeros::prefixes)
    + 1;
use Test::NoWarnings;


foreach (@Numeros::ok) {
    ok(Number::Phone::FR::is_valid($_), qq'"$_" is valid');
    my $num = Number::Phone::FR->new($_);
    isa_ok($num, 'Number::Phone::FR', "'$_'");
    is($num->country, 'FR', "$_->country is 'FR'");
    is($num->country_code, 33, "$_->country_code is 33");
    # Number::Phone does support the 2-args syntax only for international format (+33...)
    next unless /^\+33/;
    $num = Number::Phone->new('FR', $_);
    isa_ok($num, 'Number::Phone::FR', "'$_'");
    is($num->country, 'FR', "$_->country is 'FR'");
    is($num->country_code, 33, "$_->country_code is 33");
}

foreach (@Numeros::intl) {
    ok(Number::Phone::FR::is_valid($_), qq'"$_" is valid');
    isa_ok(Number::Phone->new($_), 'Number::Phone::FR', $_);
}


foreach (@Numeros::ko) {
  ok( ! Number::Phone::FR::is_valid($_), qq'"$_" is invalid');
  is( Number::Phone::FR->new($_), undef, qq'"$_" can not be created with Number::Phone::FR');
  is( Number::Phone->new('FR', $_), undef, qq'"$_" can not be created with Number::Phone');
  #is( Number::Phone->new($_), undef, qq'"$_" can not be created with Number::Phone') or diag(Number::Phone->new($_)->country);
}

for my $num (@Numeros::lignes) {
    for (map { "$_$num" } @Numeros::prefixes) {
	is( Number::Phone::FR->new($_)->subscriber, $num, "subscriber($_) is $num");
	is( Number::Phone::FR->subscriber($_), $num, "subscriber($_) is $num");
    }
}

for my $num (@Numeros::lignes_geo) {
    for (map { "$_$num" } @Numeros::prefixes) {
        my $n = Number::Phone::FR->new($_);
        isa_ok( $n, Number::Phone::FR:: );
	is(                $n->subscriber, $num, "subscriber($_) is $num");
	is( Number::Phone::FR->subscriber($_), $num, "subscriber($_) is $num");
        is(                $n->is_geographic, 1, "$_ is geographic");
        is( Number::Phone::FR->is_geographic($_), 1, "$_ is geographic");
        is(                $n->is_fixed_line, 1, "$_ is fixed_line");
        is( Number::Phone::FR->is_fixed_line($_), 1, "$_ is fixed_line");
	isnt(                $n->is_mobile, 1, "$_ isn't mobile");
	isnt( Number::Phone::FR->is_mobile($_), 1, "$_ isn't mobile");
    }
}

for (@Numeros::network) {
    my $num = Number::Phone::FR->new($_);
    isa_ok( $num, Number::Phone::FR:: );
    is( $num->is_network_service, 1, "$_ is network");
    is( Number::Phone::FR->is_network_service($_), 1, "$_ is network");
    is( $num->subscriber, undef, "subscriber is undef");
    is( Number::Phone::FR->subscriber($_), undef, "subscriber is undef");
}

for my $num (@Numeros::lignes_mobiles) {
    for (map { "$_$num" } @Numeros::prefixes) {
        my $n = Number::Phone::FR->new($_);
        isa_ok( $n, Number::Phone::FR:: );
	is(                $n->is_mobile, 1, "$_ is mobile");
	is( Number::Phone::FR->is_mobile($_), 1, "$_ is mobile");
	isnt(                $n->is_geographic, 1, "$_ isn't geo");
	isnt( Number::Phone::FR->is_geographic($_), 1, "$_ isn't geo");
	isnt(                $n->is_fixed_line, 1, "$_ isn't fixed");
	isnt( Number::Phone::FR->is_fixed_line($_), 1, "$_ isn't fixed");
    }
}
