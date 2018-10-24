use ExtUtils::MakeMaker;
use strict;
use warnings;

# Call 'perldoc ExtUtils::MakeMaker' for details of how to influence
# the contents of the Makefile that is written.

my $mm_ver = ExtUtils::MakeMaker->VERSION;

my %WriteMakefileArgs = (
    NAME                => 'Perl5::Build::Warnings',
    VERSION_FROM        => 'lib/Perl5/Build/Warnings.pm',
    AUTHOR              => 'James E Keenan (jkeenan@cpan.org)',
    ABSTRACT            => 'Parse make output for build-time warnings',
    INSTALLDIRS         => ($] < 5.011 ? 'perl' : 'site'),
    PREREQ_PM           => {},
    ( $mm_ver < 6.63_03 ? 'BUILD_REQUIRES' : 'TEST_REQUIRES' ) => {
        'Test::Simple' => 0.44,
        'Capture::Tiny' => 0,
    },
    ($mm_ver < 6.46 ? () : (META_MERGE => {
        'meta-spec' => { version => 2 },
        dynamic_config => 1,
        resources => {
            homepage => 'http://thenceforward.net/perl/modules/Perl5-Build-Warnings/',
            repository  => {
                url => 'https://github.com/jkeenan/perl5-build-warnings.git',
                web => 'https://github.com/jkeenan/perl5-build-warnings',
                type => 'git',
            },
            bugtracker => {
                web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Perl5-Build-Warnings',
            },
        },
    })),
);

WriteMakefile(%WriteMakefileArgs);
