use strict;
use warnings;
use inc::Module::Install;



test_requires     'Test::More';
requires          'Carp';
name              'Object-Composer';
all_from          'lib/Object/Composer.pm';

WriteAll;

