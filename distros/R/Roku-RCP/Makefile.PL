######################################################################
# Makefile.PL for Roku::RCP
# 2007, Robert Powers <batman@cpan.org>
######################################################################
use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'         => 'Roku::RCP',
    'VERSION_FROM' => 'lib/Roku/RCP.pm', # finds $VERSION
    'PREREQ_PM'    => {
      Net::Cmd   => 0,
      IO::Socket   => 0,
      IO::Socket::INET   => 0,
      Test::More     => 0,
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/Roku/RCP.pm',
       AUTHOR     => 'Robert Powers <batman@cpan.org>') : ()),
);
