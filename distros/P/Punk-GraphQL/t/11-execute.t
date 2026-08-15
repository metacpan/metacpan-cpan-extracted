#!perl
use 5.024;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use PGTest;

my %calls;
{
    package ExecApp;
    use Punk;
    use Punk::Plugin::GraphQL;
    graphql '/graphql' => PGTest::sdl(), {
        resolvers => PGTest::resolvers(calls => \%calls),
    };
    plugin 'GraphQL';
}
my $app = ExecApp->to_app;

# plain query, exact bytes: the sync JSON lane renders keys in query
# field order, so the whole response is deterministic
{
    my $r = hit($app,
        body => '{"query":"{ users(first: 2) { id name } }"}');
    is $r->[0], 200, 'query executes';
    is $r->[2][0],
        '{"data":{"users":[{"id":"1","name":"user1"},'
      . '{"id":"2","name":"user2"}]}}',
        'byte-exact response in query field order';
}

# variables
{
    my $r = hit($app, body =>
        '{"query":"query($first: Int) { users(first: $first) { id } }",'
      . '"variables":{"first":3}}');
    is $r->[0], 200, 'variables execute';
    is scalar @{ jdec($r)->{data}{users} }, 3, 'and are applied';
}

# operationName selects the operation - the runtime wants operation_name,
# the envelope says operationName; the mapping is the plugin's job
{
    my $two = '{"query":"query A { users(first: 1) { id } } '
            . 'query B { users(first: 2) { id } }","operationName":"B"}';
    my $r = hit($app, body => $two);
    is $r->[0], 200, 'two-operation document with operationName executes';
    is scalar @{ jdec($r)->{data}{users} }, 2,
        'and the named operation ran, not the first';
}

# mutation
{
    my $r = hit($app, body =>
        '{"query":"mutation($id: ID!, $n: String!) '
      . '{ rename(id: $id, name: $n) { id name } }",'
      . '"variables":{"id":"1","n":"renamed"}}');
    is $r->[0], 200, 'mutation executes';
    is jdec($r)->{data}{rename}{name}, 'renamed', 'and applied its args';
    ok $calls{rename}, 'mutation resolver was called';
}

# full nested page
{
    my $r = hit($app, body =>
        '{"query":"{ users { id name email active } }"}');
    my $d = jdec($r);
    is scalar @{ $d->{data}{users} }, 25, 'full page';
    # frj decodes JSON booleans as overloaded objects; assert truthiness
    ok $d->{data}{users}[0]{active},  'boolean field true';
    ok !$d->{data}{users}[1]{active}, 'boolean field false';
    like $r->[2][0], qr/"active":true/, 'rendered as JSON booleans';
}

done_testing();
