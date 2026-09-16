#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;
use Open::API;

# Component references: a $ref used IN PLACE OF a parameter, header,
# requestBody or response object (include/oa_normalize.h).
#
# These assert through the public API, the way t/28-openapi30.t does - what the
# validator accepts and rejects rather than the shape of the converted
# document - with one group at the end that reads ->spec directly, because
# inlining is something a consumer is entitled to find there.
#
# The property that matters is that a document written with component refs
# behaves EXACTLY like the same document written inline, so nearly everything
# here builds both twins and compares them.
#
# What this would have caught before the fix, and what to break to re-check it:
#
#   - a $ref PARAMETER croaked the whole document (oa_compile_params reads the
#     absent `in`), so `ref_doc` could not be constructed at all;
#   - a $ref REQUEST BODY returned early on its absent `content`, leaving
#     nbodies 0 and body_required 0 - the body silently unvalidated AND
#     silently optional. The two assertions named "would have passed before"
#     are the ones that bite; a test that only checks the document compiles
#     proves nothing about that half.

# ---- the twins -------------------------------------------------------------

my %BODY_SCHEMA = (
    type       => 'object',
    properties => { name => { type => 'string' } },
    required   => ['name'],
);

sub inline_doc {
    return {
        openapi => '3.1.0',
        info    => { title => 'T', version => '1.0.0' },
        paths   => {
            '/things' => {
                get => {
                    operationId => 'list_things',
                    parameters  => [
                        { name => 'limit', in => 'query', required => 1,
                          schema => { type => 'integer' } },
                    ],
                    responses => { 200 => { description => 'ok' } },
                },
                post => {
                    operationId => 'make_thing',
                    requestBody => {
                        required => 1,
                        content  => {
                            'application/json' => { schema => { %BODY_SCHEMA } },
                        },
                    },
                    responses => { 201 => { description => 'made' } },
                },
            },
        },
    };
}

sub ref_doc {
    return {
        openapi => '3.1.0',
        info    => { title => 'T', version => '1.0.0' },
        paths   => {
            '/things' => {
                get => {
                    operationId => 'list_things',
                    parameters  => [ { '$ref' => '#/components/parameters/Limit' } ],
                    responses   => { 200 => { '$ref' => '#/components/responses/Ok' } },
                },
                post => {
                    operationId => 'make_thing',
                    requestBody => { '$ref' => '#/components/requestBodies/Thing' },
                    responses   => { 201 => { description => 'made' } },
                },
            },
        },
        components => {
            parameters => {
                Limit => { name => 'limit', in => 'query', required => 1,
                           schema => { type => 'integer' } },
            },
            requestBodies => {
                Thing => {
                    required => 1,
                    content  => {
                        'application/json' => { schema => { %BODY_SCHEMA } },
                    },
                },
            },
            responses => { Ok => { description => 'ok' } },
        },
    };
}

my $inline = eval { Open::API->new(spec => inline_doc()) };
ok($inline, 'the inline twin compiles') or diag $@;

my $reffed = eval { Open::API->new(spec => ref_doc()) };
ok($reffed, 'the component-ref twin compiles (it croaked before the fix)')
    or diag $@;

BAIL_OUT('neither twin compiled; nothing below can mean anything')
    unless $inline && $reffed;

# Assert the same thing of both twins, so a divergence names which one.
sub both {
    my ($name, $op, $req, $want) = @_;
    for my $pair ([ inline => $inline ], [ 'component-ref' => $reffed ]) {
        my ($label, $api) = @$pair;
        my ($ok) = $api->validate_request($op, $req);
        is(!!$ok, !!$want, "$name ($label)");
    }
}

# ---- routing ---------------------------------------------------------------

for my $pair ([ inline => $inline ], [ 'component-ref' => $reffed ]) {
    my ($label, $api) = @$pair;
    my ($op) = $api->match(GET => '/things');
    is($op, 'list_things', "routes GET ($label)");
    my ($op2) = $api->match(POST => '/things');
    is($op2, 'make_thing', "routes POST ($label)");
}

# ---- a parameter reached through a component ref ---------------------------

both('a valid parameter is accepted', list_things =>
     { query => { limit => 5 } }, 1);

both('a parameter of the wrong type is rejected', list_things =>
     { query => { limit => 'lots' } }, 0);

both('a missing required parameter is rejected', list_things =>
     { query => {} }, 0);

# ---- a request body reached through a component ref ------------------------
#
# Both of these passed before the fix on the component-ref twin, because no
# schema was attached and `required` was never read.

# A body needs its content type. validate_request picks the media type's
# schema from the `content-type` header, and without one the request is refused
# as an undeclared content type before any schema is consulted - which is why
# the helper in t/06-body.t defaults the header on every call.
my $JSON = { 'content-type' => 'application/json' };

both('a valid body is accepted', make_thing =>
     { header => $JSON, body => { name => 'thing' } }, 1);

both('a body violating the schema is rejected (would have passed before)',
     make_thing => { header => $JSON, body => {} }, 0);

# No body at all, spelled the way t/06 spells it: the `required` flag is what
# has to reject this, and on the component-ref twin that flag was never read.
both('a missing required body is rejected (would have passed before)',
     make_thing => {}, 0);

# ---- idempotency -----------------------------------------------------------
#
# ->spec is fed back through new(), which runs the whole normalisation a second
# time. An inlined object carries no $ref, so the second pass must find nothing
# to do and behave identically.

my $again = eval { Open::API->new(spec => $reffed->spec) };
ok($again, 'the normalised document compiles again') or diag $@;
if ($again) {
    my ($ok) = $again->validate_request(make_thing => { body => {} });
    ok(!$ok, 'and still rejects a bad body on the second pass');
    my ($ok2) = $again->validate_request(list_things => { query => { limit => 5 } });
    ok($ok2, 'and still accepts a good parameter on the second pass');
}

# ---- refs that must NOT be silently swallowed ------------------------------

my $missing = eval {
    my $d = ref_doc();
    $d->{paths}{'/things'}{get}{parameters} =
        [ { '$ref' => '#/components/parameters/NoSuchThing' } ];
    Open::API->new(spec => $d);
};
ok(!$missing, 'a ref naming nothing still fails, rather than being dropped');

my $deep = eval {
    my $d = ref_doc();
    $d->{paths}{'/things'}{get}{parameters} =
        [ { '$ref' => '#/components/parameters/Limit/schema' } ];
    Open::API->new(spec => $d);
};
ok(!$deep, 'a deeper pointer is not treated as a whole object');

my $remote = eval {
    my $d = ref_doc();
    $d->{paths}{'/things'}{get}{parameters} =
        [ { '$ref' => 'https://example.test/x.json#/components/parameters/Limit' } ];
    Open::API->new(spec => $d);
};
ok(!$remote, 'a remote ref is left alone, and so still fails');

# A cycle must terminate. If this ever hangs rather than failing, that IS the
# regression - the hop bound in oa_deref_object is what stops it.
my $cycle = eval {
    my $d = ref_doc();
    $d->{components}{parameters}{A} = { '$ref' => '#/components/parameters/B' };
    $d->{components}{parameters}{B} = { '$ref' => '#/components/parameters/A' };
    $d->{paths}{'/things'}{get}{parameters} =
        [ { '$ref' => '#/components/parameters/A' } ];
    Open::API->new(spec => $d);
};
ok(!$cycle, 'a ref cycle is refused rather than followed for ever');

# The four cases above all replace `parameters`, and a parameter is the one
# position that already failed on its own: oa_compile_params croaks on the
# absent `in`. So they passed before the refusal existed, and proved nothing
# about the other two positions - where an unresolvable ref was SILENT, the
# body left neither validated nor required. Every shape is repeated below
# against requestBody and response, and the message is asserted too: a croak
# for the wrong reason satisfies ok(!$x) just as well as the right one.

sub body_ref {
    my ($ref) = @_;
    my $d = ref_doc();
    $d->{paths}{'/things'}{post}{requestBody} = { '$ref' => $ref };
    return $d;
}

sub resp_ref {
    my ($ref) = @_;
    my $d = ref_doc();
    $d->{paths}{'/things'}{get}{responses} = { 200 => { '$ref' => $ref } };
    return $d;
}

for my $c (
    [ 'naming nothing',   '#/components/requestBodies/NoSuchThing' ],
    [ 'a deeper pointer', '#/components/requestBodies/Thing/content' ],
    [ 'a remote document','https://example.test/x.json#/components/requestBodies/Thing' ],
) {
    my ($what, $ref) = @$c;
    my $api = eval { Open::API->new(spec => body_ref($ref)) };
    my $err = $@;
    ok(!$api, "a requestBody \$ref $what is refused");
    like($err, qr/cannot resolve \$ref/,
         "...naming the reference, not some later symptom");
}

for my $c (
    [ 'naming nothing',   '#/components/responses/NoSuchThing' ],
    # into `Ok`, which DOES exist - otherwise this is a second "naming
    # nothing" case wearing a different name.
    [ 'a deeper pointer', '#/components/responses/Ok/description' ],
) {
    my ($what, $ref) = @$c;
    my $api = eval { Open::API->new(spec => resp_ref($ref)) };
    my $err = $@;
    ok(!$api, "a response \$ref $what is refused");
    like($err, qr/cannot resolve \$ref/, "...naming the reference");
}

# A cycle in a body position: the hop bound has to stop this too, and the
# leftover ref must be refused rather than compiled into an absent body.
my $body_cycle = eval {
    my $d = ref_doc();
    $d->{components}{requestBodies}{A} = { '$ref' => '#/components/requestBodies/B' };
    $d->{components}{requestBodies}{B} = { '$ref' => '#/components/requestBodies/A' };
    $d->{paths}{'/things'}{post}{requestBody} = { '$ref' => '#/components/requestBodies/A' };
    Open::API->new(spec => $d);
};
ok(!$body_cycle, 'a requestBody ref cycle is refused rather than followed for ever');

# ---- a $ref used AS a path item --------------------------------------------
#
# Legal in 3.0 and 3.1, and common in split documents. Nothing inlined it, so
# the item kept its $ref and carried no method keys: oa_compile found no
# operations, registered no route, and the path simply 404'd. Nothing in the
# document was malformed, so nothing complained - which is why the assertion
# that matters is that the route EXISTS, not that the document compiles.

{
    my $api = eval { Open::API->new(spec => {
        openapi => '3.1.0',
        info    => { title => 'T', version => '1.0.0' },
        paths   => { '/p' => { '$ref' => '#/components/pathItems/Thing' } },
        components => { pathItems => { Thing => {
            get => { operationId => 'via_path_item',
                     responses => { 200 => { description => 'ok' } } },
        } } },
    }) };
    ok($api, 'a document whose path item is a $ref compiles') or diag $@;
    if ($api) {
        my ($id) = $api->match(GET => '/p');
        is($id, 'via_path_item', 'and the route it names actually exists');
    }

    my $ghost = eval { Open::API->new(spec => {
        openapi => '3.1.0',
        info    => { title => 'T', version => '1.0.0' },
        paths   => { '/p' => { '$ref' => '#/components/pathItems/Ghost' } },
        components => {},
    }) };
    ok(!$ghost, 'a path item naming nothing is refused, not silently dropped');
    like($@, qr/cannot resolve \$ref/, '...naming the reference');
}

# ---- webhooks --------------------------------------------------------------
#
# Webhooks are calls the API SENDS, so they are deliberately not routed: zero
# operations is the CORRECT outcome and routing them would be a bug. What was
# wrong is that they were skipped by the normaliser entirely, so a 3.0 schema
# inside one stayed in the 3.0 dialect while ->spec claimed to be 3.1
# throughout. Both halves are asserted, because fixing one by breaking the
# other would look like a pass.

{
    my $api = eval { Open::API->new(spec => {
        openapi  => '3.0.3',
        info     => { title => 'T', version => '1.0.0' },
        paths    => {},
        webhooks => { newThing => { post => {
            operationId => 'wh_new_thing',
            requestBody => { content => { 'application/json' => {
                schema => { type => 'string', nullable => 1 } } } },
            responses   => { 200 => { description => 'ok' } },
        } } },
    }) };
    ok($api, 'a document with webhooks compiles') or diag $@;
    if ($api) {
        my $s = $api->spec->{webhooks}{newThing}{post}
                    {requestBody}{content}{'application/json'}{schema};
        is_deeply($s, { type => [ 'string', 'null' ] },
                  'a 3.0 schema inside a webhook is converted like any other');
        is(scalar @{ $api->operations }, 0,
           'and webhooks are NOT routed - they are calls the API sends');
    }
}

# ---- the document a consumer reads -----------------------------------------

my $spec = $reffed->spec;
my $p = $spec->{paths}{'/things'}{get}{parameters}[0];
is(ref $p, 'HASH', 'the parameter is an object in ->spec');
is($p->{name}, 'limit', '...inlined, not left as a $ref');
is($p->{in}, 'query', '...with its location');
ok(!exists $p->{'$ref'}, '...and the $ref is gone, which is what makes it idempotent');

my $rb = $spec->{paths}{'/things'}{post}{requestBody};
ok($rb->{content}{'application/json'}{schema}, 'the request body is inlined');
ok($rb->{required}, '...and its required flag survived');

# A reference's own annotations override the target's, which is what 3.1
# allows `summary` and `description` beside a $ref for.
my $over = eval {
    my $d = ref_doc();
    $d->{paths}{'/things'}{get}{parameters} =
        [ { '$ref' => '#/components/parameters/Limit',
            description => 'how many, at most' } ];
    Open::API->new(spec => $d);
};
ok($over, 'a ref carrying annotations compiles') or diag $@;
if ($over) {
    my $q = $over->spec->{paths}{'/things'}{get}{parameters}[0];
    is($q->{description}, 'how many, at most',
       "the reference's own description wins over the target's");
    is($q->{name}, 'limit', '...while the target supplies the rest');
}

# A response header given as a component ref is inlined too: oa_conv_response
# runs its `headers` map through the same converter as a parameter.
my $hdr = eval {
    my $d = ref_doc();
    $d->{components}{headers} =
        { XReq => { schema => { type => 'string' } } };
    $d->{paths}{'/things'}{get}{responses}{200} = {
        description => 'ok',
        headers     => { 'X-Request-Id' => { '$ref' => '#/components/headers/XReq' } },
    };
    Open::API->new(spec => $d);
};
ok($hdr, 'a response header given as a component ref compiles') or diag $@;
if ($hdr) {
    my $h = $hdr->spec->{paths}{'/things'}{get}{responses}{200}{headers}{'X-Request-Id'};
    ok($h->{schema}, 'and is inlined with its schema');
}

done_testing;
