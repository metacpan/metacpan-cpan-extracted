use inc::Module::Install;

# Define metadata
name 'MooseX-Iterator';
all_from 'lib/MooseX/Iterator.pm';
license 'perl';

# Specific dependencies
requires 'Moose'            => '0.86';
build_requires 'Test::More' => '0.42';

WriteAll;
