#! /usr/bin/perl -w
#
# Copyright (c) 2003-2004 Alexey klimkin <klimkin at cpan.org>.
# All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#

use strict;
use P2P::pDonkey::Meta qw( makeFileInfoList printInfo );

die "Usage: $0 <files>\n" unless @ARGV;

my $l = makeFileInfoList(@ARGV);
foreach my $f (@$l) {
    printInfo($f);
}
