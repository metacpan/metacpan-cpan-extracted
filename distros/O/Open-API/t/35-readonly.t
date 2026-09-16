#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;
use Open::API;
use Open::API::Plack;
use File::Raw::JSON;

# readOnly / writeOnly, which are DIRECTIONAL.
#
# A readOnly property may come back in a response but must not be sent in a
# request, and writeOnly is the mirror. And a `required` property that is
# readOnly is required of RESPONSES ONLY - so the same component means two
# different things depending on which way the payload is travelling.
#
# None of that can be decided while validating: once a schema is compiled
# JSON::Schema::Fast owns the traversal, exactly as with `discriminator`. It is
# expanded into 2020-12 constructs at compile time instead, per direction, and
# a whole projected $defs block is built so a $ref from a request body reaches
# the request-projected component. Hence every case below is run TWICE, once
# with the schema inline and once through a $ref: the projection ran on inline
# schemas long before it worked through a $ref, and only the $ref form is
# representative of real documents.
#
# A TRAP worth recording, because it cost real time. When probing the RESPONSE
# direction, the REQUEST schema must be permissive. If both directions share a
# strict schema, a body carrying a readOnly property is rejected by the request
# validator, the handler never runs, no response is ever produced, and the
# absence of a response finding reads exactly like "the response conformed".
# That is why `mk` below declares a wide-open request body.

my %THING = (
    type       => 'object',
    required   => [ 'id', 'name' ],
    properties => {
        id     => { type => 'integer', readOnly  => 1 },
        name   => { type => 'string' },
        secret => { type => 'string',  writeOnly => 1 },
    },
);

# `strict` carries the directional schema on the REQUEST;
# `mk` carries it on the RESPONSE and leaves the request wide open.
sub spec {
    my ($inline) = @_;
    my $s = $inline ? { %THING } : { '$ref' => '#/components/schemas/Thing' };
    return {
        openapi => '3.1.0',
        info    => { title => 'T', version => '1.0.0' },
        paths   => {
            '/strict' => { post => {
                operationId => 'strict',
                requestBody => { required => 1,
                    content => { 'application/json' => { schema => $s } } },
                responses   => { 200 => { description => 'ok' } },
            } },
            '/mk' => { post => {
                operationId => 'mk',
                requestBody => { required => 1, content => { 'application/json' =>
                    { schema => { type => 'object' } } } },
                responses   => { 200 => { description => 'ok',
                    content => { 'application/json' => { schema => $s } } } },
            } },
        },
        components => { schemas => { Thing => { %THING } } },
    };
}

my $JSON = { 'content-type' => 'application/json' };

for my $inline (1, 0) {
    my $how = $inline ? 'inline' : 'via $ref';
    my $api = Open::API->new(spec => spec($inline));

    # ---- request direction ---------------------------------------------
    my ($ok, $errs);

    ($ok) = $api->validate_request(strict => { header => $JSON,
                                               body => { name => 'x' } });
    ok($ok, "$how: a readOnly property in `required` is not demanded of a request");

    ($ok, $errs) = $api->validate_request(strict => { header => $JSON,
                                          body => { name => 'x', id => 1 } });
    ok(!$ok, "$how: sending a readOnly property is refused");
    is(($errs && @$errs ? $errs->[0]{keyword} : ''), 'not',
       "$how: ...by the constraint the projection added, not by accident");

    ($ok) = $api->validate_request(strict => { header => $JSON,
                                    body => { name => 'x', secret => 's' } });
    ok($ok, "$how: a writeOnly property IS allowed in a request");

    ($ok) = $api->validate_request(strict => { header => $JSON,
                                               body => { id => 1 } });
    ok(!$ok, "$how: an ordinary required property is still required");

    # ---- response direction --------------------------------------------
    for my $c (
        [ { id => 1, name => 'x' },              'conforms',            0, ''         ],
        [ { name => 'x' },                       'missing readOnly id', 1, 'required' ],
        [ { id => 1, name => 'x', secret => 's' },'carries writeOnly',  1, 'not'      ],
    ) {
        my ($body, $what, $want, $kw) = @$c;
        my @seen;
        my $json = File::Raw::JSON::file_json_encode($body);
        my $a2   = Open::API->new(spec => spec($inline));
        my $app  = Open::API::Plack->new(
            api                => $a2,
            validate_responses => { mode => 'report',
                                    report => sub { push @seen, [ @_ ] } },
            handlers => { mk => sub {
                [ 200, [ 'Content-Type'   => 'application/json',
                         'Content-Length' => length $json ], [ $json ] ] } },
        )->to_app;
        open my $in, '<', \(my $b = '{}') or die;
        $app->({ REQUEST_METHOD => 'POST', PATH_INFO => '/mk', QUERY_STRING => '',
                 CONTENT_TYPE   => 'application/json', CONTENT_LENGTH => 2,
                 'psgi.input'   => $in });
        is(scalar(@seen) ? 1 : 0, $want, "$how: response $what");
        is(($seen[0] && $seen[0][2][0]{keyword}) || '', $kw,
           "$how: ...reported under the expected keyword") if $want;
    }
}

# ---- the gate --------------------------------------------------------------
#
# A document using neither flag must compile down the original path and behave
# exactly as before. This is what protects every existing document from the
# change, so it is asserted rather than assumed.

{
    my $api = Open::API->new(spec => {
        openapi => '3.1.0',
        info    => { title => 'T', version => '1.0.0' },
        paths   => { '/p' => { post => {
            operationId => 'p',
            requestBody => { required => 1, content => { 'application/json' => {
                schema => { type => 'object', required => ['a'],
                            properties => { a => { type => 'string' } } } } } },
            responses   => { 200 => { description => 'ok' } },
        } } },
    });
    my ($good) = $api->validate_request(p => { header => $JSON, body => { a => 'x' } });
    my ($bad)  = $api->validate_request(p => { header => $JSON, body => {} });
    ok($good, 'no readOnly anywhere: a conforming request is still accepted');
    ok(!$bad, '...and a missing required property is still rejected');
}

done_testing;
