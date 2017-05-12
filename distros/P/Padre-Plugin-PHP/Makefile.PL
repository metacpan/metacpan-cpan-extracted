use strict;
use lib 'privinc';
use inc::Module::Install 0.92;


name 'Padre-Plugin-PHP';
license 'perl';
author 'Gabor Szabo <szabgab@gmail.com>';
all_from 'lib/Padre/Plugin/PHP.pm';
requires 'Padre' => '0.50';

test_requires 'Test::More' => '0.47';

no_index 'directory' => qw{ t xt eg share inc privinc};

homepage 'http://padre.perlide.org/';
bugtracker 'http://padre.perlide.org/';
repository 'http://svn.perlide.org/padre/trunk/Padre-Plugin-PHP';

is_padre_plugin; # authors: Install Module::Install::PadrePlugin
use_ptar() if author_context && $^O =~/win/i; #from Module::Install::PerlTar

WriteAll;
