#!/usr/bin/perl -w
use strict;
use PrimeTime::Report;
use Getopt::Std;
our $opt_l;
getopts("l:");

# help
# {{{
if(!defined($ARGV[0])) { $ARGV[0] = "help";}
if($ARGV[0] eq "help"){
  print <<EOF;
  Usage: 
  % pr-path.pl file_name path_number [raw]
  
  The `raw' option make pr-path.pl output a raw path for you.
EOF
 exit;
}
# }}}

my $pt = new PrimeTime::Report;

my $file = shift;
my $path_number = shift;
my $raw = shift;
if(defined($raw)){
  chomp($raw);
}else{
  $raw = "kk";
}

$pt->read_file($file);

if ($raw eq "raw") {
  $pt->print_path_raw($path_number,$opt_l);
  print "\n";
}else{
  $pt->print_path($path_number,$opt_l);
}

# vim:fdm=marker
