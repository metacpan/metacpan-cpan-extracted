#! perl

use strict;
use warnings;
use inc::Module::Install;

name 'Shell-GetEnv';

license 'gpl3';
auto_license( holder => 'Smithsonian Astrophysical Observatory' );
all_from 'lib/Shell/GetEnv.pm';
readme_from;
readme_from '', { format => 'md' };;

contributors q[Marty O'Brien <mob@cpan.org>] ;

resources (
   license    => 'http://www.gnu.org/licenses/gpl-3.0.html',
   repository => 'https://github.com/djerius/shell-getenv',
   bugtracker => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Shell-GetEnv',
);

author_tests( 'xt' );

cpanfile;

WriteAll;
