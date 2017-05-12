use 5.010000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Net::SMS::SMSPilot',
    VERSION_FROM      => 'lib/Net/SMS/SMSPilot.pm', # finds $VERSION
    PREREQ_PM         => {
				   'Test::More' => 0,
                   'LWP::UserAgent' => 0,
                   'HTTP::Request::Common' => 0,
                   'Encode' => 0
				   }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Net/SMS/SMSPilot.pm', # retrieve abstract from module
       AUTHOR         => 'Daniil Putilin <dadis@cpan.org>') : ()),
);
