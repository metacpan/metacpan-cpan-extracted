use ExtUtils::MakeMaker;

use 5.008;

WriteMakefile
 ( NAME	 	=> 'Net::FTPSSL::Robust'
 , VERSION	=> '0.05'
 , PREREQ_PM    =>
   { Log::Report      => 0.25
   , Net::FTP::Robust => 0.06
   , Net::FTPSSL      => 0.18
   }
 , EXE_FILES    => [ 'bin/ftpssl-get' ]
 , AUTHOR       => 'Mark Overmeer'
 , ABSTRACT     => 'download directories over FTP with SSL or TLS encryption'
 , LICENSE      => 'perl'
 );

### used by oodist during production of distribution
sub MY::postamble { <<'__POSTAMBLE' }

# for DIST
RAWDIR          = ../public_html/net-ftpssl-robust/raw
DISTDIR         = ../public_html/net-ftpssl-robust/source
LICENSE         = artistic

# for POD
FIRST_YEAR      = 2009
EMAIL           = perl@overmeer.net
WEBSITE         = http://perl.overmeer.net
__POSTAMBLE
