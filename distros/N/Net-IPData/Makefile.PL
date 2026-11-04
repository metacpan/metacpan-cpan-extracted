use strict;
use warnings;
use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
    NAME             => 'Net::IPData',
    VERSION_FROM     => 'lib/Net/IPData.pm',
    ABSTRACT_FROM    => 'lib/Net/IPData.pm',
    AUTHOR           => 'Net::IPData contributors',
    LICENSE          => 'perl_5',
    MIN_PERL_VERSION => '5.010001',
    PREREQ_PM        => {
        'HTTP::Tiny'   => '0.049',    # core since 5.14; 0.049+ for fork/thread-safe keep-alive
        'JSON::PP'     => '2.27',     # core since 5.14
        'Carp'         => '0',
        'Scalar::Util' => '0',
    },
    TEST_REQUIRES => {
        'Test::More' => '0.96',
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            homepage   => 'https://ipdata.co/',
            repository => {
                type => 'git',
                url  => 'https://github.com/ipdata/perl.git',
                web  => 'https://github.com/ipdata/perl',
            },
            bugtracker => {
                web => 'https://github.com/ipdata/perl/issues',
            },
        },
        prereqs => {
            runtime => {
                recommends => {
                    'IO::Socket::SSL' => '1.56',
                    'Net::SSLeay'     => '1.49',
                },
            },
        },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
    clean => { FILES    => 'Net-IPData-*' },
);

# ExtUtils::MakeMaker before 6.64 does not know TEST_REQUIRES, and before
# 6.68 it cannot express a meta-spec 2 META_MERGE: it writes a MYMETA that
# claims version 2 but keeps the 1.4 layout, so CPAN::Meta drops the
# prerequisites and "cpanm --installdeps ." installs nothing (seen with the
# MakeMaker bundled with Perl 5.14). Fall back to what those versions know.
unless (eval { ExtUtils::MakeMaker->VERSION('6.64') }) {
    my $test_requires = delete $WriteMakefileArgs{TEST_REQUIRES};
    $WriteMakefileArgs{PREREQ_PM} = { %{ $WriteMakefileArgs{PREREQ_PM} }, %$test_requires };
}
unless (eval { ExtUtils::MakeMaker->VERSION('6.68') }) {
    delete $WriteMakefileArgs{META_MERGE};
}

WriteMakefile(%WriteMakefileArgs);
