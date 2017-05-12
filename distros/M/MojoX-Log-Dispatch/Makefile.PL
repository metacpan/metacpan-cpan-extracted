use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'MojoX::Log::Dispatch',
    AUTHOR              => 'Konstantin Kapitanov <perlovik@gmail.com>',
    VERSION_FROM        => 'lib/MojoX/Log/Dispatch.pm',
    ABSTRACT_FROM       => 'lib/MojoX/Log/Dispatch.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Log::Dispatch' => 2.22,
        'Mojo'			=> 0.991250
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'MojoX-Log-Dispatch-*' },
);
