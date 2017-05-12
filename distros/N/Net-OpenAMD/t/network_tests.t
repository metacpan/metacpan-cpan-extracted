#!perl
package NetworkTests;

# $AFresh1: network_tests.t,v 1.15 2010/07/17 12:10:48 andrew Exp $

use strict;
use warnings;

use Test::More;
use Test::Deep;
use Net::OpenAMD;

#use Data::Dumper;

if ( !caller() ) {
    if ( $ENV{'NETWORK_TESTS'} ) {
        plan tests => 14;
    }
    else {
        plan skip_all =>
            'Network test.  Set $ENV{NETWORK_TESTS} to a true value to run.';
    }

    my $amd = Net::OpenAMD->new();
    run_tests($amd);

    #done_testing();
}

1;

sub run_tests {
    my ($amd) = @_;

    my @interests = (
        "new tech",           "activism",
        "radio",              "lockpicking",
        "crypto",             "privacy",
        "ethics",             "telephones",
        "social engineering", "hacker spaces",
        "hardware hacking",   "nostalgia",
        "communities",        "science",
        "government",         "network security",
        "malicious software", "pen testing",
        "web",                "niche hacks",
        "media"
    );
    my %cmp = (
        single_line   => re('^[^\n]+$'),
        multi_line    => re('(?xms:^.*$)'),
        digits        => re('^\d+$'),
        track         => any( 'Lovelace', 'Tesla', 'Bell', 'Hooper' ),
        area          => any('Engressia'),
        interests     => any(@interests),
        all_interests => bag(@interests),
        coordinate    => re('^\d{1,2}\.\d+$'),
        boolean => any( 'True', 'False' ),
    );

    $cmp{user} = [
        $cmp{single_line},
        superhashof(
            {   name => $cmp{single_line},

                #interests => array_each( $cmp{interests} ),
                #x         => $cmp{coordinate},
                #y         => $cmp{coordinate},
            }
        ),
    ];

    $cmp{speaker} = [
        $cmp{single_line},
        {   name => $cmp{single_line},
            bio  => $cmp{multi_line},
        }
    ];

    $cmp{location} = superhashof(
        {   #area => $cmp{area},
            user => $cmp{single_line},

            #button => $cmp{boolean},
            x => $cmp{coordinate},
            y => $cmp{coordinate},

            #time   => $cmp{single_line},
        }
    );

    my %tests = (
        location => [
            {   args   => undef,
                expect => array_each( $cmp{location} ),
            },
            {   args   => { user => 'user0' },
                expect => qr/^Invalid \s JSON|$/xms,
            },
            {   args   => { user => 'user0', limit => 5 },
                expect => qr/^Invalid \s JSON|$/xms,
            },
            {   args   => { area => 'Lovelace' },
                expect => array_each( $cmp{location} ),
            },
        ],
        speakers => [
            {   args   => undef,
                expect => array_each( $cmp{speaker} ),
            },
            {   args => { name => 'The Cheshire Catalyst' },
                expect => array_each( $cmp{speaker} ),
            },
        ],
        talks => [
            {   args   => undef,
                expect => array_each(
                    {   abstract => $cmp{multi_line},
                        speakers => array_each( $cmp{single_line} ),
                        time     => $cmp{single_line},
                        title    => $cmp{single_line},
                        track    => $cmp{track},
                    }
                ),
            },
            {   args   => { interests => 'lockpicking' },
                expect => array_each(
                    {   abstract => $cmp{multi_line},
                        speakers => array_each( $cmp{single_line} ),
                        time     => $cmp{single_line},
                        title    => $cmp{single_line},
                        track    => $cmp{track},

                        # interests => 'lockpicking',
                    }
                ),
            },
        ],
        interests => [
            {   args   => undef,
                expect => $cmp{all_interests},
            },
        ],
        users => [
            {   args   => undef,
                expect => array_each( $cmp{user} ),
            },
            {   args   => { user => 'user0' },
                expect => array_each( $cmp{user} ),
            },
            {   args   => { user => 'user0', limit => 20 },
                expect => array_each( $cmp{user} ),
            },
            {   args   => { interests => 'lockpicking' },
                expect => array_each( $cmp{user} ),
            },
        ],
        stats => [
            {   args   => undef,
                expect => qr/^Unused \s feature/xms,
            },
        ],
    );

    foreach my $method ( keys %tests ) {
        foreach my $test ( @{ $tests{$method} } ) {
            no warnings 'uninitialized';
            my $result;
            eval { $result = $amd->$method( $test->{args} ) };
            if ( ref $test->{expect} eq 'Regexp' ) {
                like( $@, $test->{expect}, "AMD->$method($test->{args})" );
            }
            elsif ( ref $test->{expect} ) {
                if ($@) {
                    is( $@, '', "AMD->$method($test->{args})" );
                }
                else {
                    cmp_deeply( $result, $test->{expect},
                              "AMD->$method($test->{args}) - "
                            . 'got expected result' );
                }
            }
            else {
                is( $@, $test->{expect}, "AMD->$method($test->{args})" );
            }
        }
    }
}
