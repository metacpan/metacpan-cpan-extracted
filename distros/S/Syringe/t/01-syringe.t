use Modern::Perl;
use Test::More;
use Test::Moose;
use Test::Exception;
use Data::Dumper;
use Cwd 'abs_path';
use File::Spec;
use FindBin qw($Bin);

use lib "$Bin/lib";

my $abs_path = abs_path($0);

my ( $volume, $directories, $file ) = File::Spec->splitpath($abs_path);

my $test_yaml_path = File::Spec->catfile( $directories, 'syringe.yml' );
my $log4perl_conf  = File::Spec->catfile( $directories, 'log4perl.conf' );

ok( -f $test_yaml_path, "test yaml file [ $test_yaml_path ] exists!" );

use_ok('Syringe');

my $container = Syringe->instance( path => $test_yaml_path, log4perlconf => $log4perl_conf );

cmp_ok( $container->get_class('StockCar'), 'eq', 'RA::UnitTest::Car', 'get_class' );

my $car = $container->get_service('StockCar');

# try to register service with non blessed object
throws_ok { $container->register_service('DuplicateCar', [qw(foo bar baz)]) }
    qr/You must pass a blessed object/,
        'attempt to register service with non blessed object fails correctly';

$container->register_service('DuplicateCar', $car);
my $duplicate = $container->get_service('DuplicateCar');
is_deeply($car, $duplicate, 'register_service');

# try to register service again
throws_ok { $container->register_service('DuplicateCar', $car) }
    qr/You are trying to register a service with an existing name/,
        'attempt to register duplicate service fails correctly';

isa_ok( $car, 'RA::UnitTest::Car', 'get_service' );
does_ok($car, 'RA::UnitTest::CarInterface');
cmp_ok($car->make,  'eq', 'Chevrolet', 'car correct make');
cmp_ok($car->model, 'eq', 'Z06', 'car correct model');
cmp_ok($car->year,  '==', 2007, 'car correct year');

my $engine = $car->engine;

isa_ok($engine, 'RA::UnitTest::Engine'); 
does_ok($engine, 'RA::UnitTest::EngineInterface');
cmp_ok($engine->make, 'eq', 'GM', 'engine make correct');
cmp_ok($engine->model, 'eq', 'LS7', 'engine model correct');
cmp_ok($engine->year, '==', 2007, 'engine year correct');
cmp_ok($engine->horsepower, '==', 505, 'engine horsepower correct');
cmp_ok($engine->displacement, '==', 7000, 'engine displacement correct');
cmp_ok($engine->cylinders, '==', 8, 'engine cylinders correct');

my $transmission = $car->transmission;

isa_ok($transmission, 'RA::UnitTest::Transmission');
does_ok($transmission, 'RA::UnitTest::TransmissionInterface');
cmp_ok($transmission->make, 'eq', 'Tremec', 'transmission make correct');
cmp_ok($transmission->model, 'eq', 'T56', 'transmission model correct');

my $interface = $transmission->interface;
isa_ok($interface, 'RA::UnitTest::6SpeedShifter');
does_ok($interface, 'RA::UnitTest::ShifterInterface');
cmp_ok($interface->pattern, 'eq', 'H', 'transmission interface is correct');

#-------------------------------------------------------------------------------
$car = $container->get_service('FastNFuriousCar');

isa_ok( $car, 'RA::UnitTest::Car', 'get_service' );
does_ok($car, 'RA::UnitTest::CarInterface');
cmp_ok($car->make,  'eq', 'VIN BENZINE', 'car correct make');
cmp_ok($car->model, 'eq', 'Z006', 'car correct model');
cmp_ok($car->year,  '==', 2012, 'car correct year');

$engine = $car->engine;

isa_ok($engine, 'RA::UnitTest::Engine'); 
does_ok($engine, 'RA::UnitTest::EngineInterface');
cmp_ok($engine->make, 'eq', "Ridiculous Engines R' Us", 'engine make correct');
cmp_ok($engine->model, 'eq', 'LS200', 'engine model correct');
cmp_ok($engine->year, '==', 2012, 'engine year correct');
cmp_ok($engine->horsepower, '==', 2000, 'engine horsepower correct');
cmp_ok($engine->displacement, '==', 14000, 'engine displacement correct');
cmp_ok($engine->cylinders, '==', 16, 'engine cylinders correct');

$transmission = $car->transmission;

isa_ok($transmission, 'RA::UnitTest::Transmission');
does_ok($transmission, 'RA::UnitTest::TransmissionInterface');
cmp_ok($transmission->make, 'eq', 'Tremec', 'transmission make correct');
cmp_ok($transmission->model, 'eq', 'T56', 'transmission model correct');

$interface = $transmission->interface;
isa_ok($interface, 'RA::UnitTest::6SpeedShifter');
does_ok($interface, 'RA::UnitTest::ShifterInterface');
cmp_ok($interface->pattern, 'eq', 'H', 'transmission interface is correct');

done_testing();

