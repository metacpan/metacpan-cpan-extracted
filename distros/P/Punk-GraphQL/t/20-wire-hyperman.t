#!perl
use 5.024;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;

BEGIN {
    plan skip_all => 'Hyperman required for the wire tests'
        unless eval { require Hyperman; 1 };
}
use PGSpawn;
use File::Raw::JSON ();

# the server app: the same fixture schema, real prefork workers
my $h = pg_start(<<'APP');
package App;
use Punk;
use Punk::Plugin::GraphQL;
graphql '/graphql' => <<'SDL', {
type User { id: ID! name: String! }
type Query { users(first: Int): [User!]! }
SDL
    resolvers => {
        Query => {
            users => sub {
                my (undef, $args) = @_;
                return [ map +{ id => "$_", name => "user$_" },
                         1 .. ($args->{first} // 3) ];
            },
        },
    },
    graphiql => 1,
};
plugin 'GraphQL';
APP

ok $h->{pid}, 'server spawned';

my $env = '{"query":"query($first: Int) { users(first: $first) { id name } }",'
        . '"variables":{"first":2}}';

# a real POST through the wire
my ($status, $headers, $body, $sock) =
    http_post($h->{port}, '/graphql', $env);
is $status, 200, 'wire POST executes';
is $body,
    '{"data":{"users":[{"id":"1","name":"user1"},'
  . '{"id":"2","name":"user2"}]}}',
    'byte-exact response over the wire';
like $headers->{'content-type'}, qr{^application/json}, 'negotiated CT';

# keep-alive: three more requests down the same connection
for my $n (1 .. 3) {
    (my $s2, undef, my $b2, $sock) =
        http_post($h->{port}, '/graphql',
            '{"query":"{ users(first: ' . $n . ') { id } }"}',
            sock => $sock);
    is $s2, 200, "keep-alive request $n ok";
    my $d = File::Raw::JSON::file_json_decode($b2);
    is scalar @{ $d->{data}{users} }, $n, "and returned $n users";
}

# error path over the wire
{
    my ($s2, undef, $b2) = http_post($h->{port}, '/graphql',
        '{"query":"{ nosuchfield }"}');
    is $s2, 400, 'validation error is 400 on the wire';
}

# graphiql
{
    my ($s2, $h2) = http_get($h->{port}, '/graphql');
    is $s2, 200, 'GET serves GraphiQL';
    like $h2->{'content-type'}, qr{text/html}, 'as HTML';
}

# concurrent-worker smoke: distinct connections in flight together
{
    my @socks = map {
        IO::Socket::INET->new(PeerAddr => "127.0.0.1:$h->{port}",
                              Proto => 'tcp', Timeout => 10)
            or die "connect: $!";
    } 1 .. 8;
    my $req = "POST /graphql HTTP/1.1\r\nHost: x\r\n"
            . "Content-Type: application/json\r\n"
            . "Content-Length: " . length($env) . "\r\n\r\n" . $env;
    print {$_} $req for @socks;    # all in flight before any read
    my $ok = 0;
    for my $s (@socks) {
        my $line = <$s> // '';
        $ok++ if $line =~ m{^HTTP/1\.\d 200};
    }
    is $ok, 8, 'eight concurrent requests all answered 200';
}

my $log = pg_stop($h);
unlike $log, qr/Punk::Plugin::GraphQL: execution failed/,
    'no runtime errors in the server log';

done_testing();
