
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Net::ACME2',
    AUTHOR       => 'Felipe Gasper',
    ABSTRACT_FROM => 'lib/Net/ACME2.pm',
    VERSION_FROM => 'lib/Net/ACME2.pm',
    LICENSE      => 'perl',
    MIN_PERL_VERSION => '5.14.0',

    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '6.64',
    },
    BUILD_REQUIRES => {
        'ExtUtils::MakeMaker' => '6.64',
    },

    PREREQ_PM    => {
        'autodie'                  => 0,
        'constant'                 => 1.23,
        'parent'                   => 0.225,
        'Call::Context'            => 0.02,
        'Crypt::Format'            => 0.06,
        'Crypt::Perl'              => 0.18,
        'CryptX'                   => 0,
        'HTTP::Tiny'               => 0.058,
        'HTTP::Tiny::UA::Response' => 0.004,
        'JSON'                     => 2.9,
        'MIME::Base64'             => 3.11,
        'Module::Runtime'          => 0,
        'Promise::ES6'             => 0,
        'X::Tiny'                  => 0.12,

        # We need SSL to speak ACME. There is no pure Perl
        # SSL implementation, so the following will bring in
        # Net::SSLeay, which requires XS. :-(
        'IO::Socket::SSL'          => 0,
    },

    TEST_REQUIRES => {
        'File::Slurp'     => 0,
        'Test::More'      => 1.0,
        'Test::Deep'      => 0,
        'Test::Exception' => 0.40,
        'Test::NoWarnings' => 0,
        'Test::FailWarnings' => 0,
        'HTTP::Status' => 0,
    },

    META_MERGE => {
        'meta-spec' => { version => 2 },

        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/cpan-authors/Net-ACME2.git',
                web  => 'https://github.com/cpan-authors/Net-ACME2',
            },
            bugtracker => {
                web => 'https://github.com/cpan-authors/Net-ACME2/issues',
            },
        },

        prereqs => {
            runtime => {
                recommends => {
                    'Net::Curl::Multi'    => 0,
                },
            },
        },

        provides => {
            'Net::ACME2' => {
                file    => 'lib/Net/ACME2.pm',
                version => MM->parse_version('lib/Net/ACME2.pm'),
            },
        },

        no_index => {
            directory => [ 't', 'examples' ],
        },
    },
);
