### -*- mode: perl; -*-

use Test::More;

use PDF::FDF::Simple;
use File::Temp qw( tempfile );

use Data::Dumper;
use Parse::RecDescent;
use strict;
use warnings;

plan tests => 2;

################## tests ##################


my ($fdf_fh, $fdf_fname) = tempfile (
                                     "/tmp/XXXXXX",
                                     SUFFIX => '.fdf',
                                     UNLINK => 1
                                    );

my $fdf = new PDF::FDF::Simple ({
                                 filename => $fdf_fname,
                                });
$fdf->content ({
                'name'                 => 'Blubberman',
                'organisation'         => 'Misc Stuff Ltd.',
                'dotted.field.name'    => 'Hello world.',
                'language.radio.value' => 'French',
                'my.checkbox.value'    => 'On',
                'empty_stuff'          => undef,
               });

# save undefined fields
$fdf->skip_undefined_fields (0); # is default
$fdf->save;
my $fdf2 = new PDF::FDF::Simple ({ filename => $fdf_fname });
my $erg = $fdf2->load;

ok ((defined $erg->{empty_stuff} and $erg->{empty_stuff} eq ''),
    "undef becomes empty");


# don't save undefined fields
$fdf->skip_undefined_fields (1);
$fdf->save;
$fdf2 = new PDF::FDF::Simple ({ filename => $fdf_fname });
$erg = $fdf2->load;

ok ((not defined $erg->{empty_stuff}), "skip undefined values");

