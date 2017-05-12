
use t::locale_hack;
use strict;
use Test;
use Statistics::Basic qw(:all ignore_env);
use Scalar::Util qw(refaddr);

plan tests => 8;

my $v1 = vector([1 .. 5]);
my $v2 = $v1->copy;

ok( refaddr($v1) != refaddr($v2) );
ok( $v1, $v2 );

my $cov = covariance($v1, $v2);

ok( refaddr($cov->query_vector1), refaddr($v1) );
ok( refaddr($cov->query_vector2), refaddr($v2) );
ok( $cov, 2 );

my $cor = correlation($v1, $v2);
ok( refaddr($cor->query_vector1), refaddr($v1) );
ok( refaddr($cor->query_vector2), refaddr($v2) );
ok( $cor, 1 );
