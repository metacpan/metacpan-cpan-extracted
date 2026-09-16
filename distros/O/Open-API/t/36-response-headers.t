#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;
use Open::API;
use Open::API::Plack;
use File::Raw::JSON;

# Declared response headers.
#
# They were normalised as if they would be checked - a $ref to
# components.headers is inlined, the schema converted - and then never
# compiled: oa_compile_responses read only `content`. So a `required`
# response header was never checked and never reported.
#
# Two structural points drive the shape of this file:
#
#   * Headers hang off the STATUS, not the media type. A status declaring two
#     content types must not carry two copies, and a status with headers and
#     NO JSON body (204, or a 3xx carrying Location) compiles no response row
#     at all - yet still has headers to check. That case is the whole reason
#     the check cannot live beside the body schema.
#   * The check therefore runs ABOVE the body skip rules, which return early
#     for a non-JSON, oversized or streaming body. A test that only exercised
#     a JSON 200 would pass with the check in the wrong place.

sub app_for {
    my (%o) = @_;
    my $api  = Open::API->new(spec => $o{spec});
    my @seen;
    my $app  = Open::API::Plack->new(
        api                => $api,
        validate_responses => { mode => 'report',
                                report => sub { push @seen, [ @_ ] } },
        handlers           => $o{handlers},
    )->to_app;
    return ($app, \@seen, $api);
}

sub get {
    my ($app, $path) = @_;
    open my $in, '<', \(my $b = '') or die;
    return $app->({
        REQUEST_METHOD => 'GET',
        PATH_INFO      => $path,
        QUERY_STRING   => '',
        'psgi.input'   => $in,
    });
}

my $BODY = File::Raw::JSON::file_json_encode({ ok => 1 });

sub spec_with {
    my ($responses) = @_;
    return {
        openapi => '3.1.0',
        info    => { title => 'T', version => '1.0.0' },
        paths   => { '/r' => { get => {
            operationId => 'r',
            responses   => $responses,
        } } },
        components => { headers => {
            Tok => { required => 1, schema => { type => 'string' } },
        } },
    };
}

my %JSON200 = (
    200 => {
        description => 'ok',
        headers     => {
            'X-Rate' => { required => 1, schema => { type => 'integer' } },
        },
        content => { 'application/json' => { schema => { type => 'object' } } },
    },
);

# ---- a required header that is absent ---------------------------------------
{
    my ($app, $seen) = app_for(
        spec     => spec_with({ %JSON200 }),
        handlers => { r => sub {
            [ 200, [ 'Content-Type' => 'application/json',
                     'Content-Length' => length $BODY ], [ $BODY ] ] } },
    );
    get($app, '/r');
    is(scalar @$seen, 1, 'a missing required response header is reported');
    is($seen->[0][2][0]{keyword}, 'required', '...as a required failure') if @$seen;
    is($seen->[0][2][0]{in}, 'response', '...marked in=response')         if @$seen;
}

# ---- present, but failing its schema ----------------------------------------
{
    my ($app, $seen) = app_for(
        spec     => spec_with({ %JSON200 }),
        handlers => { r => sub {
            [ 200, [ 'Content-Type' => 'application/json',
                     'X-Rate'       => 'not-an-integer',
                     'Content-Length' => length $BODY ], [ $BODY ] ] } },
    );
    get($app, '/r');
    is(scalar @$seen, 1, 'a response header violating its schema is reported');
    isnt(($seen->[0][2][0]{keyword} || ''), 'required',
         '...and not as a missing header') if @$seen;
}

# ---- conforming: nothing reported -------------------------------------------
{
    my ($app, $seen) = app_for(
        spec     => spec_with({ %JSON200 }),
        handlers => { r => sub {
            [ 200, [ 'Content-Type' => 'application/json',
                     'X-Rate'       => '17',
                     'Content-Length' => length $BODY ], [ $BODY ] ] } },
    );
    get($app, '/r');
    is(scalar @$seen, 0, 'a conforming response header is not reported');
}

# ---- 204: headers, no JSON body ---------------------------------------------
#
# The case the old code could not reach at all. No `content` means no response
# row, and the body skip rules would have returned before any header was
# looked at.
{
    my ($app, $seen) = app_for(
        spec => spec_with({
            204 => { description => 'empty',
                     headers => { 'X-Gone' =>
                         { required => 1, schema => { type => 'string' } } } },
        }),
        handlers => { r => sub { [ 204, [], [ '' ] ] } },
    );
    get($app, '/r');
    is(scalar @$seen, 1,
       'a header-only status with no JSON body is still checked');
    is($seen->[0][1], 204, '...against the status it was declared under')
        if @$seen;
}

# ---- a header declared under a range key ------------------------------------
{
    my ($app, $seen) = app_for(
        spec => spec_with({
            '2XX' => { description => 'any success',
                       headers => { 'X-Rate' =>
                           { required => 1, schema => { type => 'integer' } } } },
        }),
        handlers => { r => sub { [ 200, [], [ '' ] ] } },
    );
    get($app, '/r');
    is(scalar @$seen, 1, 'headers declared under a 2XX range key are checked');
}

# ---- a $ref to components.headers -------------------------------------------
{
    my ($app, $seen) = app_for(
        spec => spec_with({
            200 => { description => 'ok',
                     headers => { 'X-Tok' => { '$ref' => '#/components/headers/Tok' } },
                     content => { 'application/json' =>
                                  { schema => { type => 'object' } } } },
        }),
        handlers => { r => sub {
            [ 200, [ 'Content-Type' => 'application/json',
                     'Content-Length' => length $BODY ], [ $BODY ] ] } },
    );
    get($app, '/r');
    is(scalar @$seen, 1, 'a $ref to components.headers is resolved and checked');
}

# ---- a document declaring no headers is unaffected --------------------------
{
    my ($app, $seen, $api) = app_for(
        spec => spec_with({
            200 => { description => 'ok',
                     content => { 'application/json' =>
                         { schema => { type => 'object',
                                       required => ['ok'],
                                       properties => { ok => { type => 'integer' } } } } } },
        }),
        handlers => { r => sub {
            [ 200, [ 'Content-Type' => 'application/json',
                     'Content-Length' => length $BODY ], [ $BODY ] ] } },
    );
    get($app, '/r');
    is(scalar @$seen, 0, 'no declared headers: the body verdict is unchanged');
    my $cov = $api->response_coverage('r');
    is($cov->{checked}, 1, '...and the body was still checked');
}

done_testing;
