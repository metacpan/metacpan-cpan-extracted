
use strict;
use warnings;

use 5.008;

use ExtUtils::MakeMaker 6.30;


my %WriteMakefileArgs = (
    NAME         => 'Redis::SQLite',
    VERSION_FROM => 'lib/Redis/SQLite.pm',
    PREREQ_PM    => {
                   'DBI'   => 0,
                   'DBD::SQLite'            => 0,
                 },

    BUILD_REQUIRES => {
        'Test::More'   => 0,
        'Test::Pod'    => 0,
        'Test::NoTabs' => 0,
    },

    ABSTRACT => 'Redis-compatible storage using SQLite on the back-end.',
    AUTHOR   => 'Steve Kemp <steve@steve.org.uk>',
    LICENSE  => "perl",

    MIN_PERL_VERSION => '5.008',

    META_MERGE => {
         resources => {
             license  => 'http://dev.perl.org/licenses/',
             homepage => 'https://github.com/skx/Redis--SQLite/',
             bugtracker =>
               'https://github.com/skx/Redis--SQLite/issues',
             repository =>
               'https://github.com/skx/Redis--SQLite.git',
             GitMirror =>
               'http://git.steve.org.uk/cpan/Redis--SQLite',
         },
    },
);



unless ( eval {ExtUtils::MakeMaker->VERSION(6.56)} )
{
    my $br = delete $WriteMakefileArgs{ BUILD_REQUIRES };
    my $pp = $WriteMakefileArgs{ PREREQ_PM };
    for my $mod ( keys %$br )
    {
        if ( exists $pp->{ $mod } )
        {
            $pp->{ $mod } = $br->{ $mod } if $br->{ $mod } > $pp->{ $mod };
        }
        else
        {
            $pp->{ $mod } = $br->{ $mod };
        }
    }
}

delete $WriteMakefileArgs{ CONFIGURE_REQUIRES }
  unless eval {ExtUtils::MakeMaker->VERSION(6.52)};

WriteMakefile(%WriteMakefileArgs);
