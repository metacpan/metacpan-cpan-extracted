#!perl -T
use strict;
use warnings FATAL => 'all';
use PostScript::Barcode::azteccode qw();
use PostScript::Barcode::datamatrix qw();
use Test::Exception tests => 2;

lives_ok {
    PostScript::Barcode::azteccode->new(data => '')->post_script_source_code;
} 'empty data - azteccode';
lives_ok {
    PostScript::Barcode::datamatrix->new(data => '')->post_script_source_code;
} 'empty data - datamatrix';
