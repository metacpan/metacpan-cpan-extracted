use 5.008;
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Template::Plugin::SSI',
    'VERSION_FROM'	=> 'SSI.pm', # finds $VERSION
    'PREREQ_PM'		=> {'CGI::SSI' => '0.82'}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'SSI.pm', # retrieve abstract from module
       AUTHOR     => 'Corey Wilson <cwilson@sbgnet.com>') : ()),
);
