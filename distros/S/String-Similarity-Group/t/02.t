use Test::Simple 'no_plan';
use strict;
use lib './lib';
use Cwd;
use vars qw($_part);

use String::Similarity::Group ':all';

my @a = qw/victory victorious victoria velociraptor velocirapto matrix garrot/;

_testrun(0.8, \@a,2);

_testrun(0.1, \@a,1);

_testrun(0.1, \@a,1);


my @b = (
'4marcus aureliUs',
'4marcus urelius',
'4marcus aurelius',
'4macrus aurelius',

'2lucinda jackson',
'2licindajackson',

'1urinologist',
'1eliu elucidites',
);

_testrun(0.8,\@b,2);

_testrun(1,\@b,0);


# do loners
_testrun(0.8,\@b,2,1);




exit;



sub _testrun {
   my ($min, $a, $groups_expected,$loners_instead) = @_;
   $a and defined $min or die;
   defined $groups_expected or die;

   ok_part("test $min $groups_expected");

   
   my @g = $loners_instead ? loners($min,$a) : groups( $min, $a);

   ### @g;

   if (! $groups_expected ){
      
      ok( ! (scalar @g), "no groups expected, and got none");
      return;
   }


   
   ok( @g, "got groups:");

   my $groups_count = scalar @g;
   ok( $groups_count == $groups_expected,
      "Got groups expected ?  $groups_count == $groups_expected");


   #$loners_instead and return;
   
   if ($loners_instead){ # they they are all 1
      for my $element ( @g ){         
         if ($element=~/^(\d)/){
            my $total_element_count_should_be = $1;
            ok( $total_element_count_should_be == 1 ,
               "our element count was: 1, should be: $total_element_count_should_be");
         }
      }

      return;
   }

   for my $g (@g ){
      my $element_count = scalar @$g;

      ok( ($element_count > 1),"Have more than one element '$element_count'");
      
      # are we counting ?
      for my $element(@$g){
         print STDERR "     # $element\n";

         if ($element=~/^(\d)/){
            my $total_element_count_should_be = $1;
            ok( $total_element_count_should_be == $element_count ,
               "our element count was: $element_count, should be: $total_element_count_should_be");
         }
      }

   }
}













sub ok_part {
   printf STDERR "\n\n===================\nPART %s %s\n==================\n\n",
      $_part++, "@_";
}


