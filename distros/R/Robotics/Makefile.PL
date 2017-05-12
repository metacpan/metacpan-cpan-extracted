use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Robotics',
    AUTHOR              => q{Jonathan Cline <jcline@ieee.org>},
    VERSION_FROM        => 'lib/Robotics.pm',
    ABSTRACT_FROM       => 'lib/Robotics.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PERLRUN             => '/cygdrive/c/perl/bin/perl',
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Robotics-*' },
);
