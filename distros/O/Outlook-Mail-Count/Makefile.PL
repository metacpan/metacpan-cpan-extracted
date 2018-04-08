use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Outlook::Mail::Count',
    AUTHOR           => q{Linus Yuan <yuan_shijiang@163.com>},
    VERSION_FROM     => 'lib/Outlook/Mail/Count.pm',
    ABSTRACT_FROM    => 'lib/Outlook/Mail/Count.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => '5.006',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    BUILD_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {
        #'ABC'              => '1.6',
        #'Foo::Bar::Module' => '5.0401',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Outlook-Mail-Count-*' },
);
