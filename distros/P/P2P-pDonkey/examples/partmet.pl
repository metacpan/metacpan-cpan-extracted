#! /usr/bin/perl
#
# Copyright (c) 2003-2004 Alexey klimkin <klimkin at cpan.org>.
# All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#

use strict;
use P2P::pDonkey::Met ':part';

#@ARGV or @ARGV = ('23.part.met');
die "Usage: $0 <files>\n" unless @ARGV;

foreach my $f (@ARGV) {
    my $p = readPartMet($f);
    if ($p) {
        printPartMet($p);
    } else {
        print "$f is not in part.met format\n";
    }
}
