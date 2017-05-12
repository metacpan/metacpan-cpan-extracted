use strict;
use warnings;
use inc::Module::Install;
use 5.008005;

name 'Router-Generic';
perl_version '5.008001';
license 'perl';
all_from 'lib/Router/Generic.pm';

test_requires 'Test::More'          => '0.70';

requires      'Carp';

tests_recursive();
WriteAll();

