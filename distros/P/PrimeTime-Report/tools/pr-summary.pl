#!/usr/bin/perl -w
use strict;
use PrimeTime::Report;

# help
# {{{
if(!defined($ARGV[0])) { $ARGV[0] = "help";}
if($ARGV[0] eq "help"){
  print <<EOF;
  Usage: 
  % $0 file_name
  
EOF
 exit;
}
# }}}
my $pt = new PrimeTime::Report;

my $file = shift;
$pt->read_file($file);
$pt->print_summary("skew","path_type", "path_group", "slack", "endpoint");
