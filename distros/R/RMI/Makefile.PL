
use warnings FATAL => 'all';
use strict;
use inc::Module::Install;

name    'RMI';
license 'perl';
all_from 'lib/RMI.pm';

# prereqs
requires 'Carp';
requires 'IO::Socket';
requires 'version';

# things the tests need
build_requires 'Test::More' => '0.86';
build_requires 'App::Prove';

#tests('t/*.t t/*/*.t');

WriteAll();

