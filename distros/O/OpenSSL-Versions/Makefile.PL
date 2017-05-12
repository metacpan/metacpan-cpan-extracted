use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'OpenSSL::Versions',
    AUTHOR              => q{A. Sinan Unur <nanis@cpan.org>},
    VERSION_FROM        => 'lib/OpenSSL/Versions.pm',
    ABSTRACT_FROM       => 'lib/OpenSSL/Versions.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    BUILD_REQUIRES      => {
        'Test::More' => '0.88',
    },
    PREREQ_PM => {
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'OpenSSL-Versions-*' },
);

