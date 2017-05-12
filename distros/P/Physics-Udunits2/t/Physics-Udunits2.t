# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Physics-Udunits2.t'

#########################

use Test::More tests => 39;
use strict;
use warnings;


BEGIN{ use_ok('Physics::Udunits2'); }

my $system = new Physics::Udunits2();
isa_ok($system, 'Physics::Udunits2::System');

my $ok = 0;
eval {
	my $noSystem = new Physics::Udunits2("xxx");
}; if ($@) {$ok = 1;}
ok($ok, 'system throws exception on wrong path');

my $mUnit = $system->getUnitByName("meter");
isa_ok($mUnit, 'Physics::Udunits2::Unit');

my $mUnit2 = $system->getUnitBySymbol("m");
isa_ok($mUnit2, 'Physics::Udunits2::Unit');

my $kmUnit = $system->getUnit("km");
isa_ok($kmUnit, 'Physics::Udunits2::Unit');

my $unit1 = $system->getDimensionlessUnit1;
isa_ok($mUnit, 'Physics::Udunits2::Unit');

my $nonsense = $system->getUnitByName("qwty");
ok(!$nonsense, 'nonsense unit undefined');

ok(! $mUnit->isConvertibleTo($unit1), "1 and m not convertible");
ok($mUnit->isConvertibleTo($kmUnit), "km and m convertible");
my $converter = $mUnit->getConverterTo($kmUnit);
isa_ok($converter, 'Physics::Udunits2::Converter');
ok(abs(1 - $converter->convert(1000)) < 1e-6, "conversion 1000m -> 1km");

my $kmUnit2 = $system->getUnit("1000 m");
isa_ok($kmUnit2, 'Physics::Udunits2::Unit');
my $converter2 = $mUnit->getConverterTo($kmUnit2);
isa_ok($converter2, 'Physics::Udunits2::Converter');
ok(abs(1 - $converter2->convert(1000)) < 1e-6, "conversion 1000m -> 1km");

# time operations

Physics::Udunits2->import(':all');
my @time = (1973, 6, 26, 9, 51, 0);
my $baseTime = encodeTime(@time);
ok(defined $baseTime, 'encodeTime');
my $baseDate = encodeDate(@time[0..2]);
ok(defined $baseDate, 'encodeDate');
my $baseClock = encodeClock(@time[3..5]);
ok(defined $baseClock, 'encodeClock');
is($baseTime, $baseDate + $baseClock, "time = date+clock");
ok(eq_array(\@time, [decodeTime($baseTime)]), 'decode = encode');

my $tUnit = $system->getUnit("minutes since 1973-06-26 00:00:00");
my $baseTimeUnit = $system->getUnitByName("second");
is (int $baseTimeUnit->getConverterTo($tUnit)->convert($baseTime), 9*60 + 51, "conversion of time");

# system operations
isa_ok($system->newBaseUnit, 'Physics::Udunits2::Unit');
isa_ok($system->newDimensionlessUnit, 'Physics::Udunits2::Unit');
ok($system->newDimensionlessUnit()->isDimensionless, 'isDimensionless');
ok($system->newBaseUnit()->sameSystem($kmUnit), 'sameSystem');

#unary unit operations
isa_ok($kmUnit->scale(1/1000), 'Physics::Udunits2::Unit');
is($kmUnit->scale(1/1000)->getConverterTo($mUnit)->convert(1), '1', '1/1000 km = m');
isa_ok($kmUnit->offset(10), 'Physics::Udunits2::Unit');
is($kmUnit->offset(10)->getConverterTo($kmUnit)->convert(1), '11', 'offset by 10');

isa_ok($kmUnit->divide($mUnit), 'Physics::Udunits2::Unit');
isa_ok($kmUnit->invert, 'Physics::Udunits2::Unit');
isa_ok($kmUnit->raise(2), 'Physics::Udunits2::Unit');
isa_ok($kmUnit->root(1), 'Physics::Udunits2::Unit');
isa_ok($kmUnit->log(10), 'Physics::Udunits2::Unit');
isa_ok($kmUnit->clone, 'Physics::Udunits2::Unit');

ok($mUnit->getName eq 'meter', 'm->getName');
ok($mUnit->getSymbol eq 'm', 'm->getSymbol');

ok($mUnit->compare($kmUnit) < 0, 'm < km');
ok($kmUnit->scale(1/1000)->compare($mUnit) == 0, 'km/1000 = m');
