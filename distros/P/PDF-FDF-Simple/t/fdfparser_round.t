### -*- mode: perl; -*-

use Test::More;
use PDF::FDF::Simple;

use Data::Dumper;
use strict;
use warnings;

plan tests => 10;

################## tests ##################

my $readonly_testfile = './t/fdfparser_standard.fdf';
my $writeto_testfile  = './t/fdfparser_output.fdf';

#first parser reads and parses a given fdf file
#and stores a newly created fdf file with Dot-notation
my $parser = new PDF::FDF::Simple ({
                                    filename => $readonly_testfile,
                                   });
ok ($parser, "setting up 1");

my $fdf_content_ptr = $parser->load;
ok ((scalar keys %$fdf_content_ptr == 18),
    "parsing 1");

$parser->filename ($writeto_testfile);
my $successfull_save = $parser->save;
ok ($successfull_save,
    "saving 1");

#second parser parses the created fdf file
my $parser2 = new PDF::FDF::Simple ({
                                     filename => $writeto_testfile,
                                    });
ok ($parser2,
    "setting up 2");

my $new_fdf_content = $parser2->load;
ok ((scalar keys %$new_fdf_content),
    "parsing 1");

#print STDERR "1: ".(scalar keys %$new_fdf_content)."\n";
#print STDERR "2: ".(scalar keys %$fdf_content_ptr)."\n";
ok ((scalar keys %$new_fdf_content == scalar keys %$fdf_content_ptr),
    "compare size");

my $compare_success = 1;

foreach my $key (keys %$new_fdf_content) {
  if ( $new_fdf_content->{$key} ne $fdf_content_ptr->{$key} ) {
    $compare_success = 0;
    print "error\n";
    last;
  }
}
ok ($compare_success,
    "compare");

is( $parser->attribute_file,  $parser2->attribute_file,  "compare file" );
is( $parser->attribute_ufile, $parser2->attribute_ufile, "compare ufile" );

is_deeply( [ sort @{$parser->attribute_id}  ],
           [ sort @{$parser2->attribute_id} ],
           "compare ids" );


