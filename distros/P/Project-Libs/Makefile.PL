use inc::Module::Install;

name     'Project-Libs';
author   'Kentaro Kuribayashi, <kentarok@cpan.org>';
license  'MIT';
all_from 'lib/Project/Libs.pm';

requires 'FindBin::libs';
test_requires 'Test::More' => 0.96;

tests 't/*.t';
author_tests 'xt';

readme_markdown_from_pod;
auto_set_repository;
auto_include_deps;

WriteAll;
