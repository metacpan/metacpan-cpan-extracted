#!perl -T
use strict;
use warnings FATAL => 'all';

use PostScript::Barcode::azteccode qw();
use Test::More tests => 1;

unlike(
    PostScript::Barcode::azteccode->new(data => 1)->post_script_source_code,
    qr/ARRAY\(0x[0-9a-f]+\)/msx,
    'unintended stringification of references',
);
