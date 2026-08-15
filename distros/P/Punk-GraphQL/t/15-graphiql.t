#!perl
use 5.024;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use PGTest;

{
    package IqlOn;
    use Punk;
    use Punk::Plugin::GraphQL;
    graphql '/graphql' => PGTest::sdl(),
        { resolvers => PGTest::resolvers(), graphiql => 1 };
    plugin 'GraphQL';
}
{
    package IqlOff;
    use Punk;
    use Punk::Plugin::GraphQL;
    graphql '/graphql' => PGTest::sdl(),
        { resolvers => PGTest::resolvers() };
    plugin 'GraphQL';
}

# on: GET serves the console, ETagged, endpoint carried in the page,
# and nothing loaded from anywhere else
{
    my $app = IqlOn->to_app;
    my $r = hit($app, method => 'GET', body => '');
    is $r->[0], 200, 'GET serves the console when enabled';
    my %h = @{ $r->[1] };
    like $h{'Content-Type'}, qr{^text/html}, 'as HTML';
    like $r->[2][0], qr/GraphQL console/, 'the page is the console';
    like $r->[2][0], qr{data-endpoint="/graphql"},
        'the endpoint rides in the page';
    unlike $r->[2][0], qr{https?://},
        'the page references no external URL at all';
    like $r->[2][0], qr{__schema},
        'schema docs come from introspection, in-page';
    ok my $etag = $h{ETag}, 'with an ETag';

    $r = hit($app, method => 'GET', body => '',
             env => { HTTP_IF_NONE_MATCH => $etag });
    is $r->[0], 304, 'If-None-Match revalidates to 304';
    is $r->[2][0] // '', '', 'with no body';
}

# off: GET is a router 405 naming POST
{
    my $r = hit(IqlOff->to_app, method => 'GET', body => '');
    is $r->[0], 405, 'GET is 405 when GraphiQL is off';
    my %h = @{ $r->[1] };
    like $h{Allow} // '', qr/POST/, 'Allow names POST';
}

done_testing();
