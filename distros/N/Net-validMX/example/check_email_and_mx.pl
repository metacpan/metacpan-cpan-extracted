#!/usr/bin/perl

use strict;
use Net::validMX;

my ($rv, $reason, $sanitized_email);

print "Check Valid MX (Net::ValidMX v".&Net::validMX::version().")\n\n";

#RUN ME WITH EMAIL ADDRESS PARAMETERS
if (scalar(@ARGV) > 0) {
  foreach $ARGV (@ARGV) {
    if ($ARGV =~ /\@/) {
      ($rv, $reason, $sanitized_email) = &Net::validMX::check_email_and_mx($ARGV);

      print &Net::validMX::get_output_result($sanitized_email, $rv, $reason);
      if (scalar(@ARGV) == 1) {
        exit($rv != 1);
      }
    } else {
      print "Invalid Argument: $ARGV\n";
    }
  }
} else {
  print "Error: Insufficient Number of Arguments\n\n\tperl check_email_and_mx.pl kevin.mcgrail\@thoughtworthy.com\n\n";
} 

exit;
