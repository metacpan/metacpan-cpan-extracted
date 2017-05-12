use ExtUtils::MakeMaker;
use 5.008003;

%reqMods = (
    'Class::EHierarchy' => 2.00,
    'Paranoid'          => 2.05,
    'URI'               => 0,
    'HTTP::Date'        => 0,
    );
%optMods = ();
%testMods = ( 'IO::File' => 0, );

WriteMakefile(
    NAME          => 'Net::ICAP',
    ABSTRACT_FROM => 'lib/Net/ICAP.pm',
    VERSION_FROM  => 'lib/Net/ICAP.pm',
    AUTHOR        => 'Arthur Corliss <corliss@digitalmages.com>',
    PREREQ_PM     => {%reqMods},
    TEST_REQUIRES => {%testMods}, (
        $ExtUtils::MakeMaker::VERSION ge '6.30_00'
        ? ( LICENSE  => 'perl',
            META_ADD => {
                'recommends' => {%optMods},
                'requires'   => {%reqMods} } )
        : ()
        ), (
        $ExtUtils::MakeMaker::VERSION ge '6.48'
        ? ( MIN_PERL_VERSION => 5.008003 )
        : ()
        ),
    dist => {
        COMPRESS => 'gzip',
        SUFFIX   => '.gz',
        },
        );

exit 0;
