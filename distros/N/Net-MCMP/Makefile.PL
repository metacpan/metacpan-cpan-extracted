use 5.006_001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Net::MCMP',
    VERSION_FROM      => 'lib/Net/MCMP.pm', # finds $VERSION
    PREREQ_PM         => {
    	'HTTP::Request' => '0',
    	'LWP::UserAgent' => '0'
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Net/MCMP.pm', # retrieve abstract from module
       AUTHOR         => 'Roman Jurkov <winfinit@cpan.org>') : ()),
);
