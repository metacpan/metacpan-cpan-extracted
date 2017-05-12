use ExtUtils::MakeMaker;
use 5.008;

# Required modules
my %reqMods = (
    'Paranoid'      => 2.0,
    'Net::SMTP'     => 0,
    'Net::Domain'   => 0,
    );

# Create the makefile
WriteMakefile(
    NAME     => 'Paranoid::Log::Email',
    ABSTRACT => 'SMTP support for Paranoid::Log',
    AUTHOR   => 'Arthur Corliss <corliss@digitalmages.com>',
    VERSION_FROM => 'lib/Paranoid/Log/Email.pm',
    PREREQ_PM    => {%reqMods}, (
        $ExtUtils::MakeMaker::VERSION ge '6.30_00'
        ? ( LICENSE  => 'perl',
            META_ADD => {
                'requires'   => {%reqMods} } )
        : ()
        ), (
        $ExtUtils::MakeMaker::VERSION ge '6.48'
        ? ( MIN_PERL_VERSION => 5.008 )
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
