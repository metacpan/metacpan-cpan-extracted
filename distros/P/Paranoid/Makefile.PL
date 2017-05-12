use ExtUtils::MakeMaker;
use 5.008003;

# Required modules
my %reqMods = (
    'Carp'       => 0,
    'Errno'      => 0,
    'Fcntl'      => 0,
    'File::Glob' => 0,
    'POSIX'      => 0,
    );
my %optMods = (
    'Socket6'      => 0.23,
    );

# Create the makefile
WriteMakefile(
    NAME     => 'Paranoid',
    ABSTRACT => 'General function library for safer, more secure programming',
    AUTHOR   => 'Arthur Corliss <corliss@digitalmages.com>',
    VERSION_FROM => 'lib/Paranoid.pm',
    PREREQ_PM    => {%reqMods}, (
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
        COMPRESS  => 'gzip',
        SUFFIX    => '.gz',
        CI        => 'cvs ci',
        RCS_LABEL => 'cvs tag -c -F $(NAME_SYM)-$(VERSION_SYM)',
        },
        );

exit 0;
