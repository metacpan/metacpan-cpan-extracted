use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'PidFile',
    AUTHOR              => q{Lukasz Romanowski <lroman@cpan.org>},
    VERSION_FROM        => 'lib/PidFile.pm',
    ABSTRACT_FROM       => 'lib/PidFile.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::Most'                => 0,
        'Carp'                      => 0,
        'FindBin'                   => 0,
        'File::Slurp'               => 0,
        'File::Basename'            => 0,
        'MooseX::Declare'           => 0,
        'MooseX::ClassAttribute'    => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'PidFile-*' },
);
