sub readme_from {}
sub auto_set_repository {}
sub author_tests {}
sub author_requires {}

use inc::Module::Install;
name 'MouseX-AttributeHelpers';
all_from 'lib/MouseX/AttributeHelpers.pm';

readme_from 'lib/MouseX/AttributeHelpers.pm';
auto_set_repository;

requires 'Mouse' => '0.40';
requires 'Mouse::Meta::Attribute';
requires 'Mouse::Util::TypeConstraints';

tests 't/*.t';
test_requires 'Any::Moose' => '0.10';
test_requires 'Test::More';
test_requires 'Test::UseAllModules';
test_requires 'Test::Deep';
test_requires 'Test::Data::Scalar';

author_tests 'xt';
author_requires 'Test::Pod';
author_requires 'Test::Pod::Coverage';
author_requires 'Test::Spelling';
author_requires 'ShipIt';
author_requires 'ShipIt::Step::Manifest';
author_requires 'ShipIt::Step::DistClean';

include_deps 'Test::More';
include_deps 'Test::UseAllModules';
include_deps 'Test::Deep';
include_deps 'Test::Data::Scalar';

WriteAll;
