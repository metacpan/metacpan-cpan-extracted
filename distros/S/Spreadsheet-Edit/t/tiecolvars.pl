#!/usr/bin/perl
use FindBin qw($Bin);
use lib $Bin;
use t_Setup;  # parses @ARGV and sets $debug, $verbose and $silent
use t_Utils;

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
  read_spreadsheet $inpath;
  # title_rx 0;
  tie_column_vars qw(:all :safe FutureB FutureC);

  insert_cols '>$', "Ctitle", "Dtitle";
  apply {
    $crow[-2] = "C$rx";
    $crow[-1] = "D$rx";
  }

  tie_column_vars qw(FutureD Future4);

  # The :safe option should cause a croak before tying it,
  # here inside BEGIN{}
  our $Myvar;
  eval { insert_cols '>$', "Myvar"; } && die;
  die "WRONG ERR:$@" unless $@ =~ /Myvar.*clashes/;
}

# BUT outside BEGIN{} we just get a warning and the variable is not
# tied, although the COLSPEC is otherwise usable.
our $Myvar2;
insert_cols '>$', "Myvar2";
die unless $rows[$title_rx]{Myvar2} eq "Myvar2";
die if defined($Myvar2);
$Myvar2 = "random"; # would croak outside of apply if this was tied
die unless $Myvar2 eq "random";
delete_cols "Myvar2";

our $Atitle;

# Declare a variable which should not be tied
our $Etitle = "non-tied Etitle value";

insert_cols '>$', "Etitle", "Ftitle"; 
our $Ftitle;
tie_column_vars 'Ftitle';
die unless $rows[$title_rx]{Ftitle} eq "Ftitle";

apply {
  $crow[-2] = "E$rx";
  $crow[-1] = "F$rx";
};

my $s = sheet;

my $count = 0;
apply {
  $count++;
  die unless $Atitle eq "A$rx";
  die unless $Btitle eq "B$rx";
  die unless $Ctitle eq "C$rx";
  die unless $Dtitle eq "D$rx";

  die unless $Etitle eq "non-tied Etitle value";
};
die unless $count == 3;

alias FutureB => "B";
alias FutureC => 2;
alias FutureD => qr/dtit/i;

$count = 0;
apply {
  $count++;
  die unless $FutureB eq "B$rx";
  die unless $FutureC eq "C$rx";
  die unless $FutureD eq "D$rx";
  
  eval{ my $dum = $Future4; } && die; die unless $@ =~ /Future4.*unknown/;

  die unless $Atitle eq "A$rx";
  die unless $Btitle eq "B$rx";
  die unless $Ctitle eq "C$rx";
  die unless $Dtitle eq "D$rx";
};
die unless $count == 3;

eval{ my $dum = $Future4; } && die; die unless $@ =~ /not.*during.*apply/i;

say "Ok." unless $silent;
exit 0;
