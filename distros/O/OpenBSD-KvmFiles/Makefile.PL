use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'OpenBSD::KvmFiles',
    AUTHOR            => q{Dohnuts <dohnuts@no-reply.github.org>},
    LIBS              => ['-lkvm'], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '', # e.g., '-I. -I/usr/include/other'
    # XSMULTI           => 1,
    VERSION_FROM      => 'lib/OpenBSD/KvmFiles.pm',
    ABSTRACT_FROM     => 'lib/OpenBSD/KvmFiles.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'OpenBSD-KvmFiles-*' },
);
