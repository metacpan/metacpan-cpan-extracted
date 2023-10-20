use 5.012;
use warnings;
require ExtUtils::MakeMaker;

my $sc = 'https://codeberg.org/h3xx/perl-Term-DataMatrix';
my $bt = "$sc/issues";

my %writemakefileargs = (
    NAME               => 'Term::DataMatrix',
    AUTHOR             => 'Dan Church <h3xx [a] gmx <d> com>',
    VERSION_FROM       => 'lib/Term/DataMatrix.pm',
    ABSTRACT_FROM      => 'lib/Term/DataMatrix.pm',
    LICENSE            => 'perl',
    MIN_PERL_VERSION   => '5.012',
    CONFIGURE_REQUIRES => {qw(
        ExtUtils::MakeMaker 0
    )},
    TEST_REQUIRES => {qw(
        List::Util 0
        Term::ANSIColor 2.01
        Test::More 0
    )},
    PREREQ_PM => {qw(
        Barcode::DataMatrix 0
        Carp 0
        Term::ANSIColor 0
        fields 0
    )},
    EXE_FILES => [
        'term-datamatrix',
    ],
    PL_FILES => {
        'term-datamatrix.PL' => 'term-datamatrix',
    },
    clean => { FILES => [
        'term-datamatrix',
    ] },
    MAN1PODS => {
        'doc/term-datamatrix.pod' => 'blib/man1/term-datamatrix.1',
    },
    test => {
        TESTS => 't/*.t xt/*.t',
    },
    META_ADD => {
        'meta-spec' => { version => 2 },
        resources   => {
            bugtracker => { web => $bt },
            license    => [ 'https://dev.perl.org/licenses/' ],
            repository => { type => 'git', url => "$sc.git", web => $sc },
        },
    },
);

# Compatibility with old versions of ExtUtils::MakeMaker
unless (_mm_ver_atleast('6.64')) {
    my $test_requires = delete $writemakefileargs{TEST_REQUIRES} || {};
    @{$writemakefileargs{PREREQ_PM}}{keys %{$test_requires}} = values %{$test_requires};
}

unless (_mm_ver_atleast('6.55_03')) {
    my $build_requires = delete $writemakefileargs{BUILD_REQUIRES} || {};
    @{$writemakefileargs{PREREQ_PM}}{keys %{$build_requires}} = values %{$build_requires};
}

unless (_mm_ver_atleast('6.52')) {
    delete $writemakefileargs{CONFIGURE_REQUIRES};
}
unless (_mm_ver_atleast('6.48')) {
    delete $writemakefileargs{MIN_PERL_VERSION};
}
unless (_mm_ver_atleast('6.31')) {
    delete $writemakefileargs{LICENSE};
}

ExtUtils::MakeMaker::WriteMakefile(%writemakefileargs);

sub _mm_ver_atleast {
    my $ver = shift;
    return eval { ExtUtils::MakeMaker->VERSION($ver); 1 };
}
