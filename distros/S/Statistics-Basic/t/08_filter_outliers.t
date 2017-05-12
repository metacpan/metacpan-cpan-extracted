
use t::locale_hack;
use strict;
use Test;
use Statistics::Basic qw(:all ignore_env);

plan tests => 11;

my @a  = (((1,2,3) x 7), 15);
my @b  = (((1,2,3) x 7));
my $v1 = vector(@a);
my $v2 = vector(@b);
my $c  = computed($v1);
   $c->set_filter(sub {
       my $s = stddev($v1);
       my $m = mean($v1);

       grep { abs( $_-$m ) <= $s } @_
   });

ok( $c, $v2 );
ok( mean($c), mean($v2) );
ok( mean($c), 2 );
ok( median($c), 2 );
ok( mode($c), "[1, 2, 3]" );

$v1->set_vector([6, 47, 49, 15, 42, 41, 7, 39, 43, 40, 36]);

my $Q2 = median($v1);
my $lh = computed($v1); $lh->set_filter(sub { grep {$_<$Q2} @_ });
my $uh = computed($v1); $uh->set_filter(sub { grep {$_>$Q2} @_ });
my $Q1 = median( $lh );
my $Q3 = median( $uh );

ok( $Q1, 15 );
ok( $Q2, 40 );
ok( $Q3, 43 );

$v1->set_vector([7, 15, 36, 39, 40, 41]);

$Q2 = median( $v1 );
$Q1 = median( $lh );
$Q3 = median( $uh );

ok( $Q1, 15 );
ok( $Q2, 37.5 );
ok( $Q3, 43 );
