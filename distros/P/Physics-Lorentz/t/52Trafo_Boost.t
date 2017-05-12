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


# check that the boosts along z axis are correct
my $boost_z_correct = Property {
    ##[
        v <- Float(range =>[-0.9999999999999,0.999999999999999]),
        x <- Float, y <- Float, z <- Float, t <- Float
    ]##

    my $boost = Physics::Lorentz::Transformation->boost_z( $v );
    myisa($boost, 'Physics::Lorentz::Transformation');
    pdl_approx_equiv($boost->{vector}->{pdl}, zeroes(1,4))
      or die "Boost's vector isn't null: $boost->{vector}";

    my $vec = Physics::Lorentz::Vector->new([$t,$x,$y,$z]);
    myisa($vec, 'Physics::Lorentz::Vector');

    my $res = $boost->apply($vec);
    myisa($res, 'Physics::Lorentz::Vector');

    pdl_approx_equiv( $vec->{pdl}->slice(',1:2'), $res->{pdl}->slice(',1:2') )
      or die "x and y components not unchanged under z boost: $vec becomes $res";

  # FIXME full tests for boost_z?

}, name => "check that the boosts along z axis are correct";

holds($boost_z_correct, trials => $Trials);




# check that the boosts along x axis are correct
my $boost_x_correct = Property {
    ##[
        v <- Float(range =>[-0.9999999999999,0.999999999999999]),
        x <- Float, y <- Float, z <- Float, t <- Float
    ]##

    my $boost = Physics::Lorentz::Transformation->boost_x( $v );
    myisa($boost, 'Physics::Lorentz::Transformation');
    pdl_approx_equiv($boost->{vector}->{pdl}, zeroes(1,4))
      or die "Boost's vector isn't null: $boost->{vector}";

    my $vec = Physics::Lorentz::Vector->new([$t,$x,$y,$z]);
    myisa($vec, 'Physics::Lorentz::Vector');

    my $res = $boost->apply($vec);
    myisa($res, 'Physics::Lorentz::Vector');

    pdl_approx_equiv( $vec->{pdl}->slice(',2:3'), $res->{pdl}->slice(',2:3') )
      or die "y and z components not unchanged under x boost: $vec becomes $res";

  # FIXME full tests for boost_x?

}, name => "check that the boosts along x axis are correct";

holds($boost_x_correct, trials => $Trials);


# check that the boosts along y axis are correct
my $boost_y_correct = Property {
    ##[
        v <- Float(range =>[-0.9999999999999,0.999999999999999]),
        x <- Float, y <- Float, z <- Float, t <- Float
    ]##

    my $boost = Physics::Lorentz::Transformation->boost_y( $v );
    myisa($boost, 'Physics::Lorentz::Transformation');
    pdl_approx_equiv($boost->{vector}->{pdl}, zeroes(1,4))
      or die "Boost's vector isn't null: $boost->{vector}";

    my $vec = Physics::Lorentz::Vector->new([$t,$x,$y,$z]);
    myisa($vec, 'Physics::Lorentz::Vector');

    my $res = $boost->apply($vec);
    myisa($res, 'Physics::Lorentz::Vector');

    pdl_approx_equiv( $vec->{pdl}->slice(',1:3:2'), $res->{pdl}->slice(',1:3:2') )
      or die "x and z components not unchanged under y boost: $vec becomes $res";

  # FIXME full tests for boost_y?

}, name => "check that the boosts along y axis are correct";

holds($boost_y_correct, trials => $Trials);



# Check that a boost() in y-dir is the same as boost_y()
my $boost_as_y_boost = Property {
    ##[
        v <- Float(range =>[-0.9999999999999,0.999999999999999])
    ]##

    my $boost = Physics::Lorentz::Transformation->boost( 0, $v, 0 );
    myisa($boost, 'Physics::Lorentz::Transformation');
    my $boost_dir = Physics::Lorentz::Transformation->boost_y( $v );
    myisa($boost_dir, 'Physics::Lorentz::Transformation');

    pdl_approx_equiv($boost->{vector}->{pdl}, zeroes(1,4))
      or die "Boost's vector isn't null: $boost->{vector}";

    pdl_approx_equiv($boost_dir->{vector}->{pdl}, zeroes(1,4))
      or die "Boost's vector isn't null: $boost_dir->{vector}";

    pdl_approx_equiv( $boost->{matrix}, $boost_dir->{matrix}, 1e-5 )
        or die "Boost_y and Boost(0,y,0) matrices differ: $boost_dir->{matrix} vs. $boost->{matrix}";

}, name => 'check that a boost() in y-dir is the same as boost_y()';

holds($boost_as_y_boost, trials => $Trials);

# Check that a boost() in x-dir is the same as boost_x()
my $boost_as_x_boost = Property {
    ##[
        v <- Float(range =>[-0.9999999999999,0.999999999999999])
    ]##

    my $boost = Physics::Lorentz::Transformation->boost( $v, 0, 0 );
    myisa($boost, 'Physics::Lorentz::Transformation');
    my $boost_dir = Physics::Lorentz::Transformation->boost_x( $v );
    myisa($boost_dir, 'Physics::Lorentz::Transformation');

    pdl_approx_equiv($boost->{vector}->{pdl}, zeroes(1,4))
      or die "Boost's vector isn't null: $boost->{vector}";

    pdl_approx_equiv($boost_dir->{vector}->{pdl}, zeroes(1,4))
      or die "Boost's vector isn't null: $boost_dir->{vector}";

    pdl_approx_equiv( $boost->{matrix}, $boost_dir->{matrix}, 1e-5 )
        or die "Boost_x and Boost(x,0,0) matrices differ: $boost_dir->{matrix} vs. $boost->{matrix}";

}, name => 'check that a boost() in x-dir is the same as boost_x()';

holds($boost_as_x_boost, trials => $Trials);


# Check that a boost() in z-dir is the same as boost_z()
my $boost_as_z_boost = Property {
    ##[
        v <- Float(range =>[-0.9999999999999,0.999999999999999])
    ]##

    my $boost = Physics::Lorentz::Transformation->boost( 0, 0, $v );
    myisa($boost, 'Physics::Lorentz::Transformation');
    my $boost_dir = Physics::Lorentz::Transformation->boost_z( $v );
    myisa($boost_dir, 'Physics::Lorentz::Transformation');

    pdl_approx_equiv($boost->{vector}->{pdl}, zeroes(1,4))
      or die "Boost's vector isn't null: $boost->{vector}";

    pdl_approx_equiv($boost_dir->{vector}->{pdl}, zeroes(1,4))
      or die "Boost's vector isn't null: $boost_dir->{vector}";

    pdl_approx_equiv( $boost->{matrix}, $boost_dir->{matrix}, 1e-5 )
        or die "Boost_z and Boost(0,0,z) matrices differ: $boost_dir->{matrix} vs. $boost->{matrix}";

}, name => 'check that a boost() in z-dir is the same as boost_z()';

holds($boost_as_z_boost, trials => $Trials);

# FIXME full tests for boost
