#! /usr/bin/perl -w
#
# Copyright (c) 2003-2004 Alexey klimkin <klimkin at cpan.org>.
# All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#

use strict;

use P2P::pDonkey::Meta qw( makeClientInfo printInfo );
use P2P::pDonkey::Packet ':all';
use Data::Hexdumper;

my $user = makeClientInfo(0, 4662, 'Muxer', 60);
my $raw = packBody(PT_HELLO, $user);
print hexdump(data => $raw);

my ($off, $pt) = (0);
$user = unpackBody(\$pt, $raw, $off);
print "Packet type: ", PacketTagName($pt), "\n";
printInfo($user);

