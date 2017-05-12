use strict;
use warnings;
use inc::Module::Install 0.67;
use Module::Install::AuthorRequires;
use Module::Install::AuthorTests;

name 'MooseX-MetaDescription';
all_from 'lib/MooseX/MetaDescription.pm';
license 'perl';

# prereqs
requires 'Moose' => 0.40;

# things the tests need
test_requires 'Test::More' => '0.62';
test_requires 'Test::Exception';

author_requires 'Test::Pod' => '1.14';
author_requires 'Test::Pod::Coverage';

tests('t/*.t');
author_tests 't-author';

WriteAll();

