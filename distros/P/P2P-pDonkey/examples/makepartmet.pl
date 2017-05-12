#! /usr/bin/perl -w
#
# Copyright (c) 2003-2004 Alexey klimkin <klimkin at cpan.org>.
# All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#

use strict;
use P2P::pDonkey::Meta qw( makeFileInfo printInfo );
use P2P::pDonkey::Met qw( writePartMet );

die "Usage: $0 <files>\n" unless @ARGV;

foreach my $f (@ARGV) {
    my $i = makeFileInfo($f);
    my $p1 = packFileInfo($i);
    if (defined $i) {
        printInfo($i);
        writePartMet("$f.part.met", $i);
    }
}
