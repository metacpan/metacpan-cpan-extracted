#!/usr/bin/perl

use Test::More (tests => 5);
use Data::Dumper;

use_ok('Monitoring::Livestatus::Class::Lite');

my @tests = (
    # normal query with 3 ands
    [
        state => { '='  => 1 },
        name  => { '!=' => [ qw/localhost router/] },
    ],
    [   "Filter: state = 1",
        "Filter: name != localhost",
        "Filter: name != router" 
    ],

    # simple or query
    {
        -or => [
          state => { '='  => 0 },
          state => { '='  => 1 },
        ]
    },
    [   "Filter: state = 0",
        "Filter: state = 1",
        "Or: 2",
    ],

    # normal or query
    [
        -or => [
          state => { '='  => 0 },
          state => { '='  => 1 },
        ],
        group => { '>=' => 'linux' }
    ],
    [   "Filter: state = 0",
        "Filter: state = 1",
        "Or: 2",
        "Filter: group >= linux",
    ],

    # cascaded query
    [
        -and => [
            -or => [
              state => { '='  => 0 },
              state => { '='  => 1 },
            ],
            group => { '>=' => 'linux' }
        ],
    ],
    [   "Filter: state = 0",
        "Filter: state = 1",
        "Or: 2",
        "Filter: group >= linux",
        "And: 2",
    ],

);

for ( my $i = 0 ; $i < scalar @tests ; $i++ ) {
    my $search            = $tests[$i];
    my $expected_statment = $tests[ ++$i ];
    my $got_statment;
    eval {
        $got_statment = Monitoring::Livestatus::Class::Lite->_apply_filter($search);
    } or  warn @_;
    is_deeply( $got_statment, $expected_statment, sprintf( "Test %d", ( $i / 2 ) + 1 ) )
        or diag("got: ".Dumper($got_statment)."\nbut expected ".Dumper($expected_statment));
}

