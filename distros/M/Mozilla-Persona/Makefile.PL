use ExtUtils::MakeMaker;

WriteMakefile
  ( NAME        => 'Mozilla::Persona'
  , VERSION     => '0.12'
  , PREREQ_PM   =>
     { 'CGI'                    => 0
     , 'CGI::Session'		=> 0
     , 'Crypt::OpenSSL::Bignum'	=> 0
     , 'Crypt::OpenSSL::RSA'	=> 0
     , 'File::Basename'		=> 0
     , 'File::Slurp'		=> 0
     , 'File::Spec'		=> 0
     , 'Getopt::Long'		=> 0
     , 'JSON'			=> 0
     , 'List::Util'		=> 0
     , 'Log::Report'		=> 0
     , 'LWP::UserAgent'		=> 0
     , 'LWP::Protocol::https'   => 0
     , 'MIME::Base64'		=> 3.11
     , 'Time::HiRes'		=> 0
     , 'URI'			=> 0
     , 'Test::More'		=> 0
     , 'Term::ReadPassword'     => 0.11

     # to be made conditional later
     , 'Mail::ExpandAliases'	=> 0
     , 'Mail::IMAPTalk'	        => 0
     , 'Apache::Htpasswd'       => 1.9
     , 'Digest'                 => 0
     }
  , AUTHOR      => 'Mark Overmeer'
  , ABSTRACT    => 'Mozilla Persona server implementation'
  , LICENSE     => 'perl'
  , EXE_FILES   => [ 'bin/persona' ]
  );

#### the next lines are added for OODoc, which generates the
#### distribution.
sub MY::postamble { <<'__POSTAMBLE' }

# for DIST
RAWDIR          = ../public_html/persona/raw
DISTDIR         = ../public_html/persona/source
LICENSE         = artistic

# for POD
FIRST_YEAR      = 2012
EMAIL           = perl@overmeer.net
WEBSITE         = http://perl.overmeer.net
__POSTAMBLE

