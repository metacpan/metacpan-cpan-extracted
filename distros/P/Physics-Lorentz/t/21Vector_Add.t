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


# Check addition of vectors
my $add_works = Property  {
    ##[ 
        x <- Float, y <- Float, z <- Float, t <- Float
        e <- Float, kx <- Float, ky <- Float, kz <- Float
    ]##
    # WTF? Undefined values? FIXME
    for ($x, $y, $z, $t, $e, $kx, $ky, $kz) {
        $_ = 0 if not defined $_;
    }

    my $v1 = Physics::Lorentz::Vector->new([$t, $x, $y, $z]);
    my $v2 = Physics::Lorentz::Vector->new([$e, $kx, $ky, $kz]);

    my $v12 = Physics::Lorentz::Vector->new([$t+$e,$x+$kx,$y+$ky,$z+$kz]);

    my $sum = $v1->add($v2);
    myisa($sum, 'Physics::Lorentz::Vector');
    pdl_approx_equiv($sum->get_pdl(), $v12->get_pdl(), 1e-8)
      or confess("v1->add(v2) breaks. Expected: $v12. Got: $sum.");

    $sum = $v2->add($v1);
    myisa($sum, 'Physics::Lorentz::Vector');
    pdl_approx_equiv($sum->get_pdl(), $v12->get_pdl(), 1e-8)
      or confess("v2->add(v1) breaks. Expected: $v12. Got: $sum.");
    
    $sum = $v1 + $v2;
    myisa($sum, 'Physics::Lorentz::Vector');
    pdl_approx_equiv($sum->get_pdl(), $v12->get_pdl(), 1e-8)
      or confess("v1 + v2 breaks. Expected: $v12. Got: $sum.");

    $sum = $v2 + $v1;
    myisa($sum, 'Physics::Lorentz::Vector');
    pdl_approx_equiv($sum->get_pdl(), $v12->get_pdl(), 1e-8)
      or confess("v2 + v1 breaks. Expected: $v12. Got: $sum.");

    $v1 += $v2;
    myisa($v1, 'Physics::Lorentz::Vector');
    pdl_approx_equiv($v1->get_pdl(), $v12->get_pdl(), 1e-8)
      or confess("v1 += v2 breaks. Expected: $v12. Got: $v1.");
}, name => 'Addition of vectors works';

holds($add_works, trials => $Trials);


