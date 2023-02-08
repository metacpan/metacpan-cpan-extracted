#!/usr/bin/perl
use FindBin qw($Bin);
use lib $Bin;
use t_Setup;  # parses @ARGV and sets $debug, $verbose and $silent
use t_Utils;


use Spreadsheet::Edit qw(:all);

my $inpath = create_testdata(
    rows => [
      [ "Atitle", "bee title", "Ctitle", "Dtitle" ],     
    ],
    gen_rows => 4,  # some data rows
);
# Atitle,"bee title",Ctitle,Dtitle
# A1,B1,C1,D1
# A2,B2,C2,D2
# A3,B3,C3,D3
# A4,B4,C4,D4

our ($Balias1, $Balias2, $Xalias1, $Xalias2, $Xalias3);
tie_column_vars qw($Balias1 $Balias2 $Xalias1 $Xalias2 $Xalias3);

###TEMP
read_spreadsheet $inpath;

# Normal alias which succeeds
alias Balias1 => qr/bee title/i; # void context
die unless $colx{Balias1} == 1; 
die unless 1 == alias Balias2 => qr/bee title/i;  # cx 1
die unless $colx{Balias2} == 1; 
apply { 
  die unless $Balias1 eq "B".$rx; 
};

# Normal alias attempt fails with non-matching regex
eval { alias Xalias1 => qr/non existent/ }; verif_eval_err qr/non exist/i;
die unless $@ =~ /does not match/i;
die if exists $colx{Xalias1};
die if exists $colx_desc{Xalias1};
eval { alias {optional => 0}, Xalias2 => qr/non existent/ }; verif_eval_err qr/non exist/i;
die unless $@ =~ /does not match/i;
die if exists $colx{Xalias2};
die if exists $colx_desc{Xalias2};
apply {
  my $dummy = eval { $Xalias2."" }; verif_eval_err qr/unk.*colspec/i; # read
  eval { $Xalias2 = "foo" }; verif_eval_err qr/unk.*colspec/i; # write
};

# optional alias 
alias {optional => 1}, Xalias3 => qr/non existent/;
die unless exists $colx{Xalias3};
die "colx{Xalias3} unexpectedly defined!\n  colx: $colx{Xalias3}\n  colx_desc: $colx_desc{Xalias3}"
  if defined $colx{Xalias3};
die unless exists $colx_desc{Xalias3};
apply {
  die if defined $Xalias3; # read returns undef
  eval { $Xalias3 = "foo" }; verif_eval_err qr/optional.*alias.*not.*defined/i; # write
};

exit 0;
