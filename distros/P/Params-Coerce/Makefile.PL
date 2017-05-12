use strict;
use inc::Module::Install;

name           'Params-Coerce';
all_from       'lib/Params/Coerce.pm';
requires       'Carp'            => 0 ;
requires       'Scalar::Util'    => '1.11';
requires       'Params::Util'    => '0.05';
build_requires 'Test::More'      => '0.47';

WriteAll;
