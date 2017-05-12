use inc::Module::Install;

name          'Mojolicious-Plugin-SassRenderer';
all_from      'lib/Mojolicious/Plugin/SassRenderer.pm';
author        q{Byron Hammond <byron_hammond <at> yahoo.com.au>};
license       'perl';

build_requires 'Test::More';
requires       'Mojolicious' => '0';
requires       'Text::Sass'  => '0.9.2';

auto_install;

WriteAll;

