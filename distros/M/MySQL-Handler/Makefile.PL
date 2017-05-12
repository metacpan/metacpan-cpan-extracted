use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'MySQL::Handler',
    VERSION_FROM      => 'lib/MySQL/Handler.pm', # finds $VERSION
    PREREQ_PM         => {
									CGI::Carp 			=> 0,
									CGI::Util			=> 0,
									Class::Struct		=> 0,
									DBD::mysql			=> 0,
									DBI					=> 0,
	 							 }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/MySQL/Handler.pm', # retrieve abstract from module
       AUTHOR         => 'Charleston Software Associates <info@charlestonsw.com>') : ()),

);
