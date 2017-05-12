use inc::Module::Install;

RTx('RT-Extension-DateDiscordian');
all_from 'lib/RT/Extension/DateDiscordian.pm';
author   'Kevin Falcone <falcone@bestpractical.com>';

build_requires 'Test::More';
requires('Date::Discordian');

auto_install;

WriteAll;

