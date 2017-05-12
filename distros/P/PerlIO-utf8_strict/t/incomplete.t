#! perl

use strict;
use warnings;
use utf8;

use Test::More 0.88;
use Test::Exception;
use lib 't/lib';
use Util qw[fh_with_octets pack_utf8 slurp];


for (my $cp = 0x80; $cp < 0x10FFFF; $cp += 0x1000) {
    my $sequence = substr(pack_utf8($cp), 0, -1);

    my $name = sprintf 'reading incomplete UTF-8 sequence <%s> throws an exception',
      join ' ', map { sprintf '%.2X', ord $_ } split //, $sequence;

    my $fh = fh_with_octets($sequence);

    throws_ok {
        slurp($fh);
    } qr/^Can't decode ill-formed UTF-8 octet sequence/, $name;
}

done_testing;

