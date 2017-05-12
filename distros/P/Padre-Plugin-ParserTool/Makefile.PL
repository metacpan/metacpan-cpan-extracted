use strict;
use warnings;
use inc::Module::Install;

name 'Padre-Plugin-ParserTool';
all_from 'lib/Padre/Plugin/ParserTool.pm';

requires 'Padre'          => '0.94';
requires 'Devel::Dumpvar' => '0.04';
requires 'Data::Dumper'   => '2.101';
requires 'PPI::Dumper'    => '1.213';

test_requires 'Test::More' => '0.88';

no_index 'directory' => qw{ t xt share inc};
homepage 'http://padre.perlide.org/trac/wiki/PadrePluginParserTool';
bugtracker 'http://padre.perlide.org/';
repository 'http://svn.perlide.org/padre/trunk/Padre-Plugin-ParserTool';

install_share_with_mofiles;

WriteAll;
