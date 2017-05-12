use Test::Simple 'no_plan';
use strict;
use lib './lib';
use Cwd;
use vars qw($_part);
use String::Similarity::Group ':all';
use Smart::Comments '###';

my @a = qw/victory victorious victoria velociraptor velocirapto matrix garrot imakedamndiff house garment and the best incident that was ever conceived by man/;

my @r;


ok( 1, 'started');

my @sort = sort_by_similarity( \@a, 'victor' );
my $c = scalar @sort;
ok( $c, "got $c results") or exit;

### @sort

ok( scalar @sort == scalar @a,'since no threshold is defined.. we get same result count back');


for my $v( qw/0.2 0.4 0.8 0.9/){
   ok_part("threshold $v");
   my @sorted_with_threshold  = sort_by_similarity( \@a, 'victor', $v );
   my $c = scalar @sorted_with_threshold;
   ok($c,"got count of results");

   ### @sorted_with_threshold
}



sub ok_part {
   printf STDERR "\n\n===================\nPART %s %s\n==================\n\n",
      $_part++, "@_";
}


