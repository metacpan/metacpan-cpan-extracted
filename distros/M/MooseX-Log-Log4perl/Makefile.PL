use inc::Module::Install '0.85';

name 'MooseX-Log-Log4perl';
all_from 'lib/MooseX/Log/Log4perl.pm';

build_requires 'IO::Scalar';
build_requires 'Test::More';

requires 'Moo' => '1.000007';
requires 'Log::Log4perl' => '1.13';

license 'perl';

auto_install;
WriteAll;
