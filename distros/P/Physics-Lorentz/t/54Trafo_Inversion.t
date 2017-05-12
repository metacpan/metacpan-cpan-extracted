#!perl
use strict;
use warnings;

use lib 't';
use MyTestHeader;

use Test::More tests => 7;
use Test::LectroTest::Compat
  regressions => $Regfile;


use_ok('Physics::Lorentz');

use PDL;

my $parity = Physics::Lorentz::Transformation->parity();
isa_ok($parity, 'Physics::Lorentz::Transformation');
my $ident = identity(4,4);
$ident->slice('1:3,1:3') *= -1;
ok(
    pdl_approx_equiv($parity->get_matrix(), $ident),
    'Parity is diagonal 4-matrix with -1 in space components'
);
ok(
    pdl_approx_equiv($parity->get_vector->get_pdl(), zeroes(1,4)),
    'Parity has no vector'
);

my $t = Physics::Lorentz::Transformation->time_reversal();
isa_ok($t, 'Physics::Lorentz::Transformation');
$ident = identity(4,4);
$ident->slice('0,0') *= -1;
ok(
    pdl_approx_equiv($t->get_matrix(), $ident),
    'Time reversal is a diagonal 4-matrix with -1 in time component'
);
ok(
    pdl_approx_equiv($t->get_vector->get_pdl(), zeroes(1,4)),
    'Time reversal has no vector'
);

