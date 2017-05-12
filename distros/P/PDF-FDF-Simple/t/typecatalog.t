### -*- mode: perl; -*-

use PDF::FDF::Simple;
use Test::More;

use Parse::RecDescent;
use strict;
use warnings;

plan tests => 5;

################## tests ##################

my $fdf_fname = 't/TEST-1234.fdf';
my $fdf = new PDF::FDF::Simple ({
                                 'filename' => $fdf_fname,
                                });
my $erg = $fdf->load;

ok ((
    $erg->{'date'}      eq 'E0909'           and
    $erg->{'binding'}   eq 'Perfect'         and
    $erg->{'pages2'}    eq '100'             and
    $erg->{'spinesub3'} eq 'SpineSub-title3'
    ),
    "parse");

ok (($fdf->attribute_file eq 'file.pdf'),
    "attribute_file");

ok (($fdf->attribute_ufile eq 'file.pdf'),
    "attribute_ufile");

ok ((grep '<6D8B89AFD4447F4C31D5A7CC958E2132>', @{$fdf->attribute_id}),
    "attribute_id 1");

ok ((grep '<B2E3BAB4C29B024EB10BFB11C43DCCE1>', @{$fdf->attribute_id}),
    "attribute_id 2");

