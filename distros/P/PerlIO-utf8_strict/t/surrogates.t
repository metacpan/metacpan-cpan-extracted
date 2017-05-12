#! perl

use strict;
use warnings;
use utf8;

use Test::More 0.88;
use Test::Exception;
use lib 't/lib';
use Util qw[fh_with_octets pack_utf8 slurp];

my @SURROGATES = (0xD800 .. 0xDFFF);

foreach my $cp (@SURROGATES) {
    my $fh = fh_with_octets(pack_utf8($cp));

    my $name = sprintf 'reading encoded surrogate U+%.4X throws an exception when using strict', $cp;

    throws_ok {
        slurp($fh);
    } qr/^Can't decode ill-formed UTF-8 octet sequence/, $name;
}

foreach my $cp (@SURROGATES) {
    my $fh = fh_with_octets(pack_utf8($cp), 'allow_surrogates');

    my $name = sprintf 'reading encoded surrogate U+%.4X succeeds when allow_surrogates is set', $cp;

    lives_ok {
        slurp($fh);
    } $name;
}

done_testing;

