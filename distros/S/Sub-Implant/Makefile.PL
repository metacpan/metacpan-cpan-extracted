use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Sub::Implant',
    AUTHOR              => q{Anno Siegel <anno5@mac.com>},
    VERSION_FROM        => 'lib/Sub/Implant.pm',
    ABSTRACT_FROM       => 'lib/Sub/Implant.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'    => 0,
        'DynaLoader'    => 0,
        'Carp'          => 0,
        'Scalar::Util'  => 0,
	'Sub::Identify' => 0,
	'Sub::Name'     => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Sub-Implant-*' },
);
