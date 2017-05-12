#! perl

use strict;
use warnings;
use utf8;

use Test::More 0.88;
use Test::Exception;
use lib 't/lib';
use Util qw[fh_with_octets pack_overlong_utf8 slurp];

my @tests = (
      0x00,
      0x80,
     0x800,
    0x1000,
);

foreach my $cp (@tests) {
    foreach my $sequence (pack_overlong_utf8($cp)) {
        my $name = sprintf 'reading non-shortest form representation of U+%.4X <%s> throws an exception',
          $cp, join ' ', map { sprintf '%.2X', ord $_ } split //, $sequence;

        my $fh = fh_with_octets($sequence);

        throws_ok {
            slurp($fh);
        } qr/^Can't decode ill-formed UTF-8 octet sequence/, $name;
    }
}

done_testing;

