use inc::Module::Install;
name 'MouseX-Types-Path-Class';
all_from 'lib/MouseX/Types/Path/Class.pm';

readme_from 'lib/MouseX/Types/Path/Class.pm';
readme_markdown_from 'lib/MouseX/Types/Path/Class.pm';
auto_set_repository;

requires 'Mouse' => '0.39';
requires 'MouseX::Types' => '0.02';
requires 'Path::Class';

recommends 'MouseX::Getopt' => '0.2200';

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

WriteAll;
