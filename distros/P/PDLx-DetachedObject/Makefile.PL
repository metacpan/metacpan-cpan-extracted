#! perl

use strict;
use warnings;
use inc::Module::Install;

name 'PDLx-DetachedObject';
license 'gpl3';
auto_license( holder => 'Smithsonian Astrophysical Observatory' );
all_from 'lib/PDLx/DetachedObject.pm';

readme_from;
readme_from '', { format => 'md' };;

resources (
   license    => 'http://www.gnu.org/licenses/gpl-3.0.html',
   repository => 'https://github.com/djerius/PDLx-DetachedObject',
   bugtracker => 'https://rt.cpan.org/Public/Dist/Display.html?Name=PDLx-DetachedObject',
);


author_tests( 'xt' );

tests_recursive;

cpanfile;

WriteAll;
