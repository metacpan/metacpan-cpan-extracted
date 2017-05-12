#! perl

use strict;
use warnings;
use utf8;

use Test::More 0.88;
use Test::Exception;
use lib 't/lib';
use Util qw[fh_with_octets pack_utf8 slurp];

my @NONCHARACTERS = (0xFDD0 .. 0xFDEF);
{
    for (my $i = 0; $i < 0x10FFFF; $i += 0x10000) {
        push @NONCHARACTERS, $i ^ 0xFFFE, $i ^ 0xFFFF;
    }
}

foreach my $cp (@NONCHARACTERS) {
    my $octets = pack_utf8($cp);
    my $name   = sprintf 'reading noncharacter U+%.4X <%s> throws an exception when using strict',
      $cp, join ' ', map { sprintf '%.2X', ord $_ } split //, $octets;

    my $fh  = fh_with_octets($octets);
    my $hex = sprintf '%.4X', $cp;
    throws_ok {
        slurp($fh);
    } qr/^Can't interchange noncharacter code point U\+$hex/, $name;
}

foreach my $cp (@NONCHARACTERS) {
    my $octets = pack_utf8($cp);
    my $name   = sprintf 'reading noncharacter U+%.4X <%s> succeeds when allow_noncharacters is set',
      $cp, join ' ', map { sprintf '%.2X', ord $_ } split //, $octets;

    my $fh = fh_with_octets($octets, 'allow_noncharacters');

    lives_ok {
        slurp($fh);
    } $name;
}

done_testing;

