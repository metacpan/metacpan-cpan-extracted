
use t::locale_hack;
   use Statistics::Basic qw(:all);

   my $v1 = vector(1,2,3,4,5);
   my $v2 = vector($v1);
   my $sd = stddev( $v1 );
   my $v3 = $sd->query_vector;
   my $m1 = mean( $v1 );
   my $m2 = $sd->query_mean;
   my $m3 = Statistics::Basic::Mean->new( $v1 );
   my $v4 = $m3->query_vector;

   use Scalar::Util qw(refaddr);
   use Test; plan tests => 5;

   ok( refaddr($v1), refaddr($v2) );
   ok( refaddr($v2), refaddr($v3) );
   ok( refaddr($m1), refaddr($m2) );
   ok( refaddr($m2), refaddr($m3) );
   ok( refaddr($v3), refaddr($v4) );

