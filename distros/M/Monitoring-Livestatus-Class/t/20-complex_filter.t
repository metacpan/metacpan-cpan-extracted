#!perl -T

use Test::More;
use Data::Dumper;

use_ok('Monitoring::Livestatus::Class::Abstract::Filter');

my @testings = (
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

for ( my $i = 0 ; $i < scalar @testings ; $i++ ) {
    my $search            = $testings[$i];
    my $expected_statment = $testings[ ++$i ];
    my $filter_obj         = Monitoring::Livestatus::Class::Abstract::Filter->new();
    my $got_statment;
    eval {
        $got_statment = $filter_obj->apply($search);
    } or  warn @_;
    is_deeply( $got_statment, $expected_statment, sprintf( "Test %d", ( $i / 2 ) + 1 ) )
        or diag("got: ".Dumper($got_statment)."\nbut expected ".Dumper($expected_statment));
}

done_testing;
