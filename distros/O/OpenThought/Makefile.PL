# Makefile.PL for OpenThought                            http://openthought.net
# ---------------------------                           eric at openthought.net

use lib "./dist";
use inc::Module::Install;

name         ('OpenThought');
abstract     ('Build web pages which do not require the page to reload');
author       ('Eric Andreychek <eric@openthought.net>');
license      ('gpl');
version_from ('lib/OpenThought.pm');

include( 'File::NCopy'           => '0' );
include( 'Text::Template'        => '0' );
include( 'ExtUtils::AutoInstall' => '0.40' );

requires(
      'Test::Harness'         => '2.0',
      'Test::More'            => '0.47',
      'File::Spec'            => '0.82',
      'HTML::Template'        => '2.2',
      'OpenThought::XML2Hash' => '0.57',
      'OpenPlugin'            => '0.11',
);


&OpenThought->config();

check_nmake();      # check and download nmake.exe for Win32

&AutoInstall->run;
&Makefile->write;


