use inc::Module::Install 0.79;

use warnings;

all_from 'lib/Module/Install/ProvidesClass.pm';

requires 'inc::Module::Install' => 0.79;
requires 'Class::Discover' => 1.000001;

test_requires 'Test::More' => 0.88;
test_requires 'Test::Differences';
test_requires 'Moose';

auto_provides;
auto_provides_class;
auto_install;

WriteAll;
