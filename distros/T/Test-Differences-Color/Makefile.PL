use inc::Module::Install;

name     'Test-Differences-Color';
all_from 'lib/Test/Differences/Color.pm';
author   q{Alec Chen <alec@cpan.org>};
license  'perl';

build_requires 'Test::More';

requires 'Sub::Override' => 0.08;
requires 'Exporter' => 5.63;
requires 'Term::ANSIColor' => 2.01;
requires 'Test::Differences' => 0.4801;

auto_install;

WriteAll;

