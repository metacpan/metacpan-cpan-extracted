use Test::More;

my $user     = $ENV{API_USER};
my $password = $ENV{API_PASSWORD};

plan skip_all => "API_USER and API_PASSWORD environment variables must be set"
    unless $user and $password;

use_ok('PowerDNS::API::Client');
ok( my $api = PowerDNS::API::Client->new(
        user     => $user,
        password => $password,
        server   => 'http://localhost:5000/',
    )
);

my $testdomain = 'foo-' . time . ".test";

ok( my $r = $api->call(GET => 'domain/'), 'get list of domains');
isa_ok( $r->{domains}, 'ARRAY', 'got array of domains' );

ok( $r = $api->call(PUT => 'domain/', domain => $testdomain ), 'add domain');
is( $r->{domain}->{name}, $testdomain, 'got right name back');
is( $r->{domain}->{type}, 'MASTER', 'is MASTER');

ok( $r = $api->call(PUT => 'domain/', domain => $testdomain ), 'add duplicate domain');
is( $r->{error}, 'domain exists', 'got error indicating duplicate domain');
is( $r->{http_status}, 409, '409 status');

ok( $r = $api->call(GET => 'domain/'), 'get list of domains');
ok( grep { $_->{name} eq $testdomain } @{ $r->{domains} }, "test domain was in list");

# TODO:
# ok( $r = $api->call(DELETE => 'domain/', domain => $testdomain ), 'delete domain');


ok( $r = $api->call(
        POST    => "record/$testdomain",
        name    => '',
        content => '10.0.0.1',
        type    => 'a'
    ),
    'Add A record'
);
is($r->{record}->{type}, 'A', 'A record created');

ok( $r = $api->call(
        POST    => "record/$testdomain",
        name    => 'www',
        content => 'test.example.net',
        type    => 'cname'
    ),
    'Add CNAME record'
);
is($r->{record}->{content}, 'test.example.net', 'CNAME record created');

ok( $r = $api->call(GET => "domain/$testdomain", type => 'A', name => ''), 'details for A record');
is( $r->{records}->[0]->{name}, '', 'got right record name');
is( $r->{records}->[0]->{content}, '10.0.0.1', 'got expected content');

# ok( my $r = $api->call(GET => "domain/$testdomain"), 'get domain details');


done_testing;
