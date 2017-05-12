#!/usr/bin/perl
use Test::Simple 'no_plan';
use strict;
use lib './lib';
use String::Similarity::Group ':all';
use Cwd;
use vars qw($_part $cwd);
$cwd = cwd();
use Getopt::Std::Strict 's:f:h';

$opt_h and print usage() and exit;

$opt_s ||= 0.80;
$opt_f ||= './t/listshort.txt';

sub usage {
   q{
      -h          help
      -f path     list file
      -s float    threshold
   }}



ok_part("get list..");
open(FILE,'<',$opt_f) or die;
my @elements = grep {/\w/} map { chomp ; $_  } <FILE>;
close FILE;
my $c = scalar @elements;
 $c or die;
#



my @groups = groups($opt_s, \@elements);

# MULTIPLES
GID: for my $members ( @groups ){
   
   my $count = scalar @$members;

   my $errors =0;

   if ($count > 1){
      print STDERR "\nGROUP FOUND: ($count) \n";
   }
      
   #what SHOULD the count be
   for my $element (@$members){
         $element=~/^(\d)/ or die('each element must begin with count desired');
         my $count_shouldbe =$1;
         unless( $count == $count_shouldbe ){
            warn( "element '$element', have: $count, want: $count_shouldbe\n");
            $errors++;
         }         
         
   }
   ok( ! $errors );#, "errors: $errors");
   
   if ($count > 1){
      print STDERR "\n";
   }

   
}




ok_part('SINGLES');
my @members = loners($opt_s, \@elements);
for my $element (@members){
         $element=~/^(\d)/ or die('each element must begin with count desired');
         my $count_shouldbe =$1;

         ok( $count_shouldbe == 1, 
            "element '$element', have: 1, want: $count_shouldbe");
         
      
         
   

   
}





ok_part("sim min set at $opt_s, list is $opt_f");







sub ok_part {
   printf STDERR "\n\n===================\nPART %s %s\n==================\n\n",
      $_part++, "@_";
}



