use 5.14.0;
use ExtUtils::MakeMaker;
use strict;
use warnings;

# Call 'perldoc ExtUtils::MakeMaker' for details of how to influence
# the contents of the Makefile that is written.

my %WriteMakefileArgs = (
    NAME                => 'Perl5::Dist::Backcompat',
    VERSION_FROM        => 'lib/Perl5/Dist/Backcompat.pm',
    AUTHOR              => 'James E Keenan (jkeenan@cpan.org)',
    ABSTRACT            => 'Will changes to dist/ build on older perls?',
    INSTALLDIRS         => ($] < 5.011 ? 'perl' : 'site'),
    EXE_FILES    => [ 'scripts/p5-dist-backcompat' ],
    PREREQ_PM           => {
        'Archive::Tar' => 0,
        'Capture::Tiny' => 0,
        'Carp' => 0,
        'Cwd' => 0,
        'File::Copy' => 0,
        'File::Find' => 0,
        'File::Spec' => 0,
        'File::Temp' => 0,
        'Getopt::Long' => 0,
        'Test::Simple' => 0.44,
        # From CPAN'
        'CPAN::DistnameInfo' => 0,
        'File::Copy::Recursive::Reduced' => 0,
        'Data::Dump' => 0,
    },
    ( eval { ExtUtils::MakeMaker->VERSION(6.46) } ? () : ( META_MERGE => {
        'meta-spec' => { version => 2 },
        dynamic_config => 1,
        resources => {
            homepage => 'http://thenceforward.net/perl/modules/Perl5-Dist-Backcompat/',
            repository => {
                url => 'https://github.com/jkeenan/p5-dist-backcompat.git',
                web => 'https://github.com/jkeenan/p5-dist-backcompat',
                type => 'git',
            },
#            bugtracker => {
#                web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Perl5-Dist-Backcompat',
#                mailto => 'bug-p5-dist-backcompat@rt.cpan.org',
#            },
        },
    })),
);

WriteMakefile(%WriteMakefileArgs);
