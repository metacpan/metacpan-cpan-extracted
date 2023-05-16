#!/usr/bin/perl
# *** DO NOT USE Test2 FEATURES becuase this is a sub-script ***
use FindBin qw($Bin);
use lib $Bin;
use t_Common qw/oops mytempfile mytempdir/; # strict, warnings, Carp etc.
use t_TestCommon  # Test::More etc.
         qw/$verbose $silent $debug dprint dprintf
            bug mycheckeq_literal expect1 mycheck 
            verif_no_internals_mentioned
            insert_loc_in_evalstr verif_eval_err
            arrays_eq hash_subset
            string_to_tempfile
            @quotes/;
use t_SSUtils;

use Spreadsheet::Edit qw(:all);

my $inpath = create_testdata(
    rows => [
      [ "Rowx 0 pre-title-row with only one non-empty column" ],
      [ "A title1", "bee title", "Ctitle", "Dtitle" ],     # missing "E" cell
      [ "A title2", "bee title", "Ctitle", "Dtitle", "" ], # empty "E" cell
      [ "A title3", "Btitle",    "Ctitle", "Dtitle", "Etitle" ], # **TITLES**
      [ "A title4", "Btitle",    "Ctitle", "Dtitle", "Etitle" ], # duplicate
      [ "A title5", "Btitle",    "Ctitle", "Dtitle", ""       ],
      [ "A title6", "Btitle",    "Ctitle", "",       "Etitle" ], 
      [ "A title7", "Btitle",    "Ctitle", "Dtitle", "not e"  ],
      [ "A title8", "Btitle",    "Ctitle", "Dtitle", "Especial" ], # alternate
      [ "A title9", "Btitle",    "Ctitle", "Dtitle", ""       ],
    ],
    gen_rows => 4,  # some more data rows
);
read_spreadsheet $inpath;
say data_source() unless $silent;
die unless data_source =~ /\Q$inpath\E/;

my $s1 = new_sheet {data_source => "My ds1"};
say "s1: ",$s1->data_source unless $silent;
#read_spreadsheet {data_source => "My ds1"}, $inpath;
die unless data_source eq "My ds1";

my $s2 = Spreadsheet::Edit->new(clone => $s1);
say "s2: ",$s2->data_source unless $silent;
die unless $s2->data_source =~ /cloned from My ds1/i;

my $s3 = Spreadsheet::Edit->new(clone => $s2);
say "s3: ",$s3->data_source unless $silent;
die unless $s3->data_source =~ /cloned from cloned from My ds1/i;

{ new_sheet; my $lno=__LINE__; 
  die "data_source = <<", data_source(), ">>\n  ...does not include line number or has wrong number"
    unless data_source() =~ /created.*$lno/i; 
}

say "new_sheet: ",data_source unless $silent; 

say "Done." unless $silent;
exit 0;
