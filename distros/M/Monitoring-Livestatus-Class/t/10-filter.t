#!perl

use Test::More;

use_ok('Monitoring::Livestatus::Class::Abstract::Filter');

my @testings = (
    [[]], [],
    [[{ name => undef }], { name => 'localhost' }, []], ["Filter: name =", "Filter: name = localhost"],
    { name => undef }, ["Filter: name ="],
    { name => 'localhost' }, ["Filter: name = localhost"],
    [ name => 'localhost', service => 'ping' ], [ "Filter: name = localhost", "Filter: service = ping" ],
    { name => [qw/localhost router/] }, [ "Filter: name = localhost", "Filter: name = router" ],
    [
        { name => 'localhost' },
        { name => 'router' },
    ], [ "Filter: name = localhost", "Filter: name = router" ],
    # not supported at the moment
    { name => { '-or' => [ qw/localhost router/] } },[ "Filter: name = localhost", "Filter: name = router", "Or: 2" ],
    { '-or' => [
            scheduled_downtime_depth => { '>' => '0' },
            host_scheduled_downtime_depth => { '>' => '0'},
        ]
    },['Filter: scheduled_downtime_depth > 0','Filter: host_scheduled_downtime_depth > 0','Or: 2'],
    {
        '-or' => [
            '-and' => [ acknowledged => '1', state => '2'],
            state => '0',
        ]
    }
    ,['Filter: acknowledged = 1', 'Filter: state = 2', 'And: 2', 'Filter: state = 0', 'Or: 2'],
    {
        '-or' => [
            { host_has_been_checked => 0, },
            {
                '-and' => [
                    host_state            => 1,
                    host_has_been_checked => 1,
                ]
            },
            {
                '-and' => [
                    host_state            => 2,
                    host_has_been_checked => 1,
                ]
            },
        ]
    }
    ,['Filter: host_has_been_checked = 0','Filter: host_state = 1','Filter: host_has_been_checked = 1','And: 2','Filter: host_state = 2','Filter: host_has_been_checked = 1','And: 2','Or: 3',],
    [
        '-or' => [
            { host_has_been_checked => 0, },
            {
                '-and' => [
                    host_state            => 1,
                    host_has_been_checked => 1,
                ]
            },
            {
                '-and' => [
                    host_state            => 3,
                    host_has_been_checked => 1,
                ]
            },
        ],
        '-and' => [
            scheduled_downtime_depth => { '>' => '0' },
            scheduled_downtime_depth => 0,
            acknowledged => [qw/0 1/],
            checks_enabled => [qw/0 1/],
            event_handler_enabled   => [qw/0 1/],
            flap_detection_enabled => [qw/0 1/],
            is_flapping => [qw/0 1/],
            notifications_enabled => [qw/0 1/],
            accept_passive_checks => [qw/0 1/],
        ]
    ],[
        'Filter: host_has_been_checked = 0',
        'Filter: host_state = 1',
        'Filter: host_has_been_checked = 1',
        'And: 2',
        'Filter: host_state = 3',
        'Filter: host_has_been_checked = 1',
        'And: 2',
        'Or: 3',
        'Filter: scheduled_downtime_depth > 0',
        'Filter: scheduled_downtime_depth = 0',
        'Filter: acknowledged = 0',
        'Filter: acknowledged = 1',
        'Filter: checks_enabled = 0',
        'Filter: checks_enabled = 1',
        'Filter: event_handler_enabled = 0',
        'Filter: event_handler_enabled = 1',
        'Filter: flap_detection_enabled = 0',
        'Filter: flap_detection_enabled = 1',
        'Filter: is_flapping = 0',
        'Filter: is_flapping = 1',
        'Filter: notifications_enabled = 0',
        'Filter: notifications_enabled = 1',
        'Filter: accept_passive_checks = 0',
        'Filter: accept_passive_checks = 1',
        'And: 16'
        ],
    # Simple operator tests
    { name => { '=' => [ qw/localhost router/] } },[ "Filter: name = localhost", "Filter: name = router" ],
    { name => { '~' => [ qw/localhost router/] } },[ "Filter: name ~ localhost", "Filter: name ~ router" ],
    { name => { '~=' => [ qw/localhost router/] } },[ "Filter: name ~= localhost", "Filter: name ~= router" ],
    { name => { '~~' => [ qw/localhost router/] } },[ "Filter: name ~~ localhost", "Filter: name ~~ router" ],
    { name => { '<' => [ qw/localhost router/] } },[ "Filter: name < localhost", "Filter: name < router" ],
    { name => { '>' => [ qw/localhost router/] } },[ "Filter: name > localhost", "Filter: name > router" ],
    { name => { '<=' => [ qw/localhost router/] } },[ "Filter: name <= localhost", "Filter: name <= router" ],
    { name => { '>=' => [ qw/localhost router/] } },[ "Filter: name >= localhost", "Filter: name >= router" ],
    { host_scheduled_downtime_depth => { '>' => 0 } },[ "Filter: host_scheduled_downtime_depth > 0" ],
);

for ( my $i = 0 ; $i < scalar @testings ; $i++ ) {
    my $search            = $testings[$i];
    my $expected_statment = $testings[ ++$i ];
    my $filter_obj        = Monitoring::Livestatus::Class::Abstract::Filter->new();
    my $got_statment;
    eval {
        $got_statment = $filter_obj->apply($search);
    } or  warn @_;
    is_deeply( $got_statment, $expected_statment,
        sprintf( "Test %d - %s", ( $i / 2 ) + 1 , join " ",@{ $expected_statment } ));
}

done_testing;
