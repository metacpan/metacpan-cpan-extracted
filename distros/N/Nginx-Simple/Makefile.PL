use strict;
use warnings;
use inc::Module::Install;

perl_version '5.008004';

name 'Nginx-Simple';
all_from 'lib/Nginx/Simple.pm';
license 'perl';

requires 'XML::Simple';
requires 'CGI::Cookie';
requires 'Time::HiRes';
requires 'nginx';

install_script glob('bin/ngs');

WriteAll();
