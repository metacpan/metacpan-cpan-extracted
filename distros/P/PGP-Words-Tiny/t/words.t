use 5.006;
use strict;
use warnings;
use Test::More 0.96;

use PGP::Words::Tiny qw/encode_pgp decode_pgp encode_pgp_hex decode_pgp_hex/;

my $hex_input    = "e58294f2e9a227486e8b061b31cc528fd7fa3f19";
my $hex_0x_input = "0x$hex_input";
my $packed       = pack "H*", "e582";

my @words = qw(
  topmost Istanbul Pluto vagabond
  treadmill Pacific brackish dictator
  goldfish Medusa afflict bravado
  chatter revolver Dupont midsummer
  stopwatch whimsical cowbell bottomless
);

is( join( " ", encode_pgp_hex($hex_input) ), join( " ", @words ), "hex -> words" );

is(
    join( " ", encode_pgp_hex($hex_0x_input) ),
    join( " ", @words ),
    "0x hex -> words"
);

is( decode_pgp_hex(@words), $hex_0x_input, "word list -> 0x hex" );
is( decode_pgp_hex( join " ", @words ), $hex_0x_input, "word list -> 0x hex", );

is( decode_pgp( encode_pgp($packed) ), $packed, "octet round trip" );

done_testing;
#
# This file is part of PGP-Words-Tiny
#
# This software is Copyright (c) 2012 by David Golden.
#
# This is free software, licensed under:
#
#   The Apache License, Version 2.0, January 2004
#
