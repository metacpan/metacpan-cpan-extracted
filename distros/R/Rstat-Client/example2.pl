#!/usr/bin/perl -w
#
# $Id: //eai/perl5/Rstat-Client/2.2/src/distro/example2.pl#2 $

# Copyright (c) 2008, Morgan Stanley & Co. Incorporated
# Please see the copyright notice in Client.pm for more information.

use Data::Dumper;
use ExtUtils::testlib;
use Rstat::Client;

my $clnt  = Rstat::Client->new();
my $stats = $clnt->fetch();
print Dumper($stats);

