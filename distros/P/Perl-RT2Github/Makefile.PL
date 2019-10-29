use ExtUtils::MakeMaker;
use strict;
use warnings;
use Devel::CheckBin;
check_bin('git');

# Call 'perldoc ExtUtils::MakeMaker' for details of how to influence
# the contents of the Makefile that is written.

my %WriteMakefileArgs = (
    NAME                => 'Perl::RT2Github',
    VERSION_FROM        => 'lib/Perl/RT2Github.pm',
    AUTHOR              => 'James E Keenan (jkeenan@cpan.org)',
    ABSTRACT            => 'Given RT ticket number, find corresponding Github issue',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
        'Devel::CheckBin' => 0,
    },
    INSTALLDIRS         => ($] < 5.011 ? 'perl' : 'site'),
    PREREQ_PM           => {
        'HTTP::Tiny' => 0,
    },
    TEST_REQUIRES => {
        'Test::Simple' => 0.44,
    },
    ( eval { ExtUtils::MakeMaker->VERSION(6.46) } ? () : ( META_MERGE => {
        'meta-spec' => { version => 2 },
        dynamic_config => 1,
        resources => {
            homepage => 'http://thenceforward.net/perl/modules/Perl-RT2Github/',
            repository => {
                url => 'https://github.com/jkeenan/perl-rt2github.git',
                web => 'https://github.com/jkeenan/perl-rt2github',
                type => 'git',
            },
            bugtracker => {
                web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Perl-RT2Github',
            },
        },
    })),
);

my %FallbackPrereqs = (
    %{$WriteMakefileArgs{PREREQ_PM}},
    %{$WriteMakefileArgs{TEST_REQUIRES}},
);

unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);
