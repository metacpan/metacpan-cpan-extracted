######################################################################
# Makefile.PL for Script::Resume
# 2006, Robert Powers <batman@cpan.org>
######################################################################
use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'         => 'Script::Resume',
    'VERSION_FROM' => 'lib/Script/Resume.pm', # finds $VERSION
    'PREREQ_PM'    => {
      Data::Dumper   => 0,
      File::Basename => 0,
      FileHandle     => 0,
      Test::More     => 0,
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/Script/Resume.pm',
       AUTHOR     => 'Robert Powers <batman@cpan.org>') : ()),
);
