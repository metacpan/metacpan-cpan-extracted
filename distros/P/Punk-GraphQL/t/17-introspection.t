#!perl
use 5.024;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use PGTest;

{
    package IntroApp;
    use Punk;
    use Punk::Plugin::GraphQL;
    graphql '/graphql' => PGTest::sdl(),
        { resolvers => PGTest::resolvers() };
    plugin 'GraphQL';
}
{
    package NoIntroApp;
    use Punk;
    use Punk::Plugin::GraphQL;
    graphql '/graphql' => PGTest::sdl(),
        { resolvers => PGTest::resolvers(), allow_introspection => 0 };
    plugin 'GraphQL';
}

my $q = '{"query":"{ __schema { queryType { name } } }"}';

{
    my $r = hit(IntroApp->to_app, body => $q);
    is $r->[0], 200, 'introspection executes by default';
    is jdec($r)->{data}{__schema}{queryType}{name}, 'Query',
        'and reports the query root';
}

{
    my $r = hit(NoIntroApp->to_app, body => $q);
    is $r->[0], 400, 'allow_introspection => 0 rejects it';
    ok jdec($r)->{errors}, 'as a request error';
}

done_testing();
