use inc::Module::Install;
name 'Rhetoric-Theme-SandStone';
all_from 'lib/Rhetoric/Theme/SandStone.pm';

# requires '';
requires 'Squatting'                  => '0.81';
requires 'Method::Signatures::Simple' => 0;
requires 'Template'                   => 0;
requires 'Rhetoric'                   => '0.06';

tests 't/*.t';
author_tests 'xt';

install_share 'share';

test_requires 'Test::More';
auto_set_repository;
auto_include;
WriteAll;
