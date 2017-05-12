use strict;
use warnings;
use inc::Module::Install;

name 'MooX-Cmd-ChainedOptions';
license 'gpl3';
auto_license( holder => 'Smithsonian Astrophysical Observatory' );
all_from 'lib/MooX/Cmd/ChainedOptions.pm';

author_tests( 'xt' );

tests_recursive;

resources (
   license    => 'http://www.gnu.org/licenses/gpl-3.0.html',
   repository => 'https://bitbucket.org/djerius/moox-cmd-chainedoptions',
   bugtracker => 'https://rt.cpan.org/Public/Dist/Display.html?Name=MooX-Cmd-ChanedOptions',
);

cpanfile;

WriteAll;
