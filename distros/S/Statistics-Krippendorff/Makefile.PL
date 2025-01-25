use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my $lib_file = 'lib/Statistics/Krippendorff.pm';
sub extract_version {
    open my $F, '<', $lib_file or die $!;
    /^our \$VERSION = '(.*)'/ and return $1 while <$F>;
}

my %WriteMakefileArgs = (
    NAME             => 'Statistics::Krippendorff',
    AUTHOR           => q{E. Choroba <choroba@cpan.org>},
    VERSION_FROM     => 'lib/Statistics/Krippendorff.pm',
    ABSTRACT_FROM    => 'lib/Statistics/Krippendorff.pm',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.026',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    TEST_REQUIRES => {
        'Test2::V0' => '0',
        'FindBin' => 0,
    },
    PREREQ_PM => {
        'Moo' => 0,
        'namespace::clean' => 0,
        'List::Util' => 0,
        'strict' => 0,
        'warnings' => 0,
        'experimental' => 0,
    },
    META_MERGE => {
        'meta-spec' => {version => 2},
        dynamic_config => 0,
        resources => {repository => {
            type => 'git',
            url => 'https://github.com/choroba/statistics-krippendorff.git',
            web => 'https://github.com/choroba/statistics-krippendorff'}},
        provides => { 'Statistics::Krippendorff' => {
            file => $lib_file,
            version => extract_version()}}},
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', TAR => 'ptar'},
    clean => { FILES => 'Statistics-Krippendorff-*' },
);

# Compatibility with old versions of ExtUtils::MakeMaker
unless (eval { ExtUtils::MakeMaker->VERSION('6.64'); 1 }) {
    my $test_requires = delete $WriteMakefileArgs{TEST_REQUIRES} || {};
    @{$WriteMakefileArgs{PREREQ_PM}}{keys %$test_requires} = values %$test_requires;
}

unless (eval { ExtUtils::MakeMaker->VERSION('6.55_03'); 1 }) {
    my $build_requires = delete $WriteMakefileArgs{BUILD_REQUIRES} || {};
    @{$WriteMakefileArgs{PREREQ_PM}}{keys %$build_requires} = values %$build_requires;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
    unless eval { ExtUtils::MakeMaker->VERSION('6.52'); 1 };
delete $WriteMakefileArgs{MIN_PERL_VERSION}
    unless eval { ExtUtils::MakeMaker->VERSION('6.48'); 1 };
delete $WriteMakefileArgs{LICENSE}
    unless eval { ExtUtils::MakeMaker->VERSION('6.31'); 1 };

WriteMakefile(%WriteMakefileArgs);
