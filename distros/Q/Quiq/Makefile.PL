use ExtUtils::MakeMaker;

WriteMakefile(
    NAME => 'Quiq',
    VERSION_FROM => 'lib/Quiq.pm',
    MIN_PERL_VERSION => 5.10.0,
    BUILD_REQUIRES => {
        ExtUtils::MakeMaker => 6.48, # wg. MIN_PERL_VERSION
    },
    PREREQ_PM => {
        Data::Printer => 0,
        DB_File => 0,
        DBD::SQLite => 0,
        DBI => 0,
        File::Rsync => 0.49,
        HTTP::Request => 0,
        Image::Size => 0,
        JSON => 0,
        LWP::UserAgent => 0,
        Mojolicious::Plugin => 0,
        Pod::WSDL => 0,
        SOAP::Transport::HTTP => 0,
        WWW::Mechanize => 0,
        XML::LibXML => 0,
        XML::Twig => 0,
    },
    ABSTRACT_FROM => 'lib/Quiq.pm',
    AUTHOR => 'Frank Seitz <fs@fseitz.de>',
    LICENSE => 'perl_5',
    test => {
        RECURSIVE_TEST_FILES => 1,
    },
    META_MERGE => {
        'meta-spec' => {
            version => 2,
        },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/s31tz/Quiq.git',
                web  => 'https://github.com/s31tz/Quiq',
            },
        },
    },
);

# eof
