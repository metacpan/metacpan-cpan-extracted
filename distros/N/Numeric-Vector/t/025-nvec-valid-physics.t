#!/usr/bin/env perl
use strict;
use warnings;
use Test2::Bundle::Numerical qw(:all);
use lib 't/lib';

use Numeric::Vector;

if (is_quadmath()) {
    diag("Testing with quadmath (128-bit precision)");
}

my $PI = 3.14159265358979323846;

# ============================================
# Geometry and Physics Integration Tests
# ============================================

subtest '2D vector operations' => sub {
    my $a = Numeric::Vector::new([3, 4]);
    my $b = Numeric::Vector::new([1, 0]);

    # Magnitude
    within_tolerance($a->norm(), 5, '|[3,4]| = 5 (3-4-5 triangle)');

    # Unit vector
    my $unit = $a->normalize();
    within_tolerance($unit->get(0), 0.6, 'unit x = 3/5');
    within_tolerance($unit->get(1), 0.8, 'unit y = 4/5');

    # Dot product for angle
    my $dot = $a->dot($b);
    within_tolerance($dot, 3, 'dot([3,4], [1,0]) = 3');
};

subtest '3D vector operations' => sub {
    my $a = Numeric::Vector::new([1, 0, 0]);
    my $b = Numeric::Vector::new([0, 1, 0]);
    my $c = Numeric::Vector::new([0, 0, 1]);

    # Orthogonal unit vectors
    within_tolerance($a->dot($b), 0, 'x dot y = 0');
    within_tolerance($b->dot($c), 0, 'y dot z = 0');
    within_tolerance($a->dot($c), 0, 'x dot z = 0');

    within_tolerance($a->norm(), 1, '|x| = 1');
    within_tolerance($b->norm(), 1, '|y| = 1');
    within_tolerance($c->norm(), 1, '|z| = 1');
};

subtest 'projectile motion simulation' => sub {
    # Initial conditions
    my $v0 = 20;       # Initial velocity (m/s)
    my $angle = $PI / 4;  # 45 degrees
    my $g = 9.81;      # Gravity

    # Time points
    my $n = 100;
    my $t_flight = 2 * $v0 * sin($angle) / $g;
    my $t = Numeric::Vector::linspace(0, $t_flight, $n);

    # x(t) = v0 * cos(theta) * t
    my $vx = $v0 * cos($angle);
    my $x = $t->scale($vx);

    # y(t) = v0 * sin(theta) * t - 0.5 * g * t^2
    my $vy = $v0 * sin($angle);
    my $y_linear = $t->scale($vy);
    my $t_sq = $t->mul($t);
    my $y_grav = $t_sq->scale(0.5 * $g);
    my $y = $y_linear->sub($y_grav);

    # Start and end at y ≈ 0
    within_tolerance($y->get(0), 0, 'starts at ground', 0.1);
    within_tolerance($y->get($n - 1), 0, 'lands at ground', 0.1);

    # Maximum height at midpoint
    my $mid = int($n / 2);
    my $max_height = $y->max();
    ok($max_height > 0, 'projectile reaches positive height');
};

subtest 'simple harmonic motion' => sub {
    # x(t) = A * cos(omega * t + phi)
    my $A = 5;        # Amplitude
    my $omega = 2;    # Angular frequency
    my $phi = 0;      # Phase

    my $n = 100;
    my $t = Numeric::Vector::linspace(0, 2 * $PI, $n);

    # Position: x = A * cos(omega*t)
    my $x = $t->scale($omega)->cos()->scale($A);

    # Velocity: v = -A*omega * sin(omega*t)
    my $v = $t->scale($omega)->sin()->scale(-$A * $omega);

    # At t=0: x = A, v = 0
    within_tolerance($x->get(0), $A, 'initial position = amplitude');
    within_tolerance($v->get(0), 0, 'initial velocity = 0', 1e-6);

    # Energy conservation: E = 0.5 * m * v^2 + 0.5 * k * x^2
    # For SHM with m=1, k=omega^2: E = 0.5 * (v^2 + omega^2 * x^2)
    my $v_sq = $v->mul($v);
    my $x_sq = $x->mul($x)->scale($omega * $omega);
    my $energy = $v_sq->add($x_sq)->scale(0.5);

    # Energy should be constant (= 0.5 * A^2 * omega^2)
    my $expected_E = 0.5 * $A * $A * $omega * $omega;
    within_tolerance($energy->mean(), $expected_E, 'average energy matches expected', 0.1);
    within_tolerance($energy->std(), 0, 'energy is constant (low variance)', 0.5);
};

subtest 'distance calculations' => sub {
    my $p1 = Numeric::Vector::new([0, 0, 0]);
    my $p2 = Numeric::Vector::new([1, 1, 1]);

    # 3D distance
    within_tolerance($p1->distance($p2), sqrt(3), 'distance to [1,1,1] = sqrt(3)');

    # Distance is symmetric
    within_tolerance($p2->distance($p1), $p1->distance($p2), 'distance is symmetric');

    # Triangle inequality: d(a,c) <= d(a,b) + d(b,c)
    my $p3 = Numeric::Vector::new([2, 0, 0]);
    my $d12 = $p1->distance($p2);
    my $d23 = $p2->distance($p3);
    my $d13 = $p1->distance($p3);
    ok($d13 <= $d12 + $d23 + 1e-10, 'triangle inequality holds');
};

subtest 'angle between vectors' => sub {
    my $a = Numeric::Vector::new([1, 0]);
    my $b = Numeric::Vector::new([0, 1]);

    # cos(theta) = (a . b) / (|a| * |b|)
    my $cos_theta = $a->cosine_similarity($b);
    my $theta = acos($cos_theta);

    within_tolerance($theta, $PI / 2, 'angle between x and y = 90°');

    # Parallel vectors
    my $c = Numeric::Vector::new([2, 0]);
    within_tolerance($a->cosine_similarity($c), 1, 'parallel vectors: cos = 1');
    within_tolerance(acos($a->cosine_similarity($c)), 0, 'parallel: angle = 0');
};

sub acos { atan2(sqrt(1 - $_[0] * $_[0]), $_[0]) }

subtest 'center of mass calculation' => sub {
    # 3 point masses
    my $masses = Numeric::Vector::new([1, 2, 3]);  # Total mass = 6

    # x-coordinates
    my $x = Numeric::Vector::new([0, 1, 2]);

    # y-coordinates
    my $y = Numeric::Vector::new([0, 0, 0]);

    # Center of mass: x_cm = sum(m_i * x_i) / sum(m_i)
    my $total_mass = $masses->sum();
    my $x_cm = $masses->dot($x) / $total_mass;

    # (1*0 + 2*1 + 3*2) / 6 = 8/6 = 4/3
    within_tolerance($x_cm, 4/3, 'center of mass x = 4/3');
};

subtest 'moment of inertia' => sub {
    # Point masses at distance r from axis
    my $masses = Numeric::Vector::new([1, 1, 1, 1]);
    my $radii = Numeric::Vector::new([1, 2, 3, 4]);

    # I = sum(m * r^2)
    my $r_squared = $radii->mul($radii);
    my $I = $masses->dot($r_squared);

    # 1 + 4 + 9 + 16 = 30
    within_tolerance($I, 30, 'moment of inertia = 30');
};

subtest 'kinetic energy distribution' => sub {
    # Particles with different velocities
    my $masses = Numeric::Vector::new([1, 2, 1, 2]);
    my $velocities = Numeric::Vector::new([1, 2, 3, 4]);

    # KE = 0.5 * m * v^2
    my $v_squared = $velocities->mul($velocities);
    my $ke = $masses->mul($v_squared)->scale(0.5);

    # [0.5*1*1, 0.5*2*4, 0.5*1*9, 0.5*2*16] = [0.5, 4, 4.5, 16]
    my $expected = Numeric::Vector::new([0.5, 4, 4.5, 16]);
    ok(vec_approx_eq($ke, $expected), 'kinetic energy distribution');

    my $total_ke = $ke->sum();
    within_tolerance($total_ke, 25, 'total KE = 25');
};

subtest 'gravity simulation (N-body)' => sub {
    # Simplified 2-body: positions and masses
    my $m1 = 1e6;
    my $m2 = 1e3;
    my $G = 6.67e-11;

    my $pos1 = Numeric::Vector::new([0, 0]);
    my $pos2 = Numeric::Vector::new([1000, 0]);

    # Distance
    my $diff = $pos2->sub($pos1);
    my $r = $diff->norm();

    # Force magnitude: F = G * m1 * m2 / r^2
    my $F = $G * $m1 * $m2 / ($r * $r);

    ok($F > 0, 'gravitational force is positive');

    # Force direction (unit vector from 1 to 2)
    my $dir = $diff->normalize();
    within_tolerance($dir->get(0), 1, 'force direction is positive x');
};

subtest 'wave interference' => sub {
    my $n = 200;
    my $x = Numeric::Vector::linspace(0, 4 * $PI, $n);

    # Two waves with slightly different frequencies
    my $wave1 = $x->sin();
    my $wave2 = $x->scale(1.1)->sin();

    # Superposition
    my $combined = $wave1->add($wave2);

    # Constructive interference: max amplitude > individual
    ok($combined->max() > $wave1->max(), 'constructive interference increases amplitude');

    # Destructive interference: min can be lower
    ok($combined->min() < $wave1->max(), 'interference creates variation');
};

subtest 'rotation matrix application' => sub {
    # 2D rotation by 90 degrees
    # R = [cos(90), -sin(90); sin(90), cos(90)] = [0, -1; 1, 0]
    my $theta = $PI / 2;
    my $cos_t = cos($theta);
    my $sin_t = sin($theta);

    # Point to rotate
    my $point = Numeric::Vector::new([1, 0]);

    # Rotated point: [x*cos - y*sin, x*sin + y*cos]
    my $x = $point->get(0);
    my $y = $point->get(1);
    my $new_x = $x * $cos_t - $y * $sin_t;
    my $new_y = $x * $sin_t + $y * $cos_t;

    within_tolerance($new_x, 0, 'rotated x ≈ 0', 1e-10);
    within_tolerance($new_y, 1, 'rotated y ≈ 1', 1e-10);
};

subtest 'spring system energy' => sub {
    # Spring constant
    my $k = 100;

    # Displacements from equilibrium
    my $x = Numeric::Vector::new([-0.5, -0.2, 0, 0.2, 0.5]);

    # Potential energy: U = 0.5 * k * x^2
    my $U = $x->mul($x)->scale(0.5 * $k);

    # U should be symmetric around 0
    within_tolerance($U->get(0), $U->get(4), 'PE symmetric for ±0.5');
    within_tolerance($U->get(1), $U->get(3), 'PE symmetric for ±0.2');
    within_tolerance($U->get(2), 0, 'PE = 0 at equilibrium');
};

subtest 'orbital mechanics - circular orbit' => sub {
    # For circular orbit: v = sqrt(G*M/r)
    my $G = 6.67e-11;
    my $M = 5.97e24;  # Earth mass
    my $r = 6.37e6 + 400e3;  # Low Earth orbit

    my $v = sqrt($G * $M / $r);

    # Period T = 2*pi*r / v
    my $T = 2 * $PI * $r / $v;

    # ISS orbital period is about 92 minutes = 5520 seconds
    ok($T > 5000 && $T < 6000, 'orbital period in reasonable range');

    # Verify using Numeric::Vector for a trajectory point
    my $theta = 0;
    my $pos = Numeric::Vector::new([$r * cos($theta), $r * sin($theta)]);
    my $vel = Numeric::Vector::new([-$v * sin($theta), $v * cos($theta)]);

    # Velocity perpendicular to position (dot product = 0)
    within_tolerance($pos->dot($vel), 0, 'velocity perpendicular to radius', $v * $r * 1e-10);
};

done_testing();
