use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Parse::Log::Smbd',
    AUTHOR              => q{Ari Constancio <affc@cpan.org>},
    VERSION_FROM        => 'lib/Parse/Log/Smbd.pm',
    ABSTRACT_FROM       => 'lib/Parse/Log/Smbd.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
	'IO::File' => 0,
	'Carp' => 0,
	'Devel::CheckOS' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Parse-Log-Smbd-*' },
);
