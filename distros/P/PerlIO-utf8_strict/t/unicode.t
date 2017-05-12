#! perl

use strict;
use warnings;
use utf8;

use Test::More 0.88;
use Test::Exception;
use lib 't/lib';
use Util qw[fh_with_octets pack_utf8 slurp];

for (my $cp = 0x00; $cp < 0x10FFFF; $cp += 0x1000) {
    my $octets = pack_utf8($cp);
    my $name   = sprintf 'successfull reading U+%.4X <%s>',
      $cp, join ' ', map { sprintf '%.2X', ord $_ } split //, $octets;

    my $fh = fh_with_octets($octets);

    lives_ok {
        slurp($fh);
    } $name;
}

done_testing;

