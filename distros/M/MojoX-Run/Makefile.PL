use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'MojoX::Run',
    AUTHOR              => q{"Brane F. Gracnar" <"bfg@frost.ath.cx">},
    VERSION_FROM        => 'lib/MojoX/Run.pm',
    ABSTRACT_FROM       => 'lib/MojoX/Run.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'  => 0,
        'Mojolicious' => 0.999940,
        'Storable'    => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'MojoX-Run-*' },
);
