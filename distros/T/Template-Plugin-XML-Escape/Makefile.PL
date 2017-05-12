use 5.006001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Template::Plugin::XML::Escape',
    VERSION_FROM      => 'lib/Template/Plugin/XML/Escape.pm', # finds $VERSION
    PREREQ_PM         => {
        'Test::More'  =>  0,
        'Template'    =>  2.10
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Template/Plugin/XML/Escape.pm', # retrieve abstract from module
       AUTHOR         => 'Toby Corkindale <cpan@corkindale.net>') : ()),
);
