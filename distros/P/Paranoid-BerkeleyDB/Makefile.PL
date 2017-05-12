use ExtUtils::MakeMaker;
use 5.008003;

# Required modules
my %reqMods = (
    'BerkeleyDB'        => 0.49,
    'Paranoid'          => 2.05,
    'Class::EHierarchy' => 2.00,
    'Cwd'               => 0,
    );

# Create the makefile
WriteMakefile(
    NAME         => 'Paranoid::BerkeleyDB',
    ABSTRACT     => 'BerkeleyDB CDS Support for Paranoid',
    AUTHOR       => 'Arthur Corliss <corliss@digitalmages.com>',
    VERSION_FROM => 'lib/Paranoid/BerkeleyDB.pm',
    PREREQ_PM    => {%reqMods}, (
        $ExtUtils::MakeMaker::VERSION ge '6.30_00'
        ? ( LICENSE  => 'perl',
            META_ADD => { 'requires' => {%reqMods} } )
        : ()
        ), (
        $ExtUtils::MakeMaker::VERSION ge '6.48'
        ? ( MIN_PERL_VERSION => 5.008003 )
        : ()
        ),
    dist => {
        COMPRESS  => 'gzip',
        SUFFIX    => '.gz',
        CI        => 'cvs ci',
        RCS_LABEL => 'cvs tag -c -F $(NAME_SYM)-$(VERSION_SYM)',
        },
        );

exit 0;
