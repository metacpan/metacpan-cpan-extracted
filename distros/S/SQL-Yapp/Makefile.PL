use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'SQL::Yapp',
    AUTHOR              => 'Henrik Theiling <cpan@theiling.de>',
    VERSION_FROM        => 'lib/SQL/Yapp.pm',
    ABSTRACT_FROM       => 'lib/SQL/Yapp.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()
    ),
    PREREQ_PM => {
        'Carp'           => 0,
        'Data::Dumper'   => 0,
        'Filter::Simple' => 0,
        'Hash::Util'     => 0,
        'Scalar::Util'   => 0,
        'Test::More'     => 0,
        'Text::Balanced' => 0,
    },
    dist   => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean  => { FILES => 'SQL-Yapp-*' },
);
