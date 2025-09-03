use ExtUtils::MakeMaker;
use strict;
use warnings;
use Devel::CheckBin;
check_bin('git');
if ($^O =~ m/mswin32/i) {
    print STDERR "NA: Not yet tested on Windows\n";
    exit 0;
}

my $mm_ver = ExtUtils::MakeMaker->VERSION;

my %WriteMakefileArgs = (
    NAME                => 'Perl5::TestEachCommit',
    VERSION_FROM        => 'lib/Perl5/TestEachCommit.pm',
    AUTHOR              => 'James E Keenan (jkeenan@cpan.org)',
    ABSTRACT            => 'Test each commit in a pull request to Perl core',
    INSTALLDIRS         => ($] < 5.011 ? 'perl' : 'site'),
    MIN_PERL_VERSION    => '5.14.0',
    test                => {
        TESTS => ($ENV{PERL_AUTHOR_TESTING}
            ? "t/*.t xt/*.t"
            : "t/*.t")
    },
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
        'Devel::CheckBin' => 0,
    },
    PREREQ_PM           => {
        'Data::Dump' => 0,
        'Carp'      => 0,
        'File::Spec' => 0,
        'File::Spec::Unix' => 0,
        'Getopt::Long' => 0,
    },
    ( $mm_ver < 6.63_03 ? 'BUILD_REQUIRES' : 'TEST_REQUIRES' ) => {
        'Capture::Tiny' => 0,
        'String::PerlIdentifier' => 0.06,
        'Test::Simple' => 0.44,
     },
    LICENSE      => "perl",
    ($mm_ver < 6.46 ? () : (META_MERGE => {
        'meta-spec' => { version => 2 },
        dynamic_config => 1,
        resources => {
            homepage => 'http://thenceforward.net/perl/modules/Perl5-TestEachCommit/',
            repository => {
                url => 'https://github.com/jkeenan/perl5-test-each-commit.git',
                web => 'https://github.com/jkeenan/perl5-test-each-commit',
                type => 'git',
            },
            bugtracker => {
                web => 'https://github.com/jkeenan/perl5-test-each-commit/issues',
            },
        },
    })),
);

WriteMakefile(%WriteMakefileArgs);
