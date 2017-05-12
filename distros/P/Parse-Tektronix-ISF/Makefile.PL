use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Parse::Tektronix::ISF',
    AUTHOR              => 'Ruizhe Yang <razor@cpan.org>',
    VERSION_FROM        => 'lib/Parse/Tektronix/ISF.pm',
    ABSTRACT_FROM       => 'lib/Parse/Tektronix/ISF.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Parse-Tektronix-ISF-*' },
);
