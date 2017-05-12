package # Hide from PAUSE
  TArray;
use strict;
use warnings;
use vars qw/$AUTOLOAD $isROOT/;
BEGIN {$isROOT = 1}

#sub AUTOLOAD {
#  $AUTOLOAD =~ s/::([^:]+)$//;
#  my $method = $1;
#  SOOT::CallMethod($AUTOLOAD, $method, \@_);
#}

sub DESTROY () {}

1;

