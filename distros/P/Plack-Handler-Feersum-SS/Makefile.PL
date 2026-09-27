use strict;
use warnings;
use 5.010;
use ExtUtils::MakeMaker;

my %args = (
    NAME             => 'Plack::Handler::Feersum::SS',
    VERSION_FROM     => 'lib/Plack/Handler/Feersum/SS.pm',
    ABSTRACT_FROM    => 'lib/Plack/Handler/Feersum/SS.pod',
    AUTHOR           => 'Yegor Korablev <egor@cpan.org>',
    LICENSE          => 'perl',
    MIN_PERL_VERSION => '5.010',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    PREREQ_PM => {
        'Carp'                    => 0,
        'Fcntl'                   => 0,
        'Feersum'                 => 0,
        'Plack::Handler::Feersum' => 0,
        'Server::Starter'         => 0,
        'Symbol'                  => 0,
        'base'                    => 0,
        'constant'                => 0,
    },
    TEST_REQUIRES => {
        'File::Temp'       => 0,
        'IO::Socket::INET' => 0,
        'Plack::Runner'    => 0,
        'Test::More'       => 0,
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/vividsnow/Plack-Handler-Feersum-SS.git',
                web  => 'https://github.com/vividsnow/Plack-Handler-Feersum-SS',
            },
            bugtracker => {
                web => 'https://github.com/vividsnow/Plack-Handler-Feersum-SS/issues',
            },
        },
    },
);
unless (eval { ExtUtils::MakeMaker->VERSION('6.64') }) {
    my $test = delete $args{TEST_REQUIRES};
    $args{PREREQ_PM} = { %{ $args{PREREQ_PM} }, %$test };
}
WriteMakefile(%args);
