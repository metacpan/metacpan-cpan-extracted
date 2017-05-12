use inc::Module::Install;

name 'MooseX-Types-UUID';
all_from 'lib/MooseX/Types/UUID.pm';

requires 'MooseX::Types';
build_requires 'Test::Exception';
build_requires 'Test::More';
build_requires 'ok';

resources(
    repository => "git://git.moose.perl.org/MooseX-Types-UUID.git",
    bugtracker => "https://rt.cpan.org/Dist/Display.html?Queue=MooseX-Types-UUID",
);

WriteAll();
