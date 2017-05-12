### -*- mode: perl; -*-

use Test::More;
use PDF::FDF::Simple;

use Data::Dumper;
use strict;
use warnings;

plan tests => 10;

################## tests ##################

my $testfile = './t/fdfparser_newline.fdf';
my $parser = new PDF::FDF::Simple ({
                                    filename => $testfile,
                                   });

ok ($parser, "setting up");

my $fdf_content_ptr = $parser->load;

ok (($fdf_content_ptr->{'uncomment'} eq ' \ '),
    "parsing newline");
ok (($fdf_content_ptr->{'slash r'} eq 'xx'),
    "parsing slash r");
ok (($fdf_content_ptr->{'dM'} eq "x\nx"),
    "parsing dM");
ok (($fdf_content_ptr->{'newline n'} eq "xx"),
    "parsing newline n");
ok (($fdf_content_ptr->{'uncomment slash n'} eq 'x\nx'),
    "parsing uncomment slash n");
ok (($fdf_content_ptr->{'uncomment slash r'} eq 'x\rx'),
    "parsing uncomment slash r");
ok (($fdf_content_ptr->{'uncomment dM'} eq 'xx'),
    "parsing uncomment dM");
ok (($fdf_content_ptr->{'slash n'} eq "x\nx"),
    "parsing slash n");
ok (($fdf_content_ptr->{'uncomment newline n'} eq "xx"),
    "uncomment newline n");
