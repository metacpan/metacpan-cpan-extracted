#! /usr/bin/perl
#
# Copyright (c) 2003-2004 Alexey klimkin <klimkin at cpan.org>.
# All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#

use strict;
use P2P::pDonkey::Met ':known';
use P2P::pDonkey::Met_v04 ':all';

warn "Usage: $0 <file>\n" unless @ARGV;
$ARGV[0] or $ARGV[0] = 'known.met';

my $p = readKnownMet_v04($ARGV[0]);
if ($p) {
    printKnownMet($p);
} else {
    print "$ARGV[0] is not in known.met format\n";
}

