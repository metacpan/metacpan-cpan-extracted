#!perl
use strict;
use warnings;

use lib 't';
use MyTestHeader;

use Carp qw/confess/;
use Test::More tests => 2;
use Test::LectroTest::Compat
  regressions => $Regfile;


use_ok('Physics::Lorentz');

use PDL;


# check that overload_multiply works
# XXX: I know that this is not a great Generator. Sue me.
my $overload_multiply_works = Property  {
    ##[ 
        x <- Float, y <- Float, z <- Float, t <- Float,
        d1 <- List(Float, length => 4),
        d2 <- List(Float, length => 4),
        d3 <- List(Float, length => 4),
        d4 <- List(Float, length => 4),
        d5 <- List(Float, length => 4),
        d6 <- List(Float, length => 4),
        d7 <- List(Float, length => 4),
        d8 <- List(Float, length => 4),
    ]##

    my $v = Physics::Lorentz::Vector->new([$t, $x, $y, $z]);
    my $v2 = Physics::Lorentz::Vector->new([$t*5, $x*2, $y/1.3, $z**2]);
    my $tr1 = Physics::Lorentz::Transformation->new([$d1,$d2,$d3,$d4], $v);
    my $tr2 = Physics::Lorentz::Transformation->new([$d5,$d6,$d7,$d8], $v2);

    my $resv = $tr1 * $v;
    myisa($resv, 'Physics::Lorentz::Vector');

    my $vt = $tr1->{matrix} x $v->{pdl};
    $vt += $tr1->{vector}{pdl};
    pdl_approx_equiv($resv->{pdl}, $vt, 1e-5)
      or confess("tr1*vector does not result in correct vector. Expected: $vt. Got: $resv->{pdl}");

    my $tr3 = $tr1 * $tr2;
    myisa($tr3, 'Physics::Lorentz::Transformation');
    my $resm =  ($tr1->{matrix} x $tr2->{matrix});
    pdl_approx_equiv($tr3->{matrix}, $resm, 1e-5)
      or confess("tr1*tr2 does result in correct matrix. Expected: $resm. Got: $tr3->{matrix} ");
    $resv = $tr1->apply($tr2->{vector});
    pdl_approx_equiv($tr3->{matrix}, $resm, 1e-5)
      or confess("tr1*tr2 does result in correct vector. Expected: $resv. Got: $tr3->{vector} ");

    eval {$tr1 *= $v2};
    $@ or confess("tr1*=vector doesn't complain");
    eval {$tr1 *= bless{}=>'Foo'};
    $@ or confess("tr1*foo doesn't complain");

}, name => 'check that overload_multiply works';

holds($overload_multiply_works, trials => $Trials);


