#!perl
use strict;
use warnings;

use lib 't';
use MyTestHeader;

use Test::More tests => 6;
use Test::LectroTest::Compat
  regressions => $Regfile;


use_ok('Physics::Lorentz');

use PDL;

# check that the euler angles rotation is correct
my $prop_euler_angle_correct = Property {
    ##[
        alpha <- Float(range=>[0,2*3.14159]),
        beta <- Float(range=>[0,3.14159]),
        gamma <- Float(range=>[0,2*3.14159]),
        x1 <- Float, x2 <- Float, x3 <- Float, t <- Float
    ]##

    my $rot_abg = Physics::Lorentz::Transformation->rotation_euler(
        $alpha, $beta, $gamma
    );
    myisa($rot_abg, 'Physics::Lorentz::Transformation');
    
    my $rot_z1 = ref($rot_abg)->rotation_z( $gamma );
    myisa($rot_z1, 'Physics::Lorentz::Transformation');

    my $rot_y = ref($rot_abg)->rotation_y( $beta );
    myisa($rot_y, 'Physics::Lorentz::Transformation');
    
    my $rot_z2 = ref($rot_abg)->rotation_z( $alpha );
    myisa($rot_z2, 'Physics::Lorentz::Transformation');

    my $rot_combined = $rot_z2->merge($rot_y->merge($rot_z1));
    myisa($rot_combined, 'Physics::Lorentz::Transformation');

    my $v = Physics::Lorentz::Vector->new([$t,$x1,$x2,$x3]);
    my $v1 = $rot_abg->apply($v);
    my $v2 = $rot_combined->apply($v);
    my $x = $rot_z1->apply($v);
    $x = $rot_y->apply($x);
    $x = $rot_z2->apply($x);

    pdl_approx_equiv($rot_combined->{matrix}, $rot_abg->{matrix})
      or die "combined and euler matrices differ";
    pdl_approx_equiv($v1->{pdl}, $v2->{pdl})
      or die "combined and euler rotation results differ";
    pdl_approx_equiv($x->{pdl}, $v1->{pdl})
      or die "manual and euler rotation results differ: $x->{pdl}, $v1->{pdl}";
    1;
}, name => "check that euler angle rotation is correct";

holds($prop_euler_angle_correct, trials => $Trials);



# check that the rotation to the z axis is correct
my $rotate_to_z_correct = Property {
    ##[
        x <- Float, y <- Float, z <- Float
    ]##

    my ($rot_mat, $rot_mat_inv) =
      Physics::Lorentz::Transformation::_rotate_to_z($x, $y, $z);

    my $rot = Physics::Lorentz::Transformation->new(
        $rot_mat,
        [0,0,0,0]
    );
    my $vec = Physics::Lorentz::Vector->new([0, $x, $y, $z]);
    my $abs = sqrt( $x**2 + $y**2 + $z**2 );
    my $zv = $rot->apply($vec);
    my $nz = $zv->{pdl}/$abs;
    pdl_approx_equiv($nz, pdl([[0],[0],[0],[1]]), 1e-3)
      or die "_rotate_to_z not correct: $nz should be 0,0,0,1";
}, name => "check that the rotation to the z axis is correct";

holds($rotate_to_z_correct, trials => $Trials);


use constant PI => 3.141592653589793238462643;

# check that rotation around z axis is correct for simple cases
my $rot_z_correct = Property {
    ##[
        t <- Float, x <- Float, y <- Float, z <- Float
    ]##

    my $ident = Physics::Lorentz::Transformation->rotation_z(0);
    myisa($ident, 'Physics::Lorentz::Transformation');
    my $ident2 = Physics::Lorentz::Transformation->rotation_z(2*PI);
    myisa($ident2, 'Physics::Lorentz::Transformation');
    my $mirror = Physics::Lorentz::Transformation->rotation_z(PI);
    myisa($mirror, 'Physics::Lorentz::Transformation');

    my $vec = Physics::Lorentz::Vector->new([$t, $x, $y, $z]);
    
    my $res = $ident->apply($vec);
    myisa($res, 'Physics::Lorentz::Vector');

    pdl_approx_equiv($res->{pdl}, $vec->{pdl}, 1e-4)
      or die "Rotating by 0 around z axis does not yield original vector: $res->{pdl}, $vec->{pdl}";

    $res = $ident2->apply($vec);
    myisa($res, 'Physics::Lorentz::Vector');

    pdl_approx_equiv($res->{pdl}, $vec->{pdl}, 1e-4)
      or die "Rotating by 2*PI around z axis does not yield original vector: $res->{pdl}, $vec->{pdl}";

    $res = $mirror->apply($vec);
    myisa($res, 'Physics::Lorentz::Vector');

    my $tpdl = $vec->{pdl}->copy;
    $tpdl->slice(',1:2') *= -1;
    pdl_approx_equiv($res->{pdl}, $tpdl, 1e-4)
      or die "Rotating by PI around z axis does not yield original vector with two dimensions flipped: $res->{pdl}, $tpdl";
}, name => 'check that rotation around z axis is correct for simple cases';

holds($rot_z_correct, trials => $Trials);


# check that rotation around y axis is correct for simple cases
my $rot_y_correct = Property {
    ##[
        t <- Float, x <- Float, y <- Float, z <- Float
    ]##
    my $ident = Physics::Lorentz::Transformation->rotation_y(0);
    myisa($ident, 'Physics::Lorentz::Transformation');
    my $ident2 = Physics::Lorentz::Transformation->rotation_y(2*PI);
    myisa($ident2, 'Physics::Lorentz::Transformation');
    my $mirror = Physics::Lorentz::Transformation->rotation_y(PI);
    myisa($mirror, 'Physics::Lorentz::Transformation');


    my $vec = Physics::Lorentz::Vector->new([$t, $x, $y, $z]);
    
    my $res = $ident->apply($vec);
    myisa($res, 'Physics::Lorentz::Vector');

    pdl_approx_equiv($res->{pdl}, $vec->{pdl}, 1e-4)
      or die "Rotating by 0 around y axis does not yield original vector: $res->{pdl}, $vec->{pdl}";

    $res = $ident2->apply($vec);
    myisa($res, 'Physics::Lorentz::Vector');

    pdl_approx_equiv($res->{pdl}, $vec->{pdl}, 1e-4)
      or die "Rotating by 2*PI around y axis does not yield original vector: $res->{pdl}, $vec->{pdl}";

    $res = $mirror->apply($vec);
    myisa($res, 'Physics::Lorentz::Vector');

    my $tpdl = $vec->{pdl}->copy;
    $tpdl->slice(',1:3:2') *= -1;
    pdl_approx_equiv($res->{pdl}, $tpdl, 1e-4)
      or die "Rotating by PI around y axis does not yield original vector with two dimensions flipped: $res->{pdl}, $tpdl";
}, name => 'check that rotation around y axis is correct for simple cases';

holds($rot_y_correct, trials => $Trials);


# check that rotation around x axis is correct for simple cases
my $rot_x_correct = Property {
    ##[
        t <- Float, x <- Float, y <- Float, z <- Float
    ]##
    my $ident = Physics::Lorentz::Transformation->rotation_x(0);
    myisa($ident, 'Physics::Lorentz::Transformation');
    my $ident2 = Physics::Lorentz::Transformation->rotation_x(2*PI);
    myisa($ident2, 'Physics::Lorentz::Transformation');
    my $mirror = Physics::Lorentz::Transformation->rotation_x(PI);
    myisa($mirror, 'Physics::Lorentz::Transformation');

    my $vec = Physics::Lorentz::Vector->new([$t, $x, $y, $z]);
    
    my $res = $ident->apply($vec);
    myisa($res, 'Physics::Lorentz::Vector');

    pdl_approx_equiv($res->{pdl}, $vec->{pdl}, 1e-4)
      or die "Rotating by 0 around x axis does not yield original vector: $res->{pdl}, $vec->{pdl}";

    $res = $ident2->apply($vec);
    myisa($res, 'Physics::Lorentz::Vector');

    pdl_approx_equiv($res->{pdl}, $vec->{pdl}, 1e-4)
      or die "Rotating by 2*PI around x axis does not yield original vector: $res->{pdl}, $vec->{pdl}";

    $res = $mirror->apply($vec);
    myisa($res, 'Physics::Lorentz::Vector');

    my $tpdl = $vec->{pdl}->copy;
    $tpdl->slice(',2:3') *= -1;
    pdl_approx_equiv($res->{pdl}, $tpdl, 1e-4)
      or die "Rotating by PI around x axis does not yield original vector with two dimensions flipped: $res->{pdl}, $tpdl";
}, name => 'check that rotation around x axis is correct for simple cases';

holds($rot_x_correct, trials => $Trials);

