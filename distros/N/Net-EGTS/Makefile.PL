use ExtUtils::MakeMaker;

WriteMakefile(
    NAME            => "Net::EGTS",
    VERSION_FROM    => "lib/Net/EGTS.pm",
    ABSTRACT_FROM   => "lib/Net/EGTS.pm",
    MAKEFILE        => 'Makefile',
    LICENSE         => 'Perl',
    AUTHOR          => [
        'Dmitry E. Oboukhov <unera@debian.org>,',
        'Roman V. Nikolaev <rshadow@rambler.ru>',
    ],
    MIN_PERL_VERSION => '5.10.0',
    PREREQ_PM       => {
        'Carp'                          => '0',
        'IO::Socket::INET'              => '0',
        'Mouse'                         => '0',
        'Digest::CRC'                   => '0',
        'Date::Parse'                   => '0',
        'List::MoreUtils'               => '0',
        'Encode'                        => '0',
        'POSIX'                         => '0',
        'namespace::autoclean'          => '0',
    },
    TEST_REQUIRES   => {
        'Test::Compile'                 => '0',
        'Test::More'                    => '0',
    },
    META_MERGE      => {
        resources   => {
            homepage    =>
                'https://github.com/dr-co/Net-EGTS',
            repository  =>
                'https://github.com/dr-co/Net-EGTS',
            bugtracker  =>
                'https://github.com/dr-co/Net-EGTS/issues',
        }
   },
);
