use Test::Most;

use Net::OpenStack::Compute;

throws_ok(
    sub { Net::OpenStack::Compute->new },
    qr(Attribute \S+ is required),
    'instantiation with no argument throws an exception'
);

throws_ok(
    sub { Net::OpenStack::Compute->new( auth_url => 'foo' ) },
    qr(Attribute \S+ is required),
    'instantiation with only auth_url argument throws an exception'
);

throws_ok(
    sub { Net::OpenStack::Compute->new( auth_url => 'foo', user => 'bar' ) },
    qr(Attribute \S+ is required),
    'instantiation with only auth_url, user arguments throws an exception'
);

subtest 'Test calling create_server with bad args' => sub {

    my $compute = Net::OpenStack::Compute->new(
        auth_url => 'http://foo.com/bar',
        user     => 'bob',
        password => 'jane'
    );
    isa_ok($compute, 'Net::OpenStack::Compute');

    throws_ok(
        sub {
            $compute->create_server(
                name => 's1', flavorRef => 'salty', imageRef => 'blarg');
        },
        qr/invalid data/,
        'create_server() dies with "invalid data" if argument is not a hashref'
    );

    throws_ok(
        sub {
            $compute->create_server(
                { name => 's1', flavorRef => 'salty', imageRef => 'blarg'});
        },
        qr/Could not determine version from url/,
        'create_server() dies if object was instantiated with a bad url',
    );
};

subtest 'Bad json response' => sub {

    my $compute = Net::OpenStack::Compute->new(
        auth_url => 'http://foo.com/v42.17',
        user     => 'bob',
        password => 'jane'
    );
    dies_ok(
        sub {
            $compute->create_server(
                { name => 's1', flavorRef => 'salty', imageRef => 'blarg'});
        },
        'create_server() dies if auth_url does not return valid json'
    );
};


done_testing;
