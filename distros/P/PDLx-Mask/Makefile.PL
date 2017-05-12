#! perl

use strict;
use warnings;
use inc::Module::Install;

name 'PDLx-Mask';
license 'gpl3';
auto_license( holder => 'Smithsonian Astrophysical Observatory' );
all_from 'lib/PDLx/Mask.pm';

readme_from 'docs/README.src';
readme_from 'docs/README.src', { format => 'md' };;

author_tests( 'xt' );

tests_recursive;

cpanfile;

WriteAll;
