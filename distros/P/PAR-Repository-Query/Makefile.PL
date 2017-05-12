use 5.006;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'PAR::Repository::Query',
    VERSION_FROM      => 'lib/PAR/Repository/Query.pm', # finds $VERSION
    LICENSE => 'perl',
    PREREQ_PM         => {
#'perl'      => '5.6',
		'version' => '0.50',
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/PAR/Repository/Query.pm', # retrieve abstract from module
       AUTHOR         => 'Steffen Müller <smueller@cpan.org>') : ()),
);
