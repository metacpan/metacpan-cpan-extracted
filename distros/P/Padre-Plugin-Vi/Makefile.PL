use strict;
use warnings;
use inc::Module::Install 0.92;

name 'Padre-Plugin-Vi';
license 'perl';
author 'Gabor Szabo <szabgab@gmail.com>';
all_from 'lib/Padre/Plugin/Vi.pm';
requires 'Padre'            => '0.37';                #Padre::Constant
requires 'Wx::Perl::Dialog' => '0.04';
test_requires 'Test::More'  => '0.47';
no_index 'directory'        => qw{ t xt eg share inc};
homepage 'http://padre.perlide.org/';
bugtracker 'http://padre.perlide.org/';
repository 'http://svn.perlide.org/padre/trunk/Padre-Plugin-Vi';

is_padre_plugin;                                      # authors: Install Module::Install::PadrePlugin

install_share_with_mofiles;                           # install Locale::Msgfmt

WriteAll;
