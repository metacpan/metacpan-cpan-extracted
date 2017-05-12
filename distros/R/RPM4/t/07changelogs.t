#!/usr/bin/perl
# $Id$

use strict;
use Test::More tests => 1;
use FindBin qw($Bin);
use RPM4;
use RPM4::Header::Changelogs;

my $htest = RPM4::Header->new("$Bin/test-rpm-1.0-1mdk.noarch.rpm");

my $ch = RPM4::Header::Changelogs->new($htest);

isa_ok(
    $ch,
    'RPM4::Header::Changelogs',
    'Get changelogs object'
);

