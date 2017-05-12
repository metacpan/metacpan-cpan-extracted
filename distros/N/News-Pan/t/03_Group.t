use Test::Simple 'no_plan';
use lib './lib';
use strict;
use warnings;
use News::Pan::Server;
use Cwd;

my $s = new News::Pan::Server({ abs_path => cwd().'/t/.pan/astraweb' });
ok($s);



for( @{$s->groups_subscribed} ){
   my $groupname = $_;
   
   my $g;
   ok( $g = $s->group($groupname), "instanced for $groupname");

   my $count;
   ok( $count = $g->subjects_count, " - counted");

   ok($count, " - count is $count");
}







