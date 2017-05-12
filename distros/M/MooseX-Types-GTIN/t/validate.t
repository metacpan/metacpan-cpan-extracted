#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

use MooseX::Types::GTIN::Validate;
use MooseX::Types::GTIN qw/ GTIN ISBN10 /;

my @good_gtin = (qw/
    12312313
    829410333658
    3432423432446
    32434324234237
/);

my @bad_checksum = (qw/
    12312314
    829410333659
    3432423432447
    32434324234238
/);

my @bad_length = (qw/
    1
    boooooo
    1234567
    123456789
    123456789012345
    0.0
/);

my @empty = (0, 0.0, "0", "", undef);

foreach my $gtin (@good_gtin) {
    lives_ok { MooseX::Types::GTIN::Validate::assert_gtin($gtin); } "gtin $gtin works";
}

foreach my $gtin (@bad_checksum) {
    throws_ok { MooseX::Types::GTIN::Validate::assert_gtin($gtin); } qr/^InvalidBarcodeIncorrectCheckSum/, "gtin $gtin failed";
}

foreach my $gtin (@bad_length) {
    throws_ok { MooseX::Types::GTIN::Validate::assert_gtin($gtin); } qr/^InvalidBarcodeIncorrectNumberOfDigits/, "gtin $gtin failed";
}

foreach my $gtin (@empty) {
    throws_ok { MooseX::Types::GTIN::Validate::assert_gtin($gtin); } qr/^InvalidEmptyBarcode/, "gtin $gtin failed";
}

foreach my $gtin (@good_gtin) {
    ok is_GTIN($gtin), "$gtin validates";
}

foreach my $gtin (@bad_checksum, @bad_length, @empty) {
    ok !is_GTIN($gtin), "$gtin does not validate";
}

is(to_GTIN("043243242424"), "043243242424");
is(to_GTIN(" 043243242424 "), "043243242424");
is(to_GTIN(43243242424), "043243242424");

ok is_ISBN10("0974514055");

{
    local $TODO = "No ISBN checksum validation yet";
    ok !is_ISBN10("0974514054");
}

ok !is_ISBN10("097451405");
is(to_ISBN10("0974514055"), "0974514055");
is(to_ISBN10(" 0974514055 "), "0974514055");


is(to_GTIN("0974514055"), "9780974514055");

{
    local $TODO = "Won't coerce all the way from a dirty string to ISBN10 to a GTIN";
is(to_GTIN(" 0974514055 "), "9780974514055");
}

done_testing;
