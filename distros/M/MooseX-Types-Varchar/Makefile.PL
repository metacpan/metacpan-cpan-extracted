use inc::Module::Install;
require Module::Install::AuthorTests;

name 'MooseX-Types-Varchar';
all_from 'lib/MooseX/Types/Varchar.pm';

test_requires 'Test::More' => '0.88';
test_requires 'Test::Exception';
test_requires 'Test::NoWarnings';
author_requires 'Test::NoTabs';
author_requires 'Test::EOL' => '0.7';
requires 'Moose';
requires 'MooseX::Types';
requires 'MooseX::Types::Parameterizable' => '0.07';

author_tests 't/author';

resources repository => 'git://github.com/chrisa/moosex-types-varchar.git';

WriteAll;
