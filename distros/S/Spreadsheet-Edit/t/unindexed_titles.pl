#!/usr/bin/perl
# *** DO NOT USE Test2 FEATURES becuase this is a sub-script ***
use FindBin qw($Bin);
use lib $Bin;
use t_Common qw/oops/; # strict, warnings, Carp etc.
use t_TestCommon  # Test2::V0 etc.
         qw/$verbose $silent $debug dprint dprintf
            bug mycheckeq_literal expect1 mycheck
            verif_no_internals_mentioned
            insert_loc_in_evalstr verif_eval_err
            arrays_eq hash_subset
            @quotes/;
use t_SSUtils;


use Spreadsheet::Edit qw(:all);

##??? WHAT ABOUT $a and $b ???
for my $forbidden_varname (',', qw/^ $ " ' \\ \/ . _ 0 ( ) < > ; [ ]/, (map{ chr } 0..31), "ARGV") {
  say dvis '$forbidden_varname' if $verbose;
  state $exp_cx = 0;
  new_sheet
    rows => [
      [ ($exp_cx ? ("Other", $forbidden_varname) : ($forbidden_varname,"Other")) ],
      [ "A1", "B1" ],
      [ "A2", "B2" ],
    ]
    ;
  options debug => $debug;
  title_rx 0;
  my $got_cx = $colx{$forbidden_varname};
  die dvis 'Should not be indexed: $forbidden_varname $got_cx $exp_cx\n%colx'
    if defined $got_cx;
  my $Other_cx = $colx{Other};
  die dvis 'Other wrongly indexed: $Other_cx\n%colx'
    unless defined($Other_cx) && $Other_cx == ($exp_cx^1);
  alias foo => qr/\A\Q${forbidden_varname}\E\z/;
  $got_cx = $colx{foo};
  die dvis 'foo alias wrongly indexed: $forbidden_varname $got_cx $exp_cx\n%colx'
    unless defined($got_cx) && $got_cx == $exp_cx;
}

say "Done." unless $silent;
exit 0;
