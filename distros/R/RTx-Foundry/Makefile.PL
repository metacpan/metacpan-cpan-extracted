#!/usr/bin/env perl
# $File: //depot/RT/osf/Makefile.PL $ $Author: autrijus $
# $Revision: #7 $ $Change: 9904 $ $DateTime: 2004/02/04 19:02:17 $

use 5.008;
use inc::Module::Install;

warn << '.';
### PLEASE NOTE ##############################################

Greetings from the YAPC::Taipei::2004 party!

This package is designed to be overlaid on top of a rt3-elixus
(http://www.freshports.org/www/rt3-elixus/) installation; all
other environments are currently unsupported.

We will be porting the API to RT 3.3.x; Foundry will be easier
to install on top of it once RT 3.3.x is released.  Meanwhile,
please read the "INSTALL" file for platform-specific tips on
how to quickly set up RT Foundry.

Don't forget to run "foundry-setup" after the installation!

##############################################################
.

RTx('Foundry');
author('Autrijus Tang <autrijus@autrijus.org>');
abstract('Base classes for the RT Foundry system');
license	('gpl');

requires(
    'WWW::Mechanize'	    => 0,
    'Email::Valid'	    => 0,
    'MIME::Base64'	    => 0,
    'HTML::Mason'	    => 0,
    'DBIx::SearchBuilder'   => 0.96,
);

features( 'SVN2CVS support' => [
    -default => 0,
    'LWP::Simple'	    => 0,
    'Digest::MD5'	    => 0,
    'File::Temp'	    => 0,
    'IPC::Run'		    => 0,
    'MIME::Base64'	    => 0,
    'Regexp::Shellish'	    => 0.93,
    'Text::Diff'	    => 0,
    'XML::ValidWriter'	    => 0.37,
    'XML::Parser'	    => 0,
    'Pod::Links'	    => 0,
] );

auto_install( -default => 0 );
include('ExtUtils/AutoInstall.pm');
&WriteAll( check_nmake => 0, sign => 1 );
