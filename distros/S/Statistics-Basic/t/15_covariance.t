
use t::locale_hack;
use strict;
use Test;
use Statistics::Basic;

plan tests => 8;

my $cov = new Statistics::Basic::Covariance([1 .. 3], [1 .. 3]);
my $var = new Statistics::Basic::Variance( $cov->query_vector1 );

ok( $cov->query, (2/3) );

    $cov->set_size( 4 );
ok( $cov->query, (5/4) );

    $cov->insert( 9, 9 );
ok( $cov->query, (155/16) ); # 38.75/4; 3.75 = mean (1,2,3,9); 38.75 = sum( map {(3.75-$_)**2} 1,2,3,9 )
ok( $var->query, $cov->query );

    $cov->insert( [10 .. 11], [11 .. 12] );
ok( $cov->query, (173/16) ); # 173 = 4*sum( ($m1-3)*($m2-3), ($m1-9)*($m2-9), ($m1-10)*($m2-11), ($m1-11)*($m2-12) )   

    $cov->set_vector( [10 .. 11], [11 .. 12] );
ok( $cov->query, (1/4) );

    $cov->ginsert( [13, 0], [13, 0] );
ok( $cov->query, (105/4) );


my  $j = new Statistics::Basic::Covariance;
    $j->set_vector([1 .. 3], [1 .. 3]);

ok( $j->query, (2/3) );
