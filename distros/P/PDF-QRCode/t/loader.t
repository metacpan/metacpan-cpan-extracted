#!/usr/bin/perl
use FindBin;
use lib $FindBin::Bin.'/../3rd/lib/perl5';
use lib $FindBin::Bin.'/../lib';

use Test::More tests => 1;
my $warn;

eval {
    require PDF::QRCode;
};

like $@,qr/PDF::QRCode not loaded/;