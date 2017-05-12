use strict;
use warnings;
use inc::Module::Install;

name 'Padre-Plugin-Moose';
all_from 'lib/Padre/Plugin/Moose.pm';

requires 'Padre'           => '0.94';
requires 'Moose'           => '2.0402';
test_requires 'Test::More' => '0.88';

no_index 'directory' => qw{ t share inc};
homepage 'http://padre.perlide.org/trac/wiki/PadrePluginMoose';
bugtracker 'http://padre.perlide.org/';
repository 'http://svn.perlide.org/padre/trunk/Padre-Plugin-Moose';

install_share_with_mofiles;

WriteAll;
