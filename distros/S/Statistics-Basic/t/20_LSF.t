
use t::locale_hack;
use strict;
use Test;
use Statistics::Basic;

plan tests => 10;

my $lsf = new Statistics::Basic::LeastSquareFit([1 .. 10], [1 .. 10]);

ok( $lsf->query->[0], 0); # alpha
ok( $lsf->query->[1], 1); # beta
   
   $lsf->set_vector([1 .. 10], [map((3 + $_ * 4), 1 .. 10)]);

ok( $lsf->query->[0], 3); # alpha
ok( $lsf->query->[1], 4); # beta

my $j = new Statistics::Basic::LeastSquareFit;
   $j->set_vector([1 .. 10], [1 .. 10]);
ok( $j->query->[0], 0); # alpha
ok( $j->query->[1], 1); # beta

my $k = new Statistics::Basic::LeastSquareFit;
my @v = ($k->query_vector1, $k->query_vector2);

my @a = (1 .. 10);
my @b = map(13 + $_*19, 1 .. 10);
for my $i (0 .. $#a) {
    $k->ginsert($a[$i], $b[$i]);
}

ok( $k->query->[0], 13); # alpha
ok( $k->query->[1], 19); # beta

# test overloads
my ($alpha, $beta) = $j->query;
ok( "$j", qr/.*alpha.*$alpha.*beta.*$beta/ );
ok( not eval { my $test = 0+$j; 1 } );
