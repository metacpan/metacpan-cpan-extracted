use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Net::WebCL',
    VERSION_FROM      => 'lib/Net/WebCL.pm', # finds $VERSION
    PREREQ_PM         => {
       'LWP' => '6.05',
       'HTTP::Cookies' => '6.01',
       'HTTP::Request::Common' => '6.06',
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Net/WebCL.pm', # retrieve abstract from module
       AUTHOR         => 'root <root@localdomain>') : ()),
);
