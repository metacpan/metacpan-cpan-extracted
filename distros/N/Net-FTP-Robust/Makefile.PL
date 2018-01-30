use ExtUtils::MakeMaker;

use 5.008;

WriteMakefile
 ( NAME	 	=> 'Net::FTP::Robust'
 , VERSION	=> '0.09'
 , PREREQ_PM    =>
   { Log::Report     => 0.25
   , Time::HiRes     => 0
   }
 , EXE_FILES    => [ 'bin/ftp-get' ]
 , AUTHOR       => 'Mark Overmeer'
 , ABSTRACT     => 'download files over FTP'
 , LICENSE      => 'perl'

 , META_MERGE =>
      { 'meta-spec' => { version => 2 }
      , resources  =>
          { repository =>
              { type => 'git'
              , url  => 'https://github.com/markov2/perl5-Net-FTP-Robust.git'
              , web  => 'https://github.com/markov2/perl5-Net-FTP-Robust'
              }
          }
      , homepage => 'http://perl.overmeer.net/CPAN/'
      , license  => [ 'http://dev.perl.org/licenses/' ]
      }

 );

### used by oodist during production of distribution
sub MY::postamble { <<'__POSTAMBLE' }

# for DIST
RAWDIR          = ../public_html/net-ftp-robust/raw
DISTDIR         = ../public_html/net-ftp-robust/source
LICENSE         = perl

# for POD
FIRST_YEAR      = 2009
EMAIL           = markov@cpan.org
WEBSITE         = http://perl.overmeer.net/CPAN/
__POSTAMBLE
