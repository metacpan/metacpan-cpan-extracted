use 5.008008;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'Net::SMS::Clickatell::SOAP',
    VERSION_FROM      => 'lib/Net/SMS/Clickatell/SOAP.pm', # finds $VERSION
    PREREQ_PM         => {
    	SOAP::Lite 	=> '0.710.08',
    	version		=> '0.85'
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Net/SMS/Clickatell/SOAP.pm', # retrieve abstract from module
       AUTHOR         => 'Peter Farr <Peter.Farr@LPI-Solutions.com>'
      ) : ()),
);
