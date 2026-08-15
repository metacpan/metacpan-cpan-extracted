#!perl
use 5.024;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use PGTest;
use GraphQL::Houtou::DataLoader ();

my @batches;        # each element: the arrayref of ids one batch saw
my $ctx_calls = 0;

{
    package CtxApp;
    use Punk;
    use Punk::Plugin::GraphQL;
    graphql '/graphql' => PGTest::sdl(), {
        resolvers => PGTest::resolvers(),
        context   => sub {
            my ($c) = @_;
            Test::More::isa_ok($c, 'Punk::Context',
                'context builder receives the context')
                if $ctx_calls == 0;
            $ctx_calls++;
            my $loader = GraphQL::Houtou::DataLoader->new(batch => sub {
                my ($ids) = @_;
                push @batches, [@$ids];
                return [ map { $PGTest::USERS[$_ - 1] } @$ids ];
            });
            return ({ loader => $loader },
                    GraphQL::Houtou::DataLoader->on_stall_for($loader));
        },
    };
    plugin 'GraphQL';
}
my $app = CtxApp->to_app;

# three aliased user() fields resolve through the loader; the stall hook
# must flush them as ONE batch
{
    my $r = hit($app, body =>
        '{"query":"{ a: user(id: 1) { name } b: user(id: 2) { name } '
      . 'c: user(id: 3) { name } }"}');
    is $r->[0], 200, 'batched query executes';
    my $d = jdec($r);
    is $d->{data}{a}{name}, 'user1', 'alias a resolved';
    is $d->{data}{c}{name}, 'user3', 'alias c resolved';
    is scalar @batches, 1, 'one batch, not three';
    is_deeply [ sort @{ $batches[0] } ], [1, 2, 3],
        'the batch carried all three ids';
}

# the builder runs once per request - loaders are request-scoped
{
    @batches = ();
    my $before = $ctx_calls;
    hit($app, body => '{"query":"{ a: user(id: 1) { name } }"}') for 1 .. 2;
    is $ctx_calls - $before, 2, 'context builder called once per request';
    is scalar @batches, 2, 'each request flushed its own loader';
}

done_testing();
