use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Template::Plugin::XSLT',
    'VERSION_FROM'	=> 'XSLT.pm', # finds $VERSION
    'PREREQ_PM'		=> {
        Template => 0,
        XML::LibXSLT => 0
    }, # e.g., Module::Name => 1.1
);
