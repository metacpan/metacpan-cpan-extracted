use 5.006;
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile
  (
   'NAME'		=> 'Net::BEEP::Lite::TLSProfile',
   'VERSION_FROM'	=> 'TLSProfile.pm',
   'PREREQ_PM'		=> {
			    'Net::BEEP::Lite' => 0.02,
			    'IO::Socket::SSL' => 0.90,
			    'Carp'            => 0,
			    'XML::LibXML'     => 1.50
			   },
   ABSTRACT_FROM        => 'TLSProfile.pm',
   AUTHOR               => 'David Blacka <davidb@verisignlabs.com>'
  );
