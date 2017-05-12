#!/usr/bin/perl

use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		=> 'Net::SMTP_auth',
    'AUTHOR'            => 'Alex Pleiner <alex@zeitform.de>',
    'ABSTRACT'          => 'SMTP_AUTH wrapper for Net::SMTP (rfc2554)',
    'VERSION_FROM'	=> 'SMTP_auth.pm', # finds $VERSION
    'PREREQ_PM'		=> {
                             Net::SMTP => 2.26,
                             MIME::Base64 => 2.00,
                             Digest::HMAC_MD5 => 1.00,
			     Authen::SASL => 2.03,
			   },

);
