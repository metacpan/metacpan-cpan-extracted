#!perl
use 5.024;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use PGTest;

{
    package TransportApp;
    use Punk;
    use Punk::Plugin::GraphQL;
    graphql '/graphql' => PGTest::sdl(), {
        resolvers => PGTest::resolvers(),
        max_body  => 4096,
    };
    plugin 'GraphQL';
}
my $app = TransportApp->to_app;
my $good = '{"query":"{ users(first: 1) { id } }"}';

# method
{
    my $r = hit($app, method => 'PUT', body => $good);
    is $r->[0], 405, 'PUT is 405';
    my %h = @{ $r->[1] };
    like $h{Allow} // '', qr/POST/, 'Allow names POST';
}

# content type
{
    my $r = hit($app, body => $good, type => 'text/plain');
    is $r->[0], 415, 'text/plain is 415';
    like jdec($r)->{errors}[0]{message}, qr/Content-Type/, 'and says why';

    $r = hit($app, body => $good, type => 'application/json; charset=utf-8');
    is $r->[0], 200, 'charset parameter on the type is fine';

    $r = hit($app, body => $good,
             type => 'application/graphql-response+json');
    is $r->[0], 200, 'the response profile type is accepted on requests';
}

# size: an oversize CONTENT_LENGTH is refused before the body is read
{
    my $r = hit($app, body => $good,
                env => { CONTENT_LENGTH => 4097 });
    is $r->[0], 413, 'oversize body is 413';
}

# body shape
{
    my $r = hit($app, body => 'not json at all');
    is $r->[0], 400, 'unparseable JSON is 400';

    $r = hit($app, body => '[1,2,3]');
    is $r->[0], 400, 'a JSON array body is 400';

    $r = hit($app, body => '{}');
    is $r->[0], 400, 'missing query is 400';
    like jdec($r)->{errors}[0]{message}, qr/"query"/, 'and says which field';

    $r = hit($app, body => '{"query":"   "}');
    is $r->[0], 400, 'whitespace query is 400';

    $r = hit($app, body => '{"query":"{ users { id } }","variables":[1]}');
    is $r->[0], 400, 'array variables is 400';

    $r = hit($app, body => '{"query":"{ users { id } }","operationName":""}');
    is $r->[0], 400, 'empty operationName is 400';
}

# response content type negotiation
{
    my $r = hit($app, body => $good);
    my %h = @{ $r->[1] };
    like $h{'Content-Type'}, qr{^application/json},
        'plain application/json without an Accept preference';
    is $h{'Content-Length'}, length $r->[2][0],
        'Content-Length matches the bytes';

    $r = hit($app, body => $good,
             env => { HTTP_ACCEPT => 'application/graphql-response+json' });
    %h = @{ $r->[1] };
    like $h{'Content-Type'}, qr{^application/graphql-response\+json},
        'graphql-response+json when Accept asks';
}

done_testing();
