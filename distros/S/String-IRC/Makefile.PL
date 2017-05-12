use inc::Module::Install;

name        'String-IRC';
all_from    'lib/String/IRC.pm';

# requires 'UNIVERSAL::require'    => 0;

build_requires 'Test::More'      => 0;
build_requires 'Test::Base'      => 0;

use_test_base;
auto_install;
WriteAll;
