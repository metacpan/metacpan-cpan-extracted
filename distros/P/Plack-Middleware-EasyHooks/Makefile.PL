use inc::Module::Install;

name     'Plack-Middleware-EasyHooks';
all_from 'lib/Plack/Middleware/EasyHooks.pm';
author   q{Peter Makholm <peter@makholm.net>};
license  'perl';
githubmeta;

requires 'Plack';
build_requires 'Test::More';

auto_install;

WriteAll;

