use strict;
use warnings;
use inc::Module::Install;

name           'Parse-ErrorString-Perl';
license        'perl';
author         'Petar Shangov, <pshangov at yahoo.com>';
author         'Gabor Szabo <http://szabgab.com/>';
author         'Ahmad M. Zawawi <ahmad.zawawi@gmail.com>';
all_from       'lib/Parse/ErrorString/Perl.pm';

requires       'Carp'              => '0';
requires       'Class::XSAccessor' => '0';
requires       'File::Basename'    => '0';
requires       'File::Spec'        => '0';
requires       'Pod::Find'         => '0';
requires       'Pod::POM'          => '0.27';

test_requires  'Test::Differences' => '0';
test_requires  'Test::More'        => '0.47';

no_index       'directory'         => qw{ t xt eg share inc};
install_script 'bin/check_perldiag';
homepage       'http://padre.perlide.org/';
bugtracker     'https://github.com/PadreIDE/Parse-ErrorString-Perl';
repository     'https://github.com/PadreIDE/Parse-ErrorString-Perl';

WriteAll;
