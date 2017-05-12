use 5.006;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Template::Plugin::SimpleJson',
    VERSION_FROM      => 'lib/Template/Plugin/SimpleJson.pm', # finds $VERSION
    PREREQ_PM         => {
        Template       => 2.14,
	JSON	=> 2.04,
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Template/Plugin/SimpleJson.pm', # retrieve abstract from module
       AUTHOR         => 'Fabio Masini <fabio.masini@gmail.com>') : ()),
);
