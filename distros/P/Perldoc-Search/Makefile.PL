######################################################################
# Makefile.PL for Perldoc::Search
# 2005, Mike Schilli <cpan@perlmeister.com>
######################################################################
use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'         => 'Perldoc::Search',
    'VERSION_FROM' => 'lib/Perldoc/Search.pm', # finds $VERSION
    'PREREQ_PM'    => {
        SWISH::API::Common       => 0,
        Shell::POSIX::Select     => 0,
        Pod::Simple::TextContent => 0,
        File::Temp               => 0,
    }, # e.g., Module::Name => 1.1
    EXE_FILES      => ['eg/perldig'],
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/Perldoc/Search.pm',
       AUTHOR     => 'Mike Schilli <cpan@perlmeister.com>') : ()),
);
