#!perl
use 5.024;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use PGTest;

{
    package CostApp;
    use Punk;
    use Punk::Plugin::GraphQL;
    graphql '/graphql' => PGTest::sdl(), {
        resolvers => PGTest::resolvers(),
        max_cost  => 2,
    };
    plugin 'GraphQL';
}
my $app = CostApp->to_app;

# the 4-leaf list query costs far more than 2 under the default list-size
# estimate: rejected as a request error at wire speed
{
    my $r = hit($app, body =>
        '{"query":"{ users { id name email active } }"}');
    is $r->[0], 400, 'over-budget query is 400';
    like jdec($r)->{errors}[0]{message}, qr/cost/i, 'and says cost';
}

# a one-field query still fits
{
    my $r = hit($app, body => '{"query":"{ boom }"}');
    is $r->[0], 200, 'a cheap query still executes';
}

done_testing();
