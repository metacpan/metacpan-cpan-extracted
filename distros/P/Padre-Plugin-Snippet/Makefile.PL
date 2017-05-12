use strict;
use warnings;
use inc::Module::Install;

name 'Padre-Plugin-Snippet';
license 'perl';
author 'Ahmad M. Zawawi <ahmad.zawawi@gmail.com>';
all_from 'lib/Padre/Plugin/Snippet.pm';

requires 'Padre'           => '0.94';
requires 'Moose'           => '2.0402';
requires 'YAML'            => '0.80';
test_requires 'Test::More' => '0.47';

no_index 'directory' => qw{ t eg share inc};
homepage 'http://padre.perlide.org/trac/wiki/PadrePluginSnippet';
bugtracker 'http://padre.perlide.org/';
repository 'http://svn.perlide.org/padre/trunk/Padre-Plugin-Snippet';

install_share_with_mofiles;

WriteAll;
