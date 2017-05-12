use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Rose::DBx::Object::Indexed',
    AUTHOR              => 'Peter Karman <karman@cpan.org>',
    VERSION_FROM        => 'lib/Rose/DBx/Object/Indexed.pm',
    ABSTRACT_FROM       => 'lib/Rose/DBx/Object/Indexed.pm',
    LICENSE             => 'perl',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'SWISH::Prog' => '0.48',
        'Rose::DB::Object' => 0,
        'Rose::DBx::Object::MoreHelpers' => 0,
        'Class::C3'        => 0,
        'Scalar::Util'     => 0,
        'Rose::DBx::TestDB' => 0.05,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Rose-DBx-Object-Indexed-* t/test.index/ ' },
);
