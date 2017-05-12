use 5.006;
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile
  (
   'NAME'		=> 'Net::BEEP::Lite',
   'VERSION_FROM'	=> 'lib/Net/BEEP/Lite.pm',
   'PREREQ_PM'		=> {
			    'IO::Socket'   => 0,
			    'Carp'         => 0,
			    'XML::LibXML'  => 1.50,
			    'MIME::Base64' => 0.0
			   },
   ABSTRACT_FROM        => 'lib/Net/BEEP/Lite.pm',
   AUTHOR               => 'David Blacka <davidb@verisignlabs.com>'
  );
