use strict;
use warnings;
use inc::Module::Install;

name 'Padre-Plugin-PDL';
all_from 'lib/Padre/Plugin/PDL.pm';

requires 'Padre' => '0.94';
requires 'Moose' => '2.0402';
requires 'PDL'   => '2.4.10';

test_requires 'Test::More' => '0.88';

no_index 'directory' => qw{ t xt eg share inc};
homepage 'http://padre.perlide.org/trac/wiki/PadrePluginPDL';
bugtracker 'http://padre.perlide.org/';
repository 'http://svn.perlide.org/padre/trunk/Padre-Plugin-PDL';

install_share_with_mofiles;

WriteAll;
