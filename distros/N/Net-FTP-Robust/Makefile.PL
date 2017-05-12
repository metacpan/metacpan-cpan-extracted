use ExtUtils::MakeMaker;

use 5.008;

WriteMakefile
 ( NAME	 	=> 'Net::FTP::Robust'
 , VERSION	=> '0.08'
 , PREREQ_PM    =>
   { Log::Report     => 0.25
   , Time::HiRes     => 0
   , Test::Pod       => '1.00'
   }
 , EXE_FILES    => [ 'bin/ftp-get' ]
 , AUTHOR       => 'Mark Overmeer'
 , ABSTRACT     => 'download directories over unencrypted FTP'
 , LICENSE      => 'perl'
 );

### used by oodist during production of distribution
sub MY::postamble { <<'__POSTAMBLE' }

# for DIST
RAWDIR          = ../public_html/net-ftp-robust/raw
DISTDIR         = ../public_html/net-ftp-robust/source
LICENSE         = artistic

# for POD
FIRST_YEAR      = 2009
EMAIL           = perl@overmeer.net
WEBSITE         = http://perl.overmeer.net
__POSTAMBLE
