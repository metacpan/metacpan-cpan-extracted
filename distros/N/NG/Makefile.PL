use 5.010;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'NG',
    AUTHOR           => q{chenryn <rao.chenlin@gmail.com>},
    VERSION_FROM     => 'lib/NG.pm',
    LICENSE          => 'Artistic_2_0',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.010,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
        'Test::Deep' => 0,
    },
    PREREQ_PM => {
        'autodie' => 0,
        'AnyEvent::HTTP' => 0,
        'File::Copy::Recursive' => 0,
        'Spreadsheet::ParseExcel' => 0,
        'Spreadsheet::WriteExcel' => 0,
        'HTML::Element' => '5.00',
        'HTML::TreeBuilder::XPath' => 0,
        'HTML::Selector::XPath' => 0,
        'Time::HiRes' => 0,
        'DBI' => 0,
        'SQL::Abstract' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'NG-*' },
);

