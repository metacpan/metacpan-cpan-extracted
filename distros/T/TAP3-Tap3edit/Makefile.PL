# -*- perl -*-

use inc::Module::Install;

name('TAP3-Tap3edit');
abstract('Decodes, modifies and encodes TAP 3 files');
author('Javier Gutierrez <jgutierrez@tap3edit.com>');
version_from('lib/TAP3/Tap3edit.pm');
license('perl');

perl_version('5.005');
requires( perl => '5.005' );
requires( 'Convert::ASN1' );

clean_files(qw(y.tab.pl.bak));

include_deps('Test::More', 5.004);

check_nmake();      # check and download nmake.exe for Win32

&Meta->write;
&Makefile->write;

# &WriteAll;

