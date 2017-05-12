use Test::More;
use Test::Exception;
use Test::FailWarnings;

use Regexp::CharClasses::Helper;


sub IsA {
    return Regexp::CharClasses::Helper::fmt(
        'A',
        '+',
        "\x61",
    );
}
sub InCapitalsButNot42 {
    return Regexp::CharClasses::Helper::fmt(
        "+A\tZ",
        "-\x42"
    );
}

sub InBD {
    return Regexp::CharClasses::Helper::fmt(
        "+LATIN CAPITAL LETTER B\tD"
    );
}
sub InBDnoC {
    return Regexp::CharClasses::Helper::fmt(
        "+B\tD",
        "-C"
    );
}

like   'aA+',  qr/^\p{IsA}+$/;
unlike 'bB',   qr/\p{IsA}/;
like   'BCD',  qr/^\p{InBD}+$/;
like   'BCD',  qr/^\p{InBD}+$/;
like   'BD',   qr/^\p{InBDnoC}+$/;
unlike 'BCD',  qr/^\p{InBDnoC}+$/;
like   'ACD',  qr/^\p{InCapitalsButNot42}+$/;
unlike 'ABCD', qr/^\p{InCapitalsButNot42}+$/;


done_testing;
