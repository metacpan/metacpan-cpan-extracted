#!perl
use strict;
use warnings FATAL => 'all';
use Capture::Tiny qw(capture);
use Image::Size qw(imgsize);
use Module::Load qw(load);
use Test::More tests => 6;

my %test_data = (
    'PostScript::Barcode::azteccode'  => {data => '123456789012345678901234567890123456789012345678901234567890', size => [62, 62],},
    'PostScript::Barcode::datamatrix' => {data => '123456789012345678901234567890123456789012345678901234567890', size => [49, 49],},
    'PostScript::Barcode::qrcode'     => {data => '123456789012345678901234567890123456789012345678901234567890', size => [67, 67],},
);

for my $module (keys %test_data) {
    load $module;
    my $barcode = $module->new(data => $test_data{$module}{data},);
    ok($barcode);
    my ($stdout) = capture {
        $barcode->render;
    };
    my @imgsize = imgsize(\$stdout);
    pop @imgsize;
    is_deeply [@imgsize], $test_data{$module}{size}, 'image size';
}
