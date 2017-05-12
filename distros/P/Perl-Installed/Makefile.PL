######################################################################
# Makefile.PL for Perl::Installed
# 2007, Mike Schilli <m@perlmeister.com>
######################################################################
use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'         => 'Perl::Installed',
    'VERSION_FROM' => 'Installed.pm', # finds $VERSION
    'PREREQ_PM'    => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Installed.pm',
       AUTHOR     => 'Mike Schilli <m@perlmeister.com>') : ()),
);
