#!/usr/bin/perl
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

BEGIN {
  my $inpath = create_testdata(
      rows => [
        [ "Atitle", "Btitle" ],
        [ "A1",     "B1"     ],
        [ "A2",     "B2"     ],
        [ "A3",     "B3"     ],
      ]
  );

  #new_sheet;
  options debug => $debug;
  read_spreadsheet $inpath;
  # title row is now auto-detected
  # title_rx 0;

## Pointless option :safe has been removed
##tie_column_vars qw(:all :safe FutureB FutureC);
  tie_column_vars qw(:all FutureB FutureC);

  insert_cols '>$', "Ctitle", "Dtitle";
  apply {
    $crow[-2] = "C$rx";
    $crow[-1] = "D$rx";
  };

  tie_column_vars qw(FutureD Future4);

  { our $FutureD; apply_torx{ eval{ my $x = $FutureD; }; verif_eval_err(qr/FutureD.*unk.*COLSPEC/); } 1; }
  { our $FutureD; apply_torx{ eval{ my $x = $FutureD; }; verif_eval_err(qr/FutureD.*unk.*COLSPEC/); } 1; }
  { our $Future4; apply_torx{ eval{ my $x = $Future4; }; verif_eval_err(qr/Future4.*unk.*COLSPEC/); } 1; }

##  # The :safe option should cause a croak before tying it,
##  # here inside BEGIN{}
##  our $Myvar;
##  eval { my $dummy = insert_cols '>$', "Myvar"; } && die;
##  die "WRONG ERR:$@" unless $@ =~ /Myvar.*clashes/;
}

### BUT outside BEGIN{} we just get a warning and the variable is not
### tied, although the COLSPEC is otherwise usable.
##{ our $Myvar2;
##  my @caught;
##  { local $SIG{__WARN__} = sub{ push @caught, join("",@_); };
##    insert_cols '>$', "Myvar2";
##  }
##  die "Did not get expected not-tied warning (got:@caught)"
##    unless grep /Not tieing new variable.*because.*:safe/i, @caught;
##  die unless $rows[$title_rx]{Myvar2} eq "Myvar2";
##  die if defined($Myvar2);
##  $Myvar2 = "random"; # would croak outside of apply if this was tied
##  die unless $Myvar2 eq "random";
##  die unless $rows[$title_rx]{Myvar2} eq "Myvar2";
##  delete_cols "Myvar2";
##}

our $Atitle;
our $FutureD;

### Declare a variable which should not be tied
##our $Etitle = "non-tied Etitle value";
our $Etitle;

bug if defined $Etitle;
bug if defined $colx{Etitle};
$Etitle = "*should never see this*";

# tie_col_vars :all was used so Etitle and Ftitle should be auto-tied
insert_cols '>$', "Etitle", "Ftitle";
our $Ftitle;
die unless $rows[$title_rx]{Ftitle} eq "Ftitle";

apply {
  $crow[-2] = "E$rx";
  $crow[-1] = "F$rx";
};

bug unless $colx{Etitle} == 4;
apply_torx{ bug unless $Etitle eq "E2" } 2;

my $s = sheet;

my $count = 0;
apply {
  $count++;
  die unless $Atitle eq "A$rx";
  die unless $Btitle eq "B$rx";
  die unless $Ctitle eq "C$rx";
  die unless $Dtitle eq "D$rx";
  die unless $Etitle eq "E$rx";
  die unless $Ftitle eq "F$rx";
};
die unless $count == 3;

apply_torx{ eval{ my $x = $FutureD; }; verif_eval_err(qr/FutureD.*unk.*COLSPEC/); } 1;

alias FutureB => "B";
alias FutureC => 2;
alias FutureD => qr/dtitle/i;

$count = 0;
apply {
  $count++;
  die unless $FutureB eq "B$rx";
  die unless $FutureC eq "C$rx";
  die unless $FutureD eq "D$rx";

  eval{ my $x = $Future4; }; verif_eval_err(qr/Future4.*unk.*COLSPEC/);

  die unless $Atitle eq "A$rx";
  die unless $Btitle eq "B$rx";
  die unless $Ctitle eq "C$rx";
  die unless $Dtitle eq "D$rx";
  die unless $FutureD eq "D$rx";
};
die unless $count == 3;

eval{ my $dum = $Future4; } && die; die unless $@ =~ /not.*during.*apply/i;

say "Done." unless $silent;
exit 0;
