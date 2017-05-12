use 5.010;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'TSQL::Common::Regexp',
    AUTHOR              => q{Ded MedVed <dedmedved@cpan.org>},
    VERSION_FROM        => 'lib/TSQL/Common/Regexp.pm',
    ABSTRACT_FROM       => 'lib/TSQL/Common/Regexp.pm',
    MIN_PERL_VERSION    => 5.10.0,
    ($ExtUtils::MakeMaker::VERSION >= 6.48
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    EXE_FILES => [],
    PREREQ_PM => {
        'Test::More'                => 0,
        'Carp'                      => 0,
        'Clone'                     => 0,
        'IPC::System::Simple'       => 0, 
        'autodie'                   => 0,
        'indirect'                  => 0,
        'version'                   => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'TSQL-Common-Regexp-*' },
);



