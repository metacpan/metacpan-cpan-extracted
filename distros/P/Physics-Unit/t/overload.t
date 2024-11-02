use strict;
use Physics::Unit::Scalar qw(GetScalar);
use Test::More tests => 40;

my $d1 = new Physics::Unit::Distance('10 meters');
ok(defined $d1, "new Physics::Unit::Distance('10 meters')");
is(ref($d1), 'Physics::Unit::Distance', '$d1 is distance type');

my $d2 = new Physics::Unit::Distance('2 meters');
ok(defined $d2, "new Physics::Unit::Distance('2 meters')");
is(ref($d2), 'Physics::Unit::Distance', '$d2 is distance type');

my $d3 = new Physics::Unit::Distance('5 meters');
ok(defined $d3, "new Physics::Unit::Distance('5 meters')");
is(ref($d3), 'Physics::Unit::Distance', '$d3 is distance type');

my $d12p = $d1 + $d2;
ok(defined $d12p, "defined \$d12p = \$d1 + \$d2 (overloaded '+')");
is($d12p, '12 meter', "\$d12p eq '12 meter' (overloaded 'eq')");
ok($d12p > $d3, "\$d12p > \$d3 (overloaded <=>)");

$d12p++;
ok(defined $d12p, "defined \$d12p++ (overloaded '+')");
ok($d12p == 13, "\$d12p == 13 (overloaded <=>)");

my $d31m = $d3 - $d1;
ok(defined $d31m, "defined \$d31m = \$d3 - \$d1 (overloaded '-')");
is($d31m, '-5 meter', "\$d31m eq '-5 meter' (overloaded 'eq')");
ok($d31m == -5, "\$d31m == -5 (overloaded <=>)");

my $d32m = 3 - $d2;
ok(defined $d32m, "defined \$d32m = 3 - \$d2 (overloaded '-')");
is($d32m, '1 meter', "\$d32m eq '1 meter' (overloaded 'eq')");
ok($d32m == 1, "\$d32m == 1 (overloaded <=>)");

my @sorted = sort { $a <=> $b } ($d1, $d2, $d3, $d12p, $d31m, $d32m);
ok($sorted[0] eq '-5 meter', "sorting with <=>; first entry is '-5 meter'");
ok($sorted[-1] eq '13 meter', "sorting with <=>; last entry is '13 meter'");

my $d32mc = $d32m**3;
ok(defined $d32mc, "defined \$d32m**3 (overloaded **)");
is($d32mc, '1000 liter', "\$d32mc eq '1000 liter' (overloaded 'eq')");
ok($d32mc ne '1001 liter', "\$d32mc ne '1001 liter' (overloaded 'ne')");

$d32mc /= $d2**2;
ok(defined $d32mc, "defined \$d32m /= \$d2**2 (overloaded / and **)");
is($d32mc, '0.25 meter', "\$d32mc eq '0.25 meter' (overloaded 'eq')");

my $angle1 = GetScalar("90 degrees");
ok(defined $angle1, "defined \$angle1 = 90 degrees");
is(ref($angle1), 'Physics::Unit::Dimensionless', '$angle1 is without dimension');
my $sin_test = sprintf("%.1f", sin($angle1));
is($sin_test, "1.0", "sin(\$angle1) = 1 (overloaded 'sin')");
my $cos_test = sprintf("%.1f", cos($angle1));
is($cos_test, "0.0", "cos(\$angle1) = 0 (overloaded 'cos')");

my $t1 = GetScalar('-300 seconds');
ok(defined $t1, "GetScalar('-300 seconds')");
is(ref($t1), 'Physics::Unit::Time', '$t1 is time type');
my $at1 = abs($t1);
is($at1, '300 second', "abs(\$t1) eq '300 seconds' (overloaded 'abs')");

my $t2 = GetScalar('31.653891 seconds');
ok(defined $t2, "GetScalar('31.653891 seconds')");
is(ref($t2), 'Physics::Unit::Time', '$t2 is time type');
my $it2 = int($t2);
is($it2, '31 second', "int(\$t2) eq '31 second' (overloaded 'int')");

my $angle2 = GetScalar('45 degrees');
ok(defined $angle2, "GetScalar('45 degrees')");
my $angle2_rounded = sprintf("%.11f", $angle2);

my $d4 = GetScalar("2 meters");
my $d5 = GetScalar("2 meters");
my $theta1 = atan2($d4, $d5);
my $theta1_rounded = sprintf("%.11f", $theta1);
ok($angle2_rounded == $theta1_rounded, "Checking output of overloaded atan2(2 meters, 2 meters) is equal to 45 degrees to 11 dp");

my $theta2 = atan2(2, $d5); 
my $theta2_rounded = sprintf("%.11f", $theta2);
ok($angle2_rounded == $theta2_rounded, "Checking output of overloaded atan2(2, 2 meters) is equal to 45 degrees to 11 dp");

my $theta3 = atan2($d4, 2);
my $theta3_rounded = sprintf("%.11f", $theta3);
ok($angle2_rounded == $theta3_rounded, "Checking output of overloaded atan2(2 meters, 2) is equal to 45 degrees to 11 dp");

ok(sprintf("%.11f", exp($d1/$d3)) == 7.38905609893, "Checking output of overloaded exp(10 meter/5 meter) to 11 dp");
ok(sprintf("%.11f", log($d1/$d3)) == 0.69314718056, "Checking output of overloaded log(10 meter/5 meter) to 11 dp");


