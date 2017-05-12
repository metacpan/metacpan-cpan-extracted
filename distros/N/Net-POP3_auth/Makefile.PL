#!/usr/bin/perl

use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		=> 'Net::POP3_auth',
    'AUTHOR'            => 'Alex Pleiner <alex@zeitform.de>',
    'ABSTRACT'          => 'POP3_AUTH wrapper for Net::POP3 (rfc1734)',
    'VERSION_FROM'	=> 'POP3_auth.pm', # finds $VERSION
    'PREREQ_PM'		=> {
                             Net::POP3 => 2.00,
                             MIME::Base64 => 2.00,
                             Digest::HMAC_MD5 => 1.00,
			     Authen::SASL => 2.03,
			   },

);
