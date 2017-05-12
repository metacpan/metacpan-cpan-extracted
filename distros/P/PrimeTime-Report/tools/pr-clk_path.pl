#!/usr/bin/perl -w
use strict;
use PrimeTime::Report;
use Getopt::Std;
our $opt_s;
our $opt_c;
getopts("sc");

# help
# {{{
if(!defined($ARGV[0])) { $ARGV[0] = "help";}
if($ARGV[0] eq "help"){
  print <<EOF;
  Usage: 
  % $0 [option] file_name
  
  -s clock path to source flip flop.
  -c clock path to capture flip flop.
EOF
exit;
}
# }}}

my $pr = new PrimeTime::Report;

my $file = shift;
my $path_no = shift;

$pr->read_file($file);

if(defined $opt_s){
  $pr->clk_path($path_no, "source");
}elsif(defined $opt_c){
  $pr->clk_path($path_no, "capture");
}else{
  print "oo\n";
}
# vim:fdm=marker
