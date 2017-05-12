use strict;
use warnings;
use inc::Module::Install;

name 'Padre-Plugin-Mojolicious';
license 'perl';
author 'Breno G. de Oliveira <garu@cpan.org>';
author 'Ahmad M. Zawawi <ahmad.zawawi@gmail.com>';
all_from 'lib/Padre/Plugin/Mojolicious.pm';
requires 'Padre'           => '0.92';
requires 'File::Basename'  => 0;
requires 'Mojolicious'     => '2.34';
test_requires 'Test::More' => '0.47';
no_index 'directory'       => qw{ t xt eg share inc};
homepage 'http://padre.perlide.org/';
bugtracker 'http://padre.perlide.org/';
repository 'http://svn.perlide.org/padre/trunk/Padre-Plugin-Mojolicious';

WriteAll;
