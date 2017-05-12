#!/usr/local/bin/perl -w

#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>#
#  pquota_user_admin.pl                    #
#                                          #
#  written by david bonner                 #
#  dbonner@cs.bu.edu                       #
#  theft is treason, citizen               #
#                                          #
#  admin script used to manage the pquota  #
#  user databases                          #
#<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<#

use Pquota;
use strict;
use vars qw ( $pquota $opt_P );

# location of pquota databases, name of default printer
sub PQUOTA_DIR { return '/usr/local/lib/pquota'; }
sub DEFAULT_PRINTER { return 'boris'; }

# get pquoa object
$pquota = Pquota->new (PQUOTA_DIR, {'UseDB' => 'NDBM_File',
                                    'Serializer' => 'Storable'});

# read command line
getopt ('P');
unless ($ARGV[0]) {
  usage();
}
if ($ARGV[0] eq 'check') {
  user_check();
}
elsif ($ARGV[0] eq 'print') {
  print_pages();
}
else {
  usage();
}

$pquota->close();
exit 0;


#>>>>>>>>>>>>>>>#
#  subroutines  #
#<<<<<<<<<<<<<<<#


##  usage message
sub usage {
  print <<__END_USAGE__;
Usage: $0 command [-P printer] [args]

$0 [-P printer] check user
        Checks to see how many pages the user can print on the printer.
        
$0 [-P printer] print user pages
        Subtracts the appropriate amount from the user's quota.
__END_USAGE__

  exit (1);
}


##  checks for the number of pages the user can print, used by the
##  printer interface scripts
sub user_check {
  my $user = $ARGV[1];
  my $printer = $opt_P || DEFAULT_PRINTER;
  my $cost = $pquota->printer_get_cost ($printer);
  my $quota = $pquota->user_get_current_by_printer ($user, $printer);

  unless ($cost && $quota) {
    print STDERR "Unable to check quota\n";
    #print "0\n";
  }
  
  print int ($quota / $cost)."\n";
}


##  adjusts the user's current quota to reflect the number of pages
##  they just printed
sub print_pages {
  my $user = $ARGV[1];
  my $pages = $ARGV[2];
  my $printer = $opt_P || DEFAULT_PRINTER;
  my $cost = $pages * $pquota->printer_get_cost ($printer);
  my $sem;
  
  unless ($pquota->user_print_pages ($user, $printer, $pages)) {
    print STDERR "Quota not deducted.\n";
    return 0;
  }
  
  return 1;
}
