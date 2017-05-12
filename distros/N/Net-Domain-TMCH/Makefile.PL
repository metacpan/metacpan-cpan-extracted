use ExtUtils::MakeMaker;

use 5.010;

my $version = '0.18';

WriteMakefile
 ( NAME	 	=> 'Net::Domain::TMCH'
 , VERSION	=> $version

 , PREREQ_PM    =>
     { Convert::X509                => '0.3'
     , Crypt::OpenSSL::VerifyX509   => '0.10'
     , Crypt::OpenSSL::X509         => '1.803'
     , Data::Dumper                 => 0
     , DateTime                     => 0
     , File::Basename               => 0
     , File::Slurp                  => 0
     , Getopt::Long                 => 0
     , LWP::UserAgent               => 0
     , MIME::Base64                 => 0
     , POSIX                        => 0
     , URI                          => 0

     , XML::Compile::WSS            => '1.09'
     , XML::Compile::WSS::Signature => '2.01'
     , XML::LibXML                  => 0
     }
 , EXE_FILES    => []
 , AUTHOR       => 'Mark Overmeer'
 , ABSTRACT     => 'Trademark Clearing House'
 , LICENSE      => 'perl'
 );

### used by oodist during production of distribution
sub MY::postamble { <<'__POSTAMBLE' }

# for DIST
RAWDIR          = ../public_html/net-domain-tmch/raw
DISTDIR         = ../public_html/net-domain-tmch/source
LICENSE         = artistic
SKIP_LINKS	= XML::LibXML

# for POD
FIRST_YEAR      = 2013
EMAIL           = perl@overmeer.net
EXTENDS         = ../XMLCompile:../XMLCache:../XMLC14N:../WSSSIG
WEBSITE         = http://perl.overmeer.net/net-domain-tmch/
PODTAIL		= PODTAIL.txt
__POSTAMBLE
