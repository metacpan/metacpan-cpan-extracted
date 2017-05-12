#! perl

use strict;
use warnings;
use utf8;

use Test::More 0.88;
use Test::Exception;
use lib 't/lib';
use Util qw[fh_with_octets pack_utf8 slurp];

for (my $cp = 0x0011_0000; $cp < 0x7FFF_FFFF; $cp += 0x200000) {
    my $name = sprintf 'reading encoded super codepoint U-%.8X throws an exception',
      $cp;

    my $fh = fh_with_octets(pack_utf8($cp));

    throws_ok {
        slurp($fh);
    } qr/^Can't decode ill-formed UTF-8 octet sequence/, $name;
}

done_testing;

