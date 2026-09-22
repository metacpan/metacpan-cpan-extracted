use v5.36;
use warnings FATAL => 'all';
use re '/aa';

=head1 NAME

t/SolusVM-Client.t - SolusVM::Client: the generated methods, and the token behind them

=cut

use Test2::V1 -i;
use Test2::Plugin::NoWarnings;

use Cpanel::JSON::XS ();
use File::Spec       ();
use File::Temp       ();

use FindBin::libs;
use Test::SolusVM::Client qw{:all};

use SolusVM::Client                ();
use SolusVM::Client::Specification ();

my $HOST = 'solus.test';
my $BASE = "https://$HOST/api/v1";

sub client (%options) {
    return SolusVM::Client->new( host => $HOST, token => 'a-token', %options );
}

subtest 'new' => sub {
    like( dies { SolusVM::Client->new( token => 'a-token' ) }, qr/needs the host/,                            'a client with no management node is refused' );
    like( dies { SolusVM::Client->new( host  => $HOST ) },     qr/either a token, or the email and password/, 'and one with no way to authenticate is too' );

    ok( SolusVM::Client->new( host => $HOST, token => 'a-token' ), 'a token is enough' );
    ok( SolusVM::Client->new( host => $HOST, email => 'you@example.test', password => 'x' ), 'so are credentials' );

    is( client()->host,                                            $HOST,                       'it remembers its host' );
    is( client()->base_url,                                        $BASE,                       'and hangs the API off it' );
    is( client( port => 8443 )->base_url,                          "https://$HOST:8443/api/v1", 'a port goes where a port goes' );
    is( client( scheme => 'http', prefix => '/api/v2' )->base_url, "http://$HOST/api/v2",       'and both halves can be said otherwise' );
};

subtest 'the generated methods' => sub {
    my $spec  = SolusVM::Client::Specification::load();
    my $solus = client();

    my @missing = grep { !$solus->can($_) } keys %{$spec};
    is( \@missing, [], 'every operation in the spec is a method' );

    my @shadowed = grep { exists $spec->{$_} } @SolusVM::Client::RESERVED;
    is( \@shadowed, [], 'and none of them is named after a method this class defines itself' );

    my @both = grep { $_->{has_body} && @{ $_->{query_params} } } values %{$spec};
    is( \@both, [], 'no operation takes both a body and a query string, which is what lets arguments be sorted without being told' );
};

subtest 'catalog' => sub {
    my $listing = client()->catalog( like => qr/snapshot/ );

    like( $listing, qr{get_list_of_server_snapshots\s+GET\s+\Q/servers/{id}/snapshots\E}, 'it says the verb and the path' );
    unlike( $listing, qr/get_list_of_servers\s/, 'and leaves out what was not asked for' );

    like( client()->catalog( like => qr/create_a_new_project_server/ ), qr/body:\s+.*\bplan_id[*]/, 'and what a body takes, with the required ones starred' );

    my @lines = split "\n", client()->catalog();
    ok( scalar @lines > 309, 'the whole catalog is all of it, summaries and all' );
};

subtest 'path parameters' => sub {
    my $mock = mock_http_tiny();
    mock_request( 'GET /api/v1/servers/42', json_response( { data => { id => 42 } } ) );

    my $answer = client()->get_an_existing_server( id => 42 );
    is( last_http_request(), "GET $BASE/servers/42", 'the placeholder is filled in' );
    is( $answer->{data}{id}, 42,                     'and the document comes back whole' );

    mock_request( 'DELETE /api/v1/servers/7/ips/9', json_response( {} ) );
    client()->delete_additional_ip( serverId => 7, ipId => 9 );
    is( last_http_request(), sprintf( '%s %s', 'DELETE', "$BASE/servers/7/ips/9" ), 'two placeholders are filled in too' );

    like(
        dies { client()->get_an_existing_server() },
        qr{get_an_existing_server needs a id: its path is /servers/\{id\}},
        'and a missing one says which, and what the path was',
    );
};

subtest 'query strings and bodies' => sub {
    my $mock = mock_http_tiny();

    mock_request( 'GET /api/v1/servers', json_response( { data => [] } ) );
    client()->get_list_of_servers( page => 2, 'filter[status]' => 'started' );
    like( last_http_request(), qr/\Qfilter%5Bstatus%5D=started\E/, 'a filter is escaped into the query' );
    like( last_http_request(), qr/\Qpage=2\E/,                     'along with the page' );
    is( last_http_content(), undef, 'and a listing sends no body' );

    mock_request( 'POST /api/v1/servers', json_response( { data => { id => 1 } }, status => 201, reason => 'Created' ) );
    client()->create_a_new_server( name => 'web01.example.test', plan => 3 );
    is( last_http_request(),                    "POST $BASE/servers",                     'a create posts to the collection' );
    is( last_http_content(),                    '{"name":"web01.example.test","plan":3}', 'with everything left over as the body' );
    is( last_http_headers()->{'Content-Type'},  'application/json',                       'said to be JSON' );
    is( last_http_headers()->{'Authorization'}, 'Bearer a-token',                         'and carrying the token' );

    mock_request( 'POST /api/v1/servers/42/start', json_response( {} ) );
    client()->server_start( id => 42 );
    is( last_http_content(), undef, 'an action described entirely by its path sends no body' );

    like(
        dies { client()->server_start( id => 42, hard => 1 ) },
        qr/server_start takes nothing but its path, so there is nowhere to put hard/,
        'and an argument it has nowhere to put is refused rather than hung off the URL',
    );
};

subtest 'failures' => sub {
    my $mock = mock_http_tiny();

    mock_request( 'GET /api/v1/servers/42', json_response( { message => 'Server not found' }, status => 404, reason => 'Not Found' ) );
    like(
        dies { client()->get_an_existing_server( id => 42 ) },
        qr{\QSolusVM get_an_existing_server (GET $BASE/servers/42) failed: 404 Not Found\E.*Server not found}s,
        'a failure names the operation, the request, the status and what the API said',
    );

    mock_request( 'POST /api/v1/servers', json_response( { errors => { plan => ['The plan field is required.'] } }, status => 422, reason => 'Unprocessable Entity' ) );
    like(
        dies { client()->create_a_new_server( name => 'web01.example.test' ) },
        qr/422.*The plan field is required/s,
        'and a validation failure keeps the detail that says which field',
    );

    like( dies { client()->_request('no_such_operation') }, qr/no operation called no_such_operation/, 'an operation that does not exist is refused' );
};

subtest 'what came back' => sub {
    my $mock = mock_http_tiny();
    mock_request( 'GET /api/v1/servers', json_response( { data => [], meta => { current_page => 1, last_page => 3 }, links => { next => 'http://x.test' } } ) );

    my $solus = client();
    $solus->get_list_of_servers();

    is( $solus->last_meta->{last_page},  3,               'the pagination of the last answer is kept' );
    is( $solus->last_links->{next},      'http://x.test', 'and its links' );
    is( $solus->last_response->{status}, 200,             'and the response itself, for whoever needs the status' );
};

subtest 'paginate' => sub {
    my $mock = mock_http_tiny();

    mock_request(
        'GET /api/v1/servers',
        sub ( $method, $url, $args ) {
            my ($page) = $url =~ m/page=(\d+)/;
            $page //= 1;
            return json_response( { data => ["server$page"], meta => { current_page => $page, last_page => 3 } } );
        },
    );

    is( [ client()->paginate('get_list_of_servers') ], [qw{server1 server2 server3}], 'every page is walked and the data run together' );
    is( scalar http_requests(),                        3,                             'which took exactly three requests' );

    clear_mocks();
    mock_request( 'GET /api/v1/locations', json_response( { data => [ 'one', 'two' ] } ) );
    is( [ client()->paginate('get_list_of_locations') ], [qw{one two}], 'an answer with no pagination at all is one page' );
};

subtest 'login' => sub {
    my $mock = mock_http_tiny();

    mock_request(
        'POST /api/v1/auth/login',
        json_response( { data => { credentials => { access_token => 'fresh', token_type => 'bearer', expires_at => '2099-01-01T00:00:00+00:00' } } } ),
    );

    my $solus       = SolusVM::Client->new( host => $HOST, email => 'you@example.test', password => 'hunter2' );
    my $credentials = $solus->login();

    is( $credentials->{access_token}, 'fresh',                                             'the credentials come back to the caller' );
    is( $solus->{token},              'fresh',                                             'and are kept' );
    is( last_http_request(),          "POST $BASE/auth/login",                             'the login goes where the API says' );
    is( last_http_content(),          '{"email":"you@example.test","password":"hunter2"}', 'with the credentials as the body' );
    ok( !exists last_http_headers()->{'Authorization'}, 'and no token, there being none yet' );

    mock_request( 'POST /api/v1/auth/login', json_response( { data => {} } ) );
    like(
        dies { SolusVM::Client->new( host => $HOST, email => 'you@example.test', password => 'hunter2' )->login() },
        qr/no access token/,
        'a login the API answers without a token is a failure, not a client with no token',
    );

    like( dies { client()->login() }, qr/no email and password/, 'and a token-only client cannot log in' );
};

subtest 'token lifetime' => sub {
    my $mock = mock_http_tiny();

    my $logins = 0;
    mock_request(
        'POST /api/v1/auth/login',
        sub ( $method, $url, $args ) {
            $logins++;
            return json_response( { data => { credentials => { access_token => "fresh$logins", expires_at => '2099-01-01T00:00:00+00:00' } } } );
        },
    );
    mock_request( 'GET /api/v1/servers', json_response( { data => [] } ) );

    my $lazy = SolusVM::Client->new( host => $HOST, email => 'you@example.test', password => 'hunter2' );
    is( $logins, 0, 'a client given credentials does not log in until it has to' );
    $lazy->get_list_of_servers();
    is( $logins,                                1,               'and then does' );
    is( last_http_headers()->{'Authorization'}, 'Bearer fresh1', 'carrying the token it was given' );

    $lazy->get_list_of_servers();
    is( $logins, 1, 'a token that has not expired is used again rather than replaced' );

    my $stale = SolusVM::Client->new( host => $HOST, token => 'stale', expires_at => '2020-01-01T00:00:00+00:00', email => 'you@example.test', password => 'hunter2' );
    $stale->get_list_of_servers();
    is( $logins,                                2,               'a token past its expiry is replaced before it is sent' );
    is( last_http_headers()->{'Authorization'}, 'Bearer fresh2', 'and the fresh one goes out' );

    is( SolusVM::Client::_epoch_of('2099-01-01 00:00:00'), SolusVM::Client::_epoch_of('2099-01-01T00:00:00+00:00'), 'both shapes of expiry the API uses parse the same' );
    is( SolusVM::Client::_epoch_of('whenever'),            undef,                                                   'and one it does not is given up on rather than guessed at' );
};

subtest 'a token the API rejects anyway' => sub {
    my $mock = mock_http_tiny();

    my $logins = 0;
    mock_request(
        'POST /api/v1/auth/login',
        sub ( $method, $url, $args ) { $logins++; return json_response( { data => { credentials => { access_token => 'renewed', expires_at => '2099-01-01T00:00:00+00:00' } } } ) },
    );

    my $attempts = 0;
    mock_request(
        'GET /api/v1/servers',
        sub ( $method, $url, $args ) {
            $attempts++;
            return json_response( { message => 'Unauthenticated.' }, status => 401, reason => 'Unauthorized' ) if $attempts == 1;
            return json_response( { data    => [] } );
        },
    );

    my $solus = SolusVM::Client->new( host => $HOST, token => 'revoked', email => 'you@example.test', password => 'hunter2' );
    ok( $solus->get_list_of_servers(), 'a rejected token is renewed and the request tried again' );
    is( $logins,   1, 'which took one login' );
    is( $attempts, 2, 'and one retry' );

    clear_mocks();
    mock_request( 'POST /api/v1/auth/login', json_response( { data    => { credentials => { access_token => 'renewed', expires_at => '2099-01-01T00:00:00+00:00' } } } ) );
    mock_request( 'GET /api/v1/servers',     json_response( { message => 'Unauthenticated.' }, status => 401, reason => 'Unauthorized' ) );

    my $hopeless = SolusVM::Client->new( host => $HOST, token => 'revoked', email => 'you@example.test', password => 'hunter2' );
    like( dies { $hopeless->get_list_of_servers() }, qr/401/, 'a second rejection is the caller\'s problem' );
    is( scalar( grep { index( $_->{url}, '/auth/login' ) >= 0 } http_requests() ), 1, 'and is not logged in for over and over' );

    clear_mocks();
    mock_request( 'GET /api/v1/servers', json_response( { message => 'Unauthenticated.' }, status => 401, reason => 'Unauthorized' ) );
    like(
        dies { client()->get_list_of_servers() },
        qr/Pass email and password as well as the token/,
        'a client with only a token is told what would have let it recover',
    );
};

subtest 'the password' => sub {
    my $mock = mock_http_tiny();

    mock_request( 'POST /api/v1/auth/login', json_response( { message => 'These credentials do not match our records.', password => 'hunter2' }, status => 422, reason => 'Unprocessable Entity' ) );

    my $failure = dies { SolusVM::Client->new( host => $HOST, email => 'you@example.test', password => 'hunter2' )->login() };
    like( $failure, qr/do not match our records/, 'a bad login says so' );
    unlike( $failure, qr/hunter2/, 'without putting the password in the exception' );

    is( SolusVM::Client::_redact('{"email":"you@example.test","password":"hunter2"}'), '{"email":"you@example.test","password":"********"}', 'and redaction leaves the rest legible' );

    clear_mocks();
    mock_request( 'POST /api/v1/auth/login', json_response( { data => { credentials => { access_token => 'fresh', expires_at => '2099-01-01T00:00:00+00:00' } } } ) );

    my $watched = q{};
    {
        open my $fh, '>', \$watched or die "could not capture STDERR: $!\n";
        local *STDERR = $fh;
        SolusVM::Client->new( host => $HOST, email => 'you@example.test', password => 'hunter2', debug => 1 )->login();
        close $fh;
    }

    like( $watched, qr{POST \Qhttps://$HOST/api/v1/auth/login\E}, 'debug says what was asked' );
    like( $watched, qr/200 OK/,                                   'and what came back' );
    unlike( $watched, qr/hunter2/, 'and still not the password, which is the whole reason to be careful about a debug flag' );
};

subtest 'a spec from a file' => sub {
    my $mock = mock_http_tiny();

    my $directory = File::Temp->newdir();
    my $file      = File::Spec->catfile( "$directory", 'small.json' );

    open my $fh, '>', $file or die "could not write $file: $!\n";
    print {$fh} Cpanel::JSON::XS->new->utf8->encode( [ { name => 'list_widgets', operation_id => 'list-widgets', method => 'GET', uri => '/widgets', path_params => [], query_params => [], has_body => 0, tag => 'Widgets', summary => q{} } ] );
    close $fh;

    mock_request( 'GET /api/v1/widgets', json_response( { data => [] } ) );

    my $solus = SolusVM::Client->new( host => $HOST, token => 'a-token', spec_file => $file );
    ok( $solus->can('list_widgets'), 'an API this release has never heard of is still callable' );
    ok( $solus->list_widgets(),      'and answers' );
};

done_testing();
