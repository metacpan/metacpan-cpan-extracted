#!/usr/bin/env perl
use ExtUtils::MakeMaker;

use 5.010;

my $version = '0.13';

WriteMakefile
 ( NAME	 	=> 'Payment::Sisow'
 , VERSION	=> $version
 , PREREQ_PM    =>
    { Test::More           => 0.80
    , Log::Report          => '1.00'
    , XML::Compile::SOAP11 => '3.00'
    , XML::Compile::SOAP12 => '3.00'
    , XML::Compile::WSDL11 => '3.00'
    , File::Basename       => 0
    , File::Spec           => 0
    , Digest::SHA1         => 0
    }
 , EXE_FILES    => []
 , AUTHOR       => 'Mark Overmeer'
 , ABSTRACT     => 'connect to Dutch Sisow payment broker'
 , LICENSE      => 'perl'
 );

### used by oodist during production of distribution
sub MY::postamble { <<'__POSTAMBLE' }

# for DIST
RAWDIR          = ../public_html/payment-sisow/raw
DISTDIR         = ../public_html/payment-sisow/source
LICENSE         = artistic

# for POD
FIRST_YEAR      = 2013
EMAIL           = perl@overmeer.net
WEBSITE         = http://perl.overmeer.net/
__POSTAMBLE
