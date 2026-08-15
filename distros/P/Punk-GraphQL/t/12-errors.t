#!perl
use 5.024;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use PGTest;

{
    package ErrApp;
    use Punk;
    use Punk::Plugin::GraphQL;
    graphql '/graphql' => PGTest::sdl(), {
        resolvers => PGTest::resolvers(),
    };
    plugin 'GraphQL';
}
my $app = ErrApp->to_app;

sub body_for { '{"query":' . shift . '}' }

# request errors: no field executed, errors-only envelope, 400
{
    my $r = hit($app, body => body_for('"query {{{ nope"'));
    is $r->[0], 400, 'syntax error is 400';
    my $d = jdec($r);
    ok $d->{errors} && !exists $d->{data}, 'errors-only envelope';
    like $d->{errors}[0]{message}, qr/Syntax Error/, 'parser message';

    $r = hit($app, body => body_for('"{ nosuchfield }"'));
    is $r->[0], 400, 'validation error is 400';
    like jdec($r)->{errors}[0]{message}, qr/nosuchfield/, 'names the field';

    $r = hit($app, body =>
        '{"query":"query($id: ID!) { user(id: $id) { id } }"}');
    is $r->[0], 400, 'missing required variable is 400';
    like jdec($r)->{errors}[0]{message}, qr/\$id/, 'names the variable';

    $r = hit($app, body => body_for('"subscription { users { id } }"'));
    is $r->[0], 400, 'subscription fails closed as a request error';
}

# field errors: execution reached the schema, 200 with data + errors
{
    my $r = hit($app, body => body_for('"{ boom }"'));
    is $r->[0], 200, 'resolver die is still 200';
    my $d = jdec($r);
    ok exists $d->{data}, 'data key present';
    is $d->{data}{boom}, undef, 'field nulled';
    is $d->{errors}[0]{message}, 'kaboom', 'die message surfaced';
    is_deeply $d->{errors}[0]{path}, ['boom'], 'with the field path';
}

# partial success: one good field, one dying field, same response
{
    my $r = hit($app, body => body_for('"{ users(first: 1) { id } boom }"'));
    is $r->[0], 200, 'partial failure is 200';
    my $d = jdec($r);
    is $d->{data}{users}[0]{id}, '1', 'good field delivered';
    is $d->{data}{boom}, undef, 'bad field nulled';
    ok $d->{errors}, 'with errors alongside';
}

done_testing();
