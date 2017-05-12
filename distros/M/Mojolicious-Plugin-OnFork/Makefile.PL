use inc::Module::Install;

name            'Mojolicious-Plugin-OnFork';
all_from        'lib/Mojolicious/Plugin/OnFork.pm';
author          'Bernhard Graf <graf@cpan.org>';
license         'perl';
repository      'git://github.com/augensalat/mojolicious-plugin-onfork.git';

build_requires  'Test::More';
build_requires  'Test::Mojo';

requires        'Mojolicious' => '3.09';
requires        'Carp';

auto_install;

WriteAll;

