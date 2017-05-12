#!/usr/bin/perl
# $File: //member/autrijus/Module-CryptSource/Makefile.PL $ $Author: autrijus $
# $Revision: #1 $ $Change: 675 $ $DateTime: 2002/08/16 19:24:21 $

require 5.005;

use ExtUtils::MakeMaker;

WriteMakefile(
    AUTHOR		=> 'Autrijus Tang (autrijus@autrijus.org)',
    ABSTRACT		=> 'Encrypt and Decrypt source for Binary Packagers',
    NAME		=> 'Module::CryptSource',
    VERSION_FROM	=> 'CryptSource.pm',
    DISTNAME		=> 'Module-CryptSource',
    BINARY_LOCATION	=> 'x86/Module-CryptSource.tar.gz',

    PREREQ_PM		=> {
	'Test::More'		=> '0',
	'Storable'		=> '0',
	'MIME::Base64'		=> '0',
	'Term::ReadKey'		=> '0',
	'Digest::MD5'		=> '0',
	'Crypt::Rijndael'	=> '0',
    },

    dist		=> {
        COMPRESS	=> 'gzip -9',
        SUFFIX		=> '.gz',
    },
);

