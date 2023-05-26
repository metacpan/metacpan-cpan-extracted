#! perl -I. -w
use t::Test::abeltje;
use Test::MockObject;
use JSON;

{
    package TestClass;
    use Moo;
    with 'MooX::Role::REST';
    1;
}

{
    my $client = TestClass->new(
        base_uri => 'http://localhost/v1/',
    );
    isa_ok($client, 'TestClass');
    isa_ok($client->ua, 'HTTP::Tiny');
    isa_ok($client->base_uri, 'URI::http');
}

{
    my $test_ua = Test::MockObject->new();
    $test_ua->set_isa('HTTP::Tiny');
    $test_ua->mock(
        request => sub {
            my $self = shift;
            my ($hmethod, $cpath, $body) = @_;
            # create a minimal HTTP::Tiny response
            return {
                success => 1,
                headers => {
                    'content-type' => 'application/json; charset=utf8',
                },
                content => to_json(
                    {
                        request => "$hmethod => $cpath",
                        ($body ? (body => $body->{content}) : ()),
                    }
                ),
            };
        },
        www_form_urlencode => sub {
            my $self = shift;
            my ($params) = @_;

            use URI; my $u = URI->new('http://none/');
	    $u->query_form(map { ($_ => $params->{$_}) } sort keys %$params)
	        if $params;
            return $u->query();
        },
    );
    my $client = TestClass->new(
        ua => $test_ua,
        base_uri => 'http://localhost/v1/',
    );
    isa_ok($client, 'TestClass');

    my $response = $client->call(GET => 'this_path', {q => 'Blah Blah', limit => 5});
    is_deeply(
        $response,
        { request => 'GET => http://localhost/v1/this_path?limit=5&q=Blah+Blah' },
        "Request received ok"
    ) or diag(explain($response));

    $response = $client->call(POST => '/v2/that_path', {q => 'Blah'});
    is_deeply(
        $response,
        {
            body    => '{"q":"Blah"}',
            request => 'POST => http://localhost/v2/that_path',
        },
        "A request with body"
    ) or diag(explain($response));
}

{ # rainy day 
    my $test_ua = Test::MockObject->new();
    $test_ua->set_isa('HTTP::Tiny');
    $test_ua->mock(
        request => sub {
            my $self = shift;
            my ($hmethod, $cpath, $body) = @_;
            # create a minimal HTTP::Tiny response
            return {
                success => 0,
                status  => 500,
                reason  => 'server error',
                headers => {
                    'content-type' => 'text/plain',
                },
                content => "Just won't do it",
            };
        },
        www_form_urlencode => sub {
            my $self = shift;
            my ($params) = @_;

            use URI; my $u = URI->new('http://none/');
	    $u->query_form(map { ($_ => $params->{$_}) } sort keys %$params)
	        if $params;
            return $u->query();
        },
    );
    my $client = TestClass->new(
        ua => $test_ua,
        base_uri => 'http://localhost/',
    );
    isa_ok($client, 'TestClass');

    my $exception = exception {
        $client->call(GET => 'this_path', {q => 'Blah Blah', limit => 5});
    };
    like(
        $exception,
        qr{^Error GET\(http://localhost/this_path\?limit=5&q=Blah\+Blah\): 500 \(server error\)},
        "Exception: Part 1"
    );
    like($exception, qr{ - Just won't do it at $0 line \d+\n$}, "Exception: Part 2");
}

abeltje_done_testing();
