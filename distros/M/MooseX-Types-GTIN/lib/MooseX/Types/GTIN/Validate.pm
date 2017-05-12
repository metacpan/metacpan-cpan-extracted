package MooseX::Types::GTIN::Validate;
use strict;
use warnings;

sub assert_gtin {
    my ($value) = @_;

    die('InvalidEmptyBarcode')
      unless
        $value;

    # http://www.barcodeisland.com/ean13.phtml
    my $length = length($value);

    # GTIN-8, GTIN-12 (UPC), GTIN-13 (EAN) and GTIN-14 are all allowed
    if (($length >= 12 && $length <= 14) || ($length == 8)) {
        my $check_digit = substr($value, -1, 1);
        my $calc_checksum = calc_mod10_check_digit(substr($value, 0, -1));

        if ($calc_checksum ne $check_digit) {
            die('InvalidBarcodeIncorrectCheckSum');
        }
    }
    else {
        die('InvalidBarcodeIncorrectNumberOfDigits');
    }

    return($value);
}

# value is the barcode without a checkdigit
sub calc_mod10_check_digit {
    my ($value) = @_;

    my $calc_checksum = 0;

    my $mult;
    if (length($value) % 2) {
        $mult = 3;
    }
    else { # for EAN-13 the first digit is "even"
        $mult = 1;
    }

    foreach my $char (split('',$value)) {
        $calc_checksum += ($char * $mult);

        if ($mult == 1) {
            $mult = 3;
        }
        else {
            $mult = 1;
        }
    }

    # The check digit is the number which, when added to the totals calculated
    # results in a number evenly divisible by 10.
    $calc_checksum = 10 - ($calc_checksum % 10);
    $calc_checksum = 0 if ($calc_checksum == 10);

    return $calc_checksum;
}

1;
