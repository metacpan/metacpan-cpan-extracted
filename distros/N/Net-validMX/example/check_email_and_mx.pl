#!/usr/bin/perl

use strict;
use warnings;

use Getopt::Long;
use Net::validMX;

my ($rv, $reason, $sanitized_email);
my $debug = 0;
my $verbose = 0;

GetOptions ("debug" => \$debug, "verbose" => \$verbose);

print "Check Valid MX (Net::ValidMX v".Net::validMX::version().")\n\n" if $verbose;

#RUN ME WITH EMAIL ADDRESS PARAMETERS
if (scalar(@ARGV) > 0) {
  foreach $ARGV (@ARGV) {
    if ($ARGV =~ /\@/) {
      Net::validMX::set_debug($debug);
      ($rv, $reason, $sanitized_email) = Net::validMX::check_email_and_mx($ARGV);

      print Net::validMX::get_output_result($sanitized_email, $rv, $reason) if $verbose;
      if (scalar(@ARGV) == 1) {
        exit($rv != 1);
      }
    } else {
      print "Invalid Argument: $ARGV\n";
    }
  }
} else {
  print "Error: Insufficient Number of Arguments\n\n\t$0 " . '$email_address' . "\n\n";
  exit 1;
}

1;
