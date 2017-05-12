#!perl
use strict;
use warnings;

use lib 't';
use MyTestHeader;

use Carp qw/confess/;
use Test::More tests => 5;
use Test::LectroTest::Compat
  regressions => $Regfile;


use_ok('Physics::Lorentz');

use PDL;


# check that the constructor works
my $zero = Physics::Lorentz::Transformation->new();
isa_ok($zero, 'Physics::Lorentz::Transformation');
ok(
    all( approx($zero->{vector}{pdl}, zeroes(1,4), 1e-9) ),
    '->new returns 0,0,0,0 as vector by default'
);
ok(
    all( approx($zero->{matrix}, identity(4,4), 1e-9) ),
    '->new returns identity as matrix by default'
);

sub check_clone {
    my $t = shift;
    myisa($t, 'Physics::Lorentz::Transformation');
    my $t_c = $t->new();
    myisa($t_c, 'Physics::Lorentz::Transformation');
    my $t_c2 = $t_c->clone();
    myisa($t_c2, 'Physics::Lorentz::Transformation');

    pdl_approx_equiv($t->{vector}{pdl}, $t_c->{vector}{pdl})
      or confess "\$trafo->new doesn't clone vector";
    pdl_approx_equiv($t->{matrix}, $t_c->{matrix})
      or confess "\$trafo->new doesn't clone matrix";

    pdl_approx_equiv($t_c2->{vector}{pdl}, $t_c->{vector}{pdl})
      or confess "\$trafo->new doesn't clone vector";
    pdl_approx_equiv($t_c2->{matrix}, $t_c->{matrix})
      or confess "\$trafo->new doesn't clone matrix";
}

my $new_works = Property  {
    ##[ 
        x <- Float, y <- Float, z <- Float, t <- Float,
        d1 <- List(Float, length => 4),
        d2 <- List(Float, length => 4),
        d3 <- List(Float, length => 4),
        d4 <- List(Float, length => 4),
    ]##
    my $ary = [$t, $x, $y, $z],
    my $pdl = pdl([[$t],[$x],[$y],[$z]]);
    my $v = Physics::Lorentz::Vector->new([$t, $x, $y, $z]);
    my $mat = pdl([$d1, $d2, $d3, $d4]);

    my $tr = Physics::Lorentz::Transformation->new([$d1,$d2,$d3,$d4], $v);
    check_clone($tr);
    pdl_approx_equiv($tr->{vector}{pdl}, $v->{pdl}, 1e-6)
      or confess "Trafo->new([...], Vector) doesn't create correct vector";
    pdl_approx_equiv($tr->{matrix}, $mat, 1e-6)
      or confess "Trafo->new([...], Vector) doesn't create correct matrix";

    $tr = Physics::Lorentz::Transformation->new([$d1,$d2,$d3,$d4], $ary);
    check_clone($tr);
    pdl_approx_equiv($tr->{vector}{pdl}, $v->{pdl}, 1e-6)
      or confess "Trafo->new([...], Ary) doesn't create correct vector";
    pdl_approx_equiv($tr->{matrix}, $mat, 1e-6)
      or confess "Trafo->new([...], Ary) doesn't create correct matrix";

    $tr = Physics::Lorentz::Transformation->new([$d1,$d2,$d3,$d4], $pdl);
    check_clone($tr);
    pdl_approx_equiv($tr->{vector}{pdl}, $v->{pdl}, 1e-6)
      or confess "Trafo->new([...], PDL) doesn't create correct vector";
    pdl_approx_equiv($tr->{matrix}, $mat, 1e-6)
      or confess "Trafo->new([...], PDL) doesn't create correct matrix";

    $tr = Physics::Lorentz::Transformation->new($mat, $v);
    check_clone($tr);
    pdl_approx_equiv($tr->{vector}{pdl}, $v->{pdl}, 1e-6)
      or confess "Trafo->new(PDL, Vector) doesn't create correct vector";
    pdl_approx_equiv($tr->{matrix}, $mat, 1e-6)
      or confess "Trafo->new(PDL, Vector) doesn't create correct matrix";

    $tr = Physics::Lorentz::Transformation->new($mat, $ary);
    check_clone($tr);
    pdl_approx_equiv($tr->{vector}{pdl}, $v->{pdl}, 1e-6)
      or confess "Trafo->new(PDL, Ary) doesn't create correct vector";
    pdl_approx_equiv($tr->{matrix}, $mat, 1e-6)
      or confess "Trafo->new(PDL, Ary) doesn't create correct matrix";

    $tr = Physics::Lorentz::Transformation->new($mat, $pdl);
    check_clone($tr);
    pdl_approx_equiv($tr->{vector}{pdl}, $v->{pdl}, 1e-6)
      or confess "Trafo->new(PDL, PDL) doesn't create correct vector";
    pdl_approx_equiv($tr->{matrix}, $mat, 1e-6)
      or confess "Trafo->new(PDL, PDL) doesn't create correct matrix";

    eval {$tr = Physics::Lorentz::Transformation->new('foo', $pdl);};
    $@ or confess("Trafo->new('crap', PDL) doesn't complain");

    eval {$tr = Physics::Lorentz::Transformation->new(pdl([[1..4]]), $pdl);};
    $@ or confess("Trafo->new(bad-pdl, PDL) doesn't complain");

    eval {$tr = Physics::Lorentz::Transformation->new(pdl($mat), 'foo');};
    $@ or confess("Trafo->new([...], 'crap') doesn't complain");
}, name => 'Trafo->new(stuff) works';

holds($new_works, trials => $Trials);


