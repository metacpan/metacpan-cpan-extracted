### -*- mode: perl; -*-

use Test::More;

use PDF::FDF::Simple;
use File::Temp qw( tempfile );

use Data::Dumper;
use Parse::RecDescent;

use strict;
use warnings;

my $test_count = 2;

eval "use Test::NoWarnings";
$test_count++ unless $@;

plan tests => $test_count;

################## tests ##################


my ($fdf_fh, $fdf_fname) = tempfile (
                                     "/tmp/XXXXXX",
                                     SUFFIX => '.fdf',
                                     UNLINK => 1
                                    );

my $fdf = new PDF::FDF::Simple ({ 'filename'     => $fdf_fname });
$fdf->content ({
                'name'                 => 'Blubberman',
                'organisation'         => 'Misc Stuff Ltd.',
                'dotted.field.name'    => 'Hello world.',
                'language.radio.value' => 'French',
                'my.checkbox.value'    => 'On'
               });
ok (($fdf->save), 'save');

my $fdf2 = new PDF::FDF::Simple ({ 'filename'     => './t/simple.fdf' });

my $erg = $fdf2->load;
ok (($erg->{'oeavoba.angebotseroeffnung.anschrift'} eq 'Ländliche Neuordnung in Sachsen TG Schönwölkau I, Lüptitzer Str. 39, 04808 Wurzen'),
    "load");

