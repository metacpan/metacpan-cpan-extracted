use 5.006002;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

my $lib_file = 'lib/Syntax/Construct.pm';

sub extract_version {
    open my $F, '<', $lib_file or die $!;
    while (<$F>) {
        return $1 if /^our \$VERSION = '(.*)'/;
    }
}

my %WriteMakefileArgs = (
    NAME             => 'Syntax::Construct',
    AUTHOR           => q{E. Choroba <choroba@cpan.org>},
    VERSION_FROM     => $lib_file,
    ABSTRACT_FROM    => $lib_file,
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => '5.006002',
    META_MERGE       => {
                        'meta-spec'    => { version => 2 },
                        dynamic_config => 0,
                        resources      => { repository => {
                                                  type => 'git',
                                                  url  => 'https://github.com/choroba/syntactic-construct.git',
                                                  web  => 'https://github.com/choroba/syntactic-construct',
                                               },
                                          },
                        provides  => { 'Syntax::Construct' => {
                                             file    => $lib_file,
                                             version => extract_version(),
                                          },
                                     },
                        },
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    TEST_REQUIRES => {
        'Test::More' => 0,
        'File::Spec' => 0,
        'FindBin'    => 0,
    },
    PREREQ_PM => {
        Config => 0,
        POSIX  => 0,
        locale => 0,
    },
    dist  => { COMPRESS => 'gzip -9f',
               SUFFIX   => 'gz',
               TAR => 'ptar' },
    clean => { FILES => 'Syntax-Construct-*' },
);

unless (eval { ExtUtils::MakeMaker->VERSION('6.64') }) {
    my $test_requires = delete $WriteMakefileArgs{TEST_REQUIRES};
    @{$WriteMakefileArgs{PREREQ_PM}}{keys %$test_requires} = values %$test_requires;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
    unless eval { ExtUtils::MakeMaker->VERSION('6.52') };

delete $WriteMakefileArgs{MIN_PERL_VERSION}
    unless eval { ExtUtils::MakeMaker->VERSION('6.48') };

delete $WriteMakefileArgs{LICENSE}
    unless eval { ExtUtils::MakeMaker->VERSION('6.31') };

WriteMakefile(%WriteMakefileArgs);
