sub author_tests         {}
sub readme_from          {}
sub auto_set_repository  {}

use lib 'lib';
use inc::Module::Install;

name        'Module-Install-PrePAN';
all_from    'lib/Module/Install/PrePAN.pm';
readme_from 'lib/Module/Install/PrePAN.pm';

prepan module_url => 'http://prepan.org/module/3Yz7PYrBJG',
       author_url => 'http://prepan.org/user/3XR97nG2Gi';

auto_set_repository;

tests 't/*.t';
test_requires 'Test::More' => 0.96; # done_testing, subtest
author_tests('xt');

WriteAll;
