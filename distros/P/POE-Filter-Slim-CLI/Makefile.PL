use inc::Module::Install;

perl_version '5.6.1';

name 'POE-Filter-Slim-CLI';
author 'Andy Grundman <andy@slimdevices.com>';
license 'perl';
all_from 'lib/POE/Filter/Slim/CLI.pm';

build_requires 'Test::More' => 0.47;
requires 'Clone';
requires 'POE' => 0.38;
requires 'URI';

if (-e 'inc/.author') {
    build_requires 'Test::Perl::Critic';
}

WriteAll();
