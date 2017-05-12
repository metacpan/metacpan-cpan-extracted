use strict;
use warnings;

use ExtUtils::MakeMaker 6.31;

my %WriteMakefileArgs = (
    'ABSTRACT' => 'provides method modifier for collecting method calls from roles and superclasses',
    'AUTHOR' => 'Alessandro Ranellucci <aar@cpan.org>',
    'BUILD_REQUIRES' => {
        'Moose' => '1.21',
        'Test::More' => '0.96',
        'Test::Deep' => '0',
    },
    'CONFIGURE_REQUIRES' => {
        'ExtUtils::MakeMaker' => '6.31'
    },
    'DISTNAME' => 'MooseX-Collect',
    'EXE_FILES' => [],
    'LICENSE' => 'perl',
    'NAME' => 'MooseX::Collect',
    'PREREQ_PM' => {
        'Moose' => '1.21',
    },
    'VERSION' => '0.92',
    'test' => {
        'TESTS' => 't/*.t'
    },
    'META_MERGE' => {
        resources => {
            repository => 'git://git@github.com:alexrj/MooseX-Collect.git',
        },
        no_index => {
            package => [qw(MooseX::Collect::Method)]
        },
    },
);

unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
    my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
    my $pp = $WriteMakefileArgs{PREREQ_PM};
    for my $mod (keys %$br) {
        if (exists $pp->{$mod}) {
            $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
        }
        else {
            $pp->{$mod} = $br->{$mod};
        }
    }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);
