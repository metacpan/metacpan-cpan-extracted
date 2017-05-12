use inc::Module::Install;

name              'MooseX-Types-Vehicle';
perl_version_from 'lib/MooseX/Types/Vehicle.pm';
version_from      'lib/MooseX/Types/Vehicle.pm';
author            q{Evan Carroll <me@evancarroll.com>};
license           'perl';

requires 'Moose'                => '2.06';
requires 'MooseX::Types'        => '0.35';
requires 'MooseX::Types::Moose' => '0.35';

homepage 'https://github.com/EvanCarroll/mx-t-vehicle';
repository 'git://github.com/EvanCarroll/mx-t-vehicle.git';

build_requires 'Test::More';

auto_install;

WriteAll;

