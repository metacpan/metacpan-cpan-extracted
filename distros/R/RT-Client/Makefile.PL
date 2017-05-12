#!/usr/bin/perl

use strict;
use inc::Module::Install;

name		('RT-Client');
author		('Autrijus Tang <autrijus@autrijus.org>');
abstract	('A client of RT from Best Practical Solutions');
license		('perl');
version_from	('lib/RT/Client.pm');

requires(qw(
    XML::Simple		    0.01
    XML::Atom		    0.07
    URI			    0
    Spiffy		    0.16
    LWP::Authen::Wsse	    0
    Digest::MD5		    0
));

include('ExtUtils::AutoInstall');
auto_install( -config => { force => 1 } );

WriteAll( sign => 1 );
