use strict;
use warnings;
use inc::Module::Install;

name 'String-Interpolate-RE';

all_from 'lib/String/Interpolate/RE.pm';

author 'Diab Jerius';

bugtracker 'http://rt.cpan.org/Public/Dist/Display.html?Name=String-Interpolate-RE';

repository 'https://bitbucket.org/djerius/string-interpolate-re';

author_tests( 'xt' );

auto_install;

cpanfile;

WriteAll;
