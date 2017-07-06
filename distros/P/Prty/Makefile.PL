    use 5.010000;
    use ExtUtils::MakeMaker;
    # See lib/ExtUtils/MakeMaker.pm for details of how to influence
    # the contents of the Makefile that is written.
    WriteMakefile(
        NAME => 'Prty',
        VERSION_FROM => 'lib/Prty.pm', # finds $VERSION
        PREREQ_PM => {
            DBD::SQLite => 0,
            DBI => 0,
            Data::Printer => 0,
            File::Rsync => 0,
            HTTP::Request => 0,
            Image::Size => 0,
            JSON => 0,
            LWP::UserAgent => 0,
            Pod::WSDL => 0,
            SOAP::Transport::HTTP => 0,
            WWW::Mechanize => 0,
            XML::LibXML => 0,
            XML::Twig => 0,
        }, # e.g., Module::Name => 1.1
        ABSTRACT_FROM => 'lib/Prty.pm', # retrieve abstract from module
        AUTHOR => 'Frank Seitz <fs@fseitz.de>',
        LICENSE => 'perl',
        # Value must be from legacy list of licenses here
        # http://search.cpan.org/perldoc?Module%3A%3ABuild%3A%3AAPI
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
                    url  => 'https://github.com/s31tz/Prty.git',
                    web  => 'https://github.com/s31tz/Prty',
                },
            },
        },
    );
