use strict;
use warnings;
use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
    NAME                => 'Net::Jabber::Bot',
    AUTHOR              => 'Todd E Rinaldo <toddr@cpan.org>',
    VERSION_FROM        => 'lib/Net/Jabber/Bot.pm',
    ABSTRACT_FROM       => 'lib/Net/Jabber/Bot.pm',
    LICENSE             => 'perl',
    MIN_PERL_VERSION    => '5.010',
    PL_FILES            => {},
    CONFIGURE_REQUIRES  => {
        'ExtUtils::MakeMaker' => '6.64',
    },
    PREREQ_PM => {
        'Log::Log4perl' => 0,
        'Moo'             => 2,
        'Type::Tiny'      => 1,
        'Types::Standard' => 0,
        'Mozilla::CA'   => 0,
        'Net::Jabber'   => 2.0,
        'Sys::Hostname'  => 0,
        'Time::HiRes'   => 0,
        'version'       => 0,
    },
    TEST_REQUIRES => {
        'FindBin'           => 0,
        'Test::More'        => 0,
        'Test::NoWarnings'  => 0,
        'lib'               => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Net-Jabber-Bot-*' },
    META_MERGE  => {
        'meta-spec' => { version => 2 },
        resources => {
            license    => ['https://dev.perl.org/licenses/'],
            homepage   => 'https://metacpan.org/pod/Net::Jabber::Bot',
            bugtracker => {
                web => 'https://github.com/cpan-authors/perl-net-jabber-bot/issues',
            },
            repository => {
                type => 'git',
                url  => 'https://github.com/cpan-authors/perl-net-jabber-bot.git',
                web  => 'https://github.com/cpan-authors/perl-net-jabber-bot',
            },
        },
    },
);

# Fallback for older EUMM without TEST_REQUIRES
unless (eval { ExtUtils::MakeMaker->VERSION('6.64') }) {
    $WriteMakefileArgs{PREREQ_PM} = {
        %{ $WriteMakefileArgs{PREREQ_PM} },
        %{ delete $WriteMakefileArgs{TEST_REQUIRES} },
    };
}

# Fallback for older EUMM without CONFIGURE_REQUIRES
unless (eval { ExtUtils::MakeMaker->VERSION('6.52') }) {
    delete $WriteMakefileArgs{CONFIGURE_REQUIRES};
}

# Fallback for older EUMM without MIN_PERL_VERSION
unless (eval { ExtUtils::MakeMaker->VERSION('6.48') }) {
    delete $WriteMakefileArgs{MIN_PERL_VERSION};
}

WriteMakefile(%WriteMakefileArgs);
