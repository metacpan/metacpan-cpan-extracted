use 5.012003;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Test::AutomationFramework',
    VERSION_FROM      => 'lib/Test/AutomationFramework.pm', # finds $VERSION
    MAKE 	      => 'dmake',
    PREREQ_PM         => {
      "Date::Manip" => 6.23,
      "File::Path"=> 2.08_01,
      "Test::More"=> 0.96,
      "Getopt::Long"=> 2.38,
      "File::Copy"=> 2.18,
      "File::Copy::Recursive"=> 0.38,
      "Regexp::Assemble"=> 0.35,
      "HTTP::Server::Simple::CGI"=> 0.44,
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Test/AutomationFramework.pm', # retrieve abstract from module
       AUTHOR         => 'Yong Wang <ywangperl@gmail.com>') : ()),      
);

