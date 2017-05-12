#!perl
use strict;
use warnings;

use lib 't';
use MyTestHeader;

use Carp qw/confess/;
use Test::More tests => 4;
use Test::LectroTest::Compat
  regressions => $Regfile;


use_ok('Physics::Lorentz');

use PDL;


# check that the constructor works
my $zero = Physics::Lorentz::Vector->new();
isa_ok($zero, 'Physics::Lorentz::Vector');
ok(
    all( approx($zero->{pdl}, zeroes(1,4), 1e-9) ),
    '->new returns 0,0,0,0 by default'
);

sub check_clone {
    my $v = shift;
    myisa($v, 'Physics::Lorentz::Vector');
    my $v_c = $v->new();
    myisa($v_c, 'Physics::Lorentz::Vector');
    my $v_c2 = $v_c->clone();
    myisa($v_c2, 'Physics::Lorentz::Vector');
    pdl_approx_equiv($v->{pdl}, $v_c->{pdl}) or confess "\$vector->new doesn't clone";
    pdl_approx_equiv($v_c->{pdl}, $v_c2->{pdl}) or confess "\$vector->clone doesn't clone";
}

my $new_works = Property  {
    ##[ 
        x <- Float, y <- Float, z <- Float, t <- Float
    ]##
    my $pdl = pdl([[$t],[$x],[$y],[$z]]);
    my $v = Physics::Lorentz::Vector->new([$t, $x, $y, $z]);
    check_clone($v);
    pdl_approx_equiv($v->{pdl}, $pdl) or confess "Vector->new([...]) doesn't create correct PDL";

    $v = Physics::Lorentz::Vector->new($pdl->transpose);
    check_clone($v);
    pdl_approx_equiv($v->{pdl}, $pdl) or confess "Vector->new([...]) doesn't create correct PDL";

    $v = Physics::Lorentz::Vector->new($pdl);
    check_clone($v);
    pdl_approx_equiv($v->{pdl}, $pdl) or confess "Vector->new([...]) doesn't create correct PDL";

    eval {$v = Physics::Lorentz::Vector->new('fooo')};
    $@ or die "Trying to initialize a vector with crap doesn't complain.";

    eval {$v = Physics::Lorentz::Vector->new(pdl([[[$t, $x],[$t, $y],[$t, $z]]]))};
    $@ or die "Trying to initialize a vector with a crap PDL doesn't complain.";

}, name => 'Vector->new(stuff) works';

holds($new_works, trials => $Trials);


