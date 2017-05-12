use inc::Module::Install;

name 'MooX-Attributes-Shadow';
all_from 'lib/MooX/Attributes/Shadow.pm';

repository 'https://bitbucket.org/djerius/moox-attributes-shadow';
bugtracker 'https://rt.cpan.org/Public/Dist/Display.html?Name=MooX-Attributes-Shadow';

author_tests 'xt';
author_requires 'Test::NoBreakpoints';
author_requires 'Test::Perl::Critic';
author_requires 'Test::Pod::Coverage';
author_requires 'Test::Pod';

tests_recursive;

test_requires 'Moo';
test_requires 'Test::More';
test_requires 'Test::Deep';
test_requires 'Test::Exception';

requires 'Moo';
requires 'Moo::Role';
requires 'Params::Check';

no_index directory => qw[ inc t xt ];

WriteAll;
