use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Sub::Pipe',
    AUTHOR              => 'FUJIWARA Shunichiro <fujiwara@cpan.org>',
    VERSION_FROM        => 'lib/Sub/Pipe.pm',
    ABSTRACT_FROM       => 'lib/Sub/Pipe.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Sub-Pipe-*' },
);
