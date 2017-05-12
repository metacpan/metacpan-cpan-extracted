use inc::Module::Install;

name     'MooseX-CurriedHandles';
all_from 'lib/MooseX/CurriedHandles.pm';
author   'Joel Bernstein <rataxis@cpan.org>';

build_requires 'Test::More';
build_requires 'Moose';

no_index(package => 'Another');
no_index(package => 'MyClass');

auto_install;

WriteAll;

