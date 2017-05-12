#! /usr/bin/perl
#
# Copyright (c) 2003-2004 Alexey klimkin <klimkin at cpan.org>.
# All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#

use strict;
use Tie::IxHash;
use P2P::pDonkey::Met ':server';

my $servers;

warn "Usage: $0 <file>\n" unless @ARGV;
$ARGV[0] or $ARGV[0] = 'server.met';

my $p = readServerMet($ARGV[0]);
if ($p) {
    printServerMet($p);
#    writeServerMet('ss.met', $servers);
} else {
    print "$ARGV[0] is not in server.met format\n";
}

