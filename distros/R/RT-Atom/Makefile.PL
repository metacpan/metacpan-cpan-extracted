#!/usr/bin/env perl
# $File: //depot/RT/osf/Makefile.PL $ $Author: autrijus $
# $Revision: #7 $ $Change: 9904 $ $DateTime: 2004/02/04 19:02:17 $

use inc::Module::Install;

warn << '.';
### PLEASE NOTE ##############################################

You need a RT3 instance before installing this module.
RT3 is available from http://www.bestpractical.com/rt/.

##############################################################
.

RTx('RT-Atom');
author('Autrijus Tang <autrijus@autrijus.org>');
abstract('Atom API for RT');
license('gpl');

requires(qw(
    URI		    0
    XML::Simple	    0
    Digest::MD5	    0
    Digest::SHA1    0
    MIME::Base64    0
));

include('ExtUtils::AutoInstall');
auto_install( -config => { force => 1 } );

&WriteAll( check_nmake => 0, sign => 1 );

