use strict;
use warnings;
use inc::Module::Install;
use 5.008001;

name         'PDF-API3';
perl_version '5.008001';
all_from     'lib/PDF/API3.pm';
license      'perl';

test_requires 'Test::More';

WriteAll();
