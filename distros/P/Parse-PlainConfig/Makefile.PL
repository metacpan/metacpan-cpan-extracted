use ExtUtils::MakeMaker;
use 5.008003;

# Create the makefile
WriteMakefile(
    NAME         => 'Parse::PlainConfig',
    ABSTRACT     => 'Parser/Generator of human-readable conf files',
    AUTHOR       => 'Arthur Corliss <corliss@digitalmages.com>',
    VERSION_FROM => 'lib/Parse/PlainConfig.pm',
    PREREQ_PM    => {
        'Class::EHierarchy' => 2.00,
        'Paranoid'          => 2.05,
        'Text::ParseWords'  => 0,
        'Text::Tabs'        => 0,
        }, (
        $ExtUtils::MakeMaker::VERSION ge '6.30_00' ? ( LICENSE => 'perl', )
        : ()
        ), (
        $ExtUtils::MakeMaker::VERSION ge '6.48'
        ? ( MIN_PERL_VERSION => 5.008003 )
        : ()
        ),
        );

exit 0;

