use inc::Module::Install;

name     'Regexp-Common-microsyntax';
all_from 'lib/Regexp/Common/microsyntax.pm';
author   q{Gavin Carr <gavin@openfusion.com.au>};
license  'perl';

build_requires 'Test::More' >= 0.88;
build_requires 'Test::Deep';
build_requires 'Encode';
build_requires 'YAML';

requires 'Regexp::Common';
requires 'utf8';

auto_install;

WriteAll;

