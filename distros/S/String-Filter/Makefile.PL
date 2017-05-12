use strict;
use inc::Module::Install;

name 'String-Filter';
all_from 'lib/String/Filter.pm';
readme_from 'lib/String/Filter.pm';

requires 'Regexp::Assemble';
test_requires 'HTML::Entities';
test_requires 'Test::More' => 0.88; # done_testing()
test_requires 'URI::Escape';

WriteAll;
