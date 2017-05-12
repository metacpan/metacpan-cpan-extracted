#!perl -T
use strict;
use warnings FATAL => 'all';
use PostScript::Barcode::azteccode qw();
use PostScript::Barcode::qrcode qw();
use PostScript::Barcode::datamatrix qw();
use Test::Exception tests => 2;

my $first_instance = PostScript::Barcode::azteccode->new(data => '123');
lives_ok {
    my $second_instance = PostScript::Barcode::qrcode->new(data => '456');
} 'construct again in same scope';
lives_ok {
    my $third_instance = PostScript::Barcode::datamatrix->new(data => '789');
} 'construct yet again in same scope';
