use strict;
use warnings;
use inc::Module::Install;

name 'MooX-TaggedAttributes';
license 'gpl3';
auto_license( holder => 'Smithsonian Astrophysical Observatory' );
all_from 'lib/MooX/TaggedAttributes.pm';

resources (
   license    => 'http://www.gnu.org/licenses/gpl-3.0.html',
   repository => 'https://bitbucket.org/djerius/moox-taggedattributes',
   bugtracker => 'https://rt.cpan.org/Public/Dist/Display.html?Name=MooX-TaggedAttributes',
);

author_tests( 'xt' );

cpanfile;

tests_recursive;

WriteAll;
