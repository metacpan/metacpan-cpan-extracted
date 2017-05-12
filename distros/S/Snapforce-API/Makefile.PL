use 5.018002;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Snapforce::API',
    VERSION_FROM      => 'lib/Snapforce/API.pm', # finds $VERSION
    PREREQ_PM         => {
		'XML::Parser'			=> '2.44',
		'HTTP::Request::Common'	=> '6.11',
		'LWP::UserAgent'		=> '6.15'}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Snapforce/API.pm', # retrieve abstract from module
       AUTHOR         => 'Gabriel Benamy <gabriel_benamy@snapforce.com>') : ()),
);
