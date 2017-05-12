use strict;
use warnings;
use inc::Module::Install;

name 'Padre-Plugin-Experimento';
all_from 'lib/Padre/Plugin/Experimento.pm';

requires 'Padre'         => '0.94';
requires 'Modern::Perl'  => '1.20120130';
requires 'Wx::Scintilla' => '0.3801';
requires 'IO::String'    => '1.08';

test_requires 'Test::More' => '0.88';

no_index 'directory' => qw{ t share inc};
homepage 'http://padre.perlide.org/trac/wiki/PadrePluginExperimento';
bugtracker 'http://padre.perlide.org/';
repository 'http://svn.perlide.org/padre/trunk/Padre-Plugin-Experimento';

install_share_with_mofiles;

WriteAll;
