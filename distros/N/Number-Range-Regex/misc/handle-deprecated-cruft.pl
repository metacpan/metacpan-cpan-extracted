#!perl -w
$|++;

use strict;
use warnings;

my @deprecated_pms = qw ( Number/Range/Regex/EmptyRange.pm
                          Number/Range/Regex/InfiniteRange.pm ) ;

# create empty versions of all deprecated pms to overwrite the old ones
# with in the 'make install' step
foreach my $pm (@deprecated_pms) {
  #TODO: for completeness, mkdir-p here
  open(my $fh, ">lib/$pm") || die "open $pm $!";
  print $fh map { s/^\s+//s; s/\s+$/\n/s; s/^\s+//mg; $_ } qq{
    #!perl -w
    die "'$pm' is deprecated";
    0;
  };
  close($fh);
}


## grr, the 'Right' solution requires sudo privs, but
## MakeMaker has no hooks for that point in the install process
#eval {
#  use Number::Range::Regex;
#  foreach my $pm ( @deprecated_pms ) {
#    my $file = $INC{$pm};
#    next unless $file;
#warn "pm: $pm, file: $file";
#    if(-e $file) {
#      print STDERR "trying to remove '$file'... ";
#      my $result = unlink($file) ? "ok" : "error: $!";
#      print STDERR "$result\n";
#    }
#  }
#}

