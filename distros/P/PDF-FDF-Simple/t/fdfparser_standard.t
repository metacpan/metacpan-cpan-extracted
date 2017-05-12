### -*- mode: perl; -*-

use Test::More;
use PDF::FDF::Simple;

use Data::Dumper;
use strict;
use warnings;

plan tests => 19;

################## tests ##################

my $testfile = './t/fdfparser_standard.fdf';
my $parser = new PDF::FDF::Simple ({
                                    filename => $testfile,
                                   });

ok ($parser, "setting up");

my $fdf_content_ptr = $parser->load;

ok (($fdf_content_ptr->{'root.data.plzort'} eq '01069'),
    "parsing file (digits)");
ok (($fdf_content_ptr->{'root.parentA.kidA_A'} eq 'valueA_A'),
    "parsing file (parent / child)");
ok (($fdf_content_ptr->{'root.data.ort'} eq 'Dresden'),
    "parsing file (characters)");
ok (($fdf_content_ptr->{'root.checkbox1'} eq 'OFF'),
    "parsing file (special values)");
ok (($fdf_content_ptr->{'root.specials.parenthesize'} eq ' (parenthesize) '),
    "parsing file (parenthesize)");
ok (($fdf_content_ptr->{'root.specials.hexa'} eq 'zuf#E4llig'),
    "parsing file (hexa, no hex decode applies)");
ok (($fdf_content_ptr->{'root.specials.hexb'} eq 'zufällig'),
    "parsing file (hexb, hex decode to literal names)");
ok (($fdf_content_ptr->{'root.parentB.kidB_B'} eq 'valueB_B'),
    "parsing file (parent / child)");
ok (($fdf_content_ptr->{'root.parentB.kidB_A'} eq 'valueB_A'),
    "parsing file (parent / child)");
ok (($fdf_content_ptr->{'root.specials.backspace'} eq ' \ '),
    "parsing file (backspaces)");
ok (($fdf_content_ptr->{'root.data.name'} eq 'some company Inc'),
    "parsing file (characters)");
ok (($fdf_content_ptr->{'root.specials.rhomb'} eq '#'),
    "parsing file (rhomb)");
ok (($fdf_content_ptr->{'root.data.'} eq ''),
    "parsing file (empty)");
ok (($fdf_content_ptr->{'root.specials.slash'} eq ' / '),
    "parsing file (slash)");
ok (($fdf_content_ptr->{'root.checkbox2'} eq 'ON'),
    "parsing file (special values)");
ok (($fdf_content_ptr->{'root.specials.spaces'} eq '  2x space at start and end  '),
    "parsing file (spaces)");
ok (($fdf_content_ptr->{'root.data.email'} eq 'info@doo.de'),
    "parsing file (special characters)");

my $keys = keys %{$fdf_content_ptr};
ok ($keys == 18, "number of key-value pairs");
