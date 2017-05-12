use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Python::Decorator',
    VERSION_FROM      => 'lib/Python/Decorator.pm', # finds $VERSION
    PREREQ_PM         => {
	'PPI' => 1.200,
	'Filter::Util::Call' => 1.34, 
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Python/Decorator.pm', # retrieve abstract from module
       AUTHOR         => 'Erwan Lemonnier <erwan@cpan.org>') : ()),
);

