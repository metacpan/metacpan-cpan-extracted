
use Test::More;
use OpenSearch::Client;

my $cli = OpenSearch::Client->new;

test_parse_request(
    'get or post on body gives get',
    $cli,
    {
        body    => {},
        method  => 'detect',
        detect  => { method => 'GET', alternate => 'POST', check => { body => 1, paths => 0 } },
        parts   => { index => {}},
        paths   => [
            [ { index => 3 }, "_plugins", "_ism", "explain", "{index}" ],
            [ {}, "_plugins", "_ism", "explain" ]
        ],
        qs      => {},
    },
    {
        index => 'myindex',
    },
    'GET',
);

test_parse_request(
    'get or post on body gives post',
    $cli,
    {
        body    => {},
        method  => 'detect',
        detect  => { method => 'GET', alternate => 'POST', check => { body => 1, paths => 0 } },
        parts   => { index => {}},
        paths   => [
            [ { index => 3 }, "_plugins", "_ism", "explain", "{index}" ],
            [ {}, "_plugins", "_ism", "explain" ]
        ],
        qs      => {},
    },
    {
        body  => { something => 'here'},
        index => 'myindex',
    },
    'POST',
);

test_parse_request(
    'get or post on paths gives get',
    $cli,
    {
        body    => {},
        method  => 'detect',
        detect  => { method => 'GET', alternate => 'POST', check => { body => 0, paths => 1 } },
        parts   => { index => {}, dummy => { required => 1 }},
        paths   => [
            [ { dummy => 3, index => 4 }, "_some", "_random", "path", "{dummy}", "{index}" ],
            [ { dummy => 3 }, "_some", "_random", "path", "{dummy}" ]
        ],
        qs      => {},
    },
    {
        dummy => 'true',
        body  => { something => 'here'},
    },
    'GET',
);

test_parse_request(
    'get or post on paths gives post',
    $cli,
    {
        body    => {},
        method  => 'detect',
        detect  => { method => 'GET', alternate => 'POST', check => { body => 0, paths => 1 } },
        parts   => { index => {}, dummy => { required => 1 }},
        paths   => [
            [ { dummy => 3, index => 4 }, "_some", "_random", "path", "{dummy}", "{index}" ],
            [ { dummy => 3 }, "_some", "_random", "path", "{dummy}" ]
        ],
        qs      => {},
    },
    {
        dummy => 'true',
        index => 'myindex',
        body  => { something => 'here'},
    },
    'POST',
);

test_parse_request(
    'post or put on paths gives post',
    $cli,
    {
        body    => {},
        method  => 'detect',
        detect  => { method => 'POST', alternate => 'PUT', check => { body => 0, paths => 1 } },
        parts   => { id => {}, index => {  required => 1 }},
        paths   => [
            [ { index => 0, id => 2 }, "{index}", "_doc", "{id}" ],
            [ { index => 0 }, "{index}", "_doc" ]
        ],
        qs      => {}
    },
    {
        index => 'myindex',
    },
    'POST'
);

test_parse_request(
    'post or put on paths gives put',
    $cli,
    {
        body    => {},
        method  => 'detect',
        detect  => { method => 'POST', alternate => 'PUT', check => { body => 0, paths => 1 } },
        parts   => { id => {}, index => {  required => 1 }},
        paths   => [
            [ { index => 0, id => 2 }, "{index}", "_doc", "{id}" ],
            [ { index => 0 }, "{index}", "_doc" ]
        ],
        qs      => {}
    },
    {
        index => 'myindex',
        id    => 1
    },
    'PUT',
);

test_parse_request(
    'post or put on body gives post',
    $cli,
    {
        body    => {},
        method  => 'detect',
        detect  => { method => 'POST', alternate => 'PUT', check => { body => 1, paths => 0 } },
        parts   => { repository => {  required => 1 }, snapshot => {  required => 1 }},
        paths   => [[ { repository => 1, snapshot => 2 }, "_snapshot", "{repository}", "{snapshot}" ]],
        qs      => {},
    },
    {
        repository => 'myrepo',
        snapshot   => 'mysnapshot',
    },
    'POST',
);

test_parse_request(
    'post or put on body gives put',
    $cli,
    {
        body    => {},
        method  => 'detect',
        detect  => { method => 'POST', alternate => 'PUT', check => { body => 1, paths => 0 } },
        parts   => { repository => {  required => 1 }, snapshot => {  required => 1 }},
        paths   => [[ { repository => 1, snapshot => 2 }, "_snapshot", "{repository}", "{snapshot}" ]],
        qs      => {},
    },
    {
        body       => { something => 'here'},
        repository => 'myrepo',
        snapshot   => 'mysnapshot',
    },
    'PUT',
);

sub test_parse_request {
    my( $tname, $os, $def, $params, $expected_method ) = @_;
    my $request = $os->parse_request($def, $params);
    is($request->{method}, $expected_method, $tname );
}


done_testing;
