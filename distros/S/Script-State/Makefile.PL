use inc::Module::Install;

name 'Script-State';
all_from 'lib/Script/State.pm';

requires 'PadWalker';
requires 'Data::Dumper';
requires 'Carp';
requires 'File::Spec';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';

readme_markdown_from_pod;

auto_set_repository;
auto_include;

WriteAll;
