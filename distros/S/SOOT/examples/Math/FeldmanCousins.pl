use strict;
use warnings;
use SOOT ':all';

# FIXME: this SEGV's somehow...

sub _FeldmanCousins {
  # Example macro of using the TFeldmanCousins class in root.
  # Author : Adrian John Bevan <bevan@SLAC.Stanford.EDU>
  # get a FeldmanCousins calculation object with the default limits
  # of calculating a 90% CL with the minimum signal value scanned 
  # = 0.0 and the maximum signal value scanned of 50.0
  
  my $f = TFeldmanCousins->new(0.9, "");

  # calculate either the upper or lower limit for 10 observerd
  # events with an estimated background of 3.  The calculation of
  # either upper or lower limit will return that limit and fill
  # data members with both the upper and lower limit for you.

  my $Nobserved   = 10.0;
  my $Nbackground = 3.0;

  my $ul = $f->CalculateUpperLimit($Nobserved, $Nbackground);
  my $ll = $f->GetLowerLimit();

  print <<VERBATIM;
For $Nobserved data observed with and estimated background
of $Nbackground candidates, the Feldman-Cousins method of
calculating confidence limits gives:
	Upper Limit = $ul
	Limit       = $ll
at the 90% CL
VERBATIM
}

_FeldmanCousins();

