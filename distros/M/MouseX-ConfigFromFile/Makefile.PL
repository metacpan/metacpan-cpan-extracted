use inc::Module::Install;
name 'MouseX-ConfigFromFile';
all_from 'lib/MouseX/ConfigFromFile.pm';

readme_from 'lib/MouseX/ConfigFromFile.pm';
readme_markdown_from 'lib/MouseX/ConfigFromFile.pm';
auto_set_repository;

requires 'Mouse' => '0.39';
requires 'MouseX::Types::Path::Class' => '0.06';

tests 't/*.t';
test_requires 'Test::More' => '0.94';
test_requires 'Test::UseAllModules';

author_tests 'xt';
author_requires 'Test::Pod';
author_requires 'Test::Pod::Coverage';
author_requires 'Test::Spelling';
author_requires 'ShipIt';
author_requires 'ShipIt::Step::Manifest';
author_requires 'ShipIt::Step::DistClean';
author_requires 'ShipIt::Step::Twitter';

auto_include_deps;
WriteAll;
