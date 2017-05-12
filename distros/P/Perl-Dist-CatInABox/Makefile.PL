use inc::Module::Install 0.77;

all_from       'lib/Perl/Dist/CatInABox.pm';
requires       'Perl::Dist::Strawberry' => '1.07';
build_requires 'Test::More'             => '0.42';

WriteAll;
