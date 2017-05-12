use inc::Module::Install;

name            'Template-Declare';
license         'perl';
author          'Jesse Vincent <jesse@bestpractical.com>';
all_from        'lib/Template/Declare.pm';

perl_version '5.8.2';

build_requires  'Test::More';
build_requires  'Test::Warn' => 0.11;
requires 'Class::Accessor::Fast';
requires 'Class::Data::Inheritable';
requires 'Class::ISA';
requires 'String::BufferStack' => 1.10;


feature 'HTML Lint testing' => 
    -default => 0,
    'HTML::Lint' => 0;

sign;
auto_install;
WriteAll;
