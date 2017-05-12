use inc::Module::Install;

name        'Params-Registry';
readme_from 'lib/Params/Registry.pm';
all_from    'lib/Params/Registry.pm';
author      q{Dorian Taylor <dorian@cpan.org>};
license     'apache';

requires 'Moose'                    => '2.0604';
requires 'namespace::autoclean'     => '0.20';
requires 'MooseX::Types'            => '0.35';
requires 'MooseX::Params::Validate' => '0.18';
requires 'Throwable'                => '0.200008';
requires 'URI'                      => '1.60';
requires 'Set::Scalar'              => '1.25';
requires 'Set::Infinite'            => '0.63';
requires 'DateTime'                 => '0.70';
requires 'DateTime::Set'            => '0.31';
requires 'Tie::IxHash'              => '1.23';

build_requires 'Test::More';

auto_install;

WriteAll;

