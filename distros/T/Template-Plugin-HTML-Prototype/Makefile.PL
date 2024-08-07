use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Template::Plugin::HTML::Prototype',
    VERSION_FROM      => 'lib/Template/Plugin/HTML/Prototype.pm', # finds $VERSION
    PREREQ_PM         => {
    	'HTML::Prototype' => 0, 
    	'Template' => 0, 
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Template/Plugin/HTML/Prototype.pm', # retrieve abstract from module
       AUTHOR         => 'Bernhard Bauer <bauerb@in.tum.de>') : ()),
);
