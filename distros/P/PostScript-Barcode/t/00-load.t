#!perl -T
use strict;
use warnings FATAL   => 'all';
use Test::More tests => 4;

BEGIN {
    for my $module (qw(
        PostScript::Barcode
        PostScript::Barcode::Meta::Types
        PostScript::Barcode::azteccode
        PostScript::Barcode::qrcode
    )) {
        use_ok($module) or BAIL_OUT("could not load $module, cannot continue");
    }
}
