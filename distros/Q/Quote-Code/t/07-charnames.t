use warnings FATAL => 'all';
use strict;

use Test::More tests => 6;

use Quote::Code;

use if $^V lt v5.15.7, 'charnames' => qw(:full :short);

is qc"\N{U+123}", "\N{U+123}";
is qc"\N{U+1_f4_A9}", "\N{U+1_f4_A9}";

is qc"\N{EURO SIGN}", "\N{EURO SIGN}";
is qc{\N{LATIN SMALL LETTER E WITH ACUTE}\t\N{GREEK SMALL LETTER XI}\}},
   qq{\N{LATIN SMALL LETTER E WITH ACUTE}\t\N{GREEK SMALL LETTER XI}\}};

if ($^V lt v5.17.6) {
    is eval 'qc~abc \N{mTfNpY}~', eval 'qq~abc \N{mTfNpY}~';
    is eval 'qc~\N{mTfNpY}~', "\x{FFFD}";
} else {
    is eval 'qc~abc \N{mTfNpY}~', undef;
    like $@, qr/Unknown charname 'mTfNpY'/;
}
