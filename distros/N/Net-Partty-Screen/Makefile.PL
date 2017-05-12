use inc::Module::Install;
name 'Net-Partty-Screen';
all_from 'lib/Net/Partty/Screen.pm';

requires $_ for (qw/
    Net::Partty
    Term::Cap
    Term::Screen
/);

features(
    'debug mode' => [
        recommends('Term::ReadKey'),
    ],
);

build_requires 'Test::More';
use_test_base;
auto_include;
WriteAll;
