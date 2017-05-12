use inc::Module::Install;

all_from 'lib/SVK/Command/Churn.pm';
name 'SVK-Churn';
abstract 'Generate SVK Statistics graph.';

requires
    Quantum::Superpositions => 0,
    SVK                     => 2.00,
    IO::All                 => 0,
    Chart::Strip            => 0;

build_requires 'Test::More';
build_requires 'Test::Pod';
build_requires 'Test::Pod::Coverage';

WriteAll;

