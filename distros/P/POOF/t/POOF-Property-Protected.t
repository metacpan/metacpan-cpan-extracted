# perl -T
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl POOF.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 13;
BEGIN { use_ok('POOF::Example::Vehicle::Automobile::NissanXterra') };
BEGIN { use_ok('POOF::Example::Vehicle::Bicycle::BMX') };
BEGIN { use_ok('POOF::Example::Key') };
BEGIN { use_ok('POOF::Example::Engine') };
#########################

$POOF::TRACE = 0;

my $car = POOF::Example::Vehicle::Automobile::NissanXterra->new;
my $key = POOF::Example::Key->new;
my $engine = POOF::Example::Engine->new;

#my $b = POOF::Example::Vehicle::Bicycle::BMX->new;

my $car_pp_e = [ qw(Wheels Trim Color VIN) ];
my $car_pp_r = [ keys %{$car} ];

is_deeply($car_pp_r, $car_pp_e, 'public property test');

is(
    $car->{'Color'}, 'White',
    'Testing that the default value of Color is "White"');

$car->{'Color'} = 'Black';

is(
    $car->{'Color'}, 'Black',
    'Changing Color to "Black"');

is(
   $car->StartEngine, 0,
   'Calling method StartEngine without the $key parameter.');

is(
   $car->StartEngine($key), 1,
   'Calling method StartEngine with a valid $key parameter.');

is(
   $car->StopEngine, 0,
   'Calling method StopEngine without the $key parameter.');

is(
   $car->StopEngine($key), 1,
   'Calling method StopEngine with a valid $key parameter.');

eval
{
    $engine->validKey;
};

is(
   defined $@, 1,
   'Calling private method validKey outside of private context.');

my $car2 = POOF::Example::Vehicle::Automobile::NissanXterra->new;

$car2->{'Color'} = 'Pink';
$car->{'Color'} = 'Blue';

isnt(
    $car2->{'Color'},$car->{'Color'},
    'Testing that two instances of the same class are really separate.');

exit;

