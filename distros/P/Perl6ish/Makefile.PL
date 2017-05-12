use inc::Module::Install;
name 'Perl6ish';
all_from 'lib/Perl6ish.pm';

requires
    'Readonly' => 1.03,
    'Perl6::Contexts' => 0.4,
    'Perl6::Junction' => 1.40000,
    'Perl6::Perl' => 0.01,
    'Perl6::Slurp' => 0.03,
    'Perl6::Caller' => 0.04,
    'Perl6::Take' => 0.04,
    'Data::Bind' => 0.30,
    'Scalar::Util' => 1.19,
    'List::Util' => 1.19,
    'Devel::Caller' => 2.03,
    'Devel::Declare' => 0.003004,
    'Devel::BeginLift' => 0.001002,
    'B::Hooks::Parser' => 0.08;

tests 't/*.t';
author_tests 'xt';

build_requires 'Test::More';

auto_include;
WriteAll;
