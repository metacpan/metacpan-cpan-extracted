use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'PID::File',
    AUTHOR              => q{Rob Brown <rob@intelcompute.com>},
    VERSION_FROM        => 'lib/PID/File.pm',
    ABSTRACT_FROM       => 'lib/PID/File.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES              => {},
    PREREQ_PM => {
        'Test::More'      => 0,
        'Test::Exception' => 0,
        'File::Basename'  => 0,
        'FindBin'         => 0,
        'Scalar::Util'    => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'PID-File-*' },
);
