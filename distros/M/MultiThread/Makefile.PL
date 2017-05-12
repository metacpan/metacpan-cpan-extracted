use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'MultiThread',
    AUTHOR              => 'David Spadea <dspadea@cpan.org>',
    VERSION_FROM        => 'lib/MultiThread.pm',
    ABSTRACT_FROM       => 'lib/MultiThread.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Sys::CPU' => '0.40',
        'threads' => 0,
        'Storable' => 0
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'MultiThread-*' },
);
