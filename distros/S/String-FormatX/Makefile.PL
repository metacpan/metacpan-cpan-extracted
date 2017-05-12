use 5.00;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'String::FormatX',
    VERSION_FROM      => 'lib/String/FormatX.pm', # finds $VERSION
    PREREQ_PM         => {
				CGI::Carp 			=> 0,
				Number::Format			=> 0,
	 							 }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/String/FormatX.pm', # retrieve abstract from module
       AUTHOR         => 'Charleston Software Associates <info@charlestonsw.com>') : ()),

);
