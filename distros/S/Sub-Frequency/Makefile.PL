use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Sub::Frequency',
    AUTHOR              => q{Breno G. de Oliveira <garu@cpan.org>},
    VERSION_FROM        => 'lib/Sub/Frequency.pm',
    ABSTRACT_FROM       => 'lib/Sub/Frequency.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'   => 0.90,
        'Scalar::Util' => 0,
        'Carp'         => 0,
        'parent'       => 0,
        'Exporter'     => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Sub-Frequency-*' },
);
