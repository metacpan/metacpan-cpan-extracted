#!perl
use 5.008003;
use strict;
use warnings;
use FindBin ();
use Test::More;
use Open::API;
use JSON::Schema::Fast;

# operation_doc and operation_schema (lib/Open/API/Tools.pm).
#
# The compiled table cannot answer either question: operation_info reports
# whether a schema is attached, not what it is, and carries no summary,
# description or tags. Both are assembled from ->spec instead.
#
# The load-bearing property is that what comes out is real JSON Schema
# 2020-12 - so the strongest test here is simply that JSON::Schema::Fast
# compiles it, for every operation of every fixture. That is not a formality:
# a schema with an unresolvable $ref throws, so this is exactly what catches a
# $defs block pruned too hard.

# ---- a document with everything worth reading ------------------------------

my $api = Open::API->new(spec => {
    openapi => '3.1.0',
    info    => { title => 'T', version => '1.0.0' },
    paths   => {
        '/pets/{petId}' => {
            parameters => [
                { name => 'petId', in => 'path', required => 1,
                  description => 'which pet',
                  schema => { type => 'string' } },
            ],
            get => {
                operationId => 'get_pet',
                summary     => 'Fetch one pet',
                description => 'The long version.',
                tags        => ['pets'],
                'x-mcp'     => { title => 'Fetch a pet' },
                parameters  => [
                    { name => 'verbose', in => 'query',
                      schema => { type => 'boolean' } },
                ],
                responses => { 200 => { description => 'ok' } },
            },
            post => {
                operationId => 'update_pet',
                requestBody => {
                    required => 1,
                    content  => { 'application/json' => {
                        schema => { '$ref' => '#/components/schemas/Pet' } } },
                },
                responses => { 200 => { description => 'ok' } },
            },
        },
    },
    components => {
        schemas => {
            Pet => {
                type       => 'object',
                properties => { name => { type => 'string' },
                                tag  => { '$ref' => '#/components/schemas/Tag' } },
                required   => ['name'],
            },
            Tag    => { type => 'string' },
            Unused => { type => 'object' },
        },
    },
});

# ---- operation_doc ---------------------------------------------------------

my $doc = $api->operation_doc('get_pet');
is(ref $doc, 'HASH', 'operation_doc returns a hashref');
is($doc->{summary}, 'Fetch one pet', 'summary');
is($doc->{description}, 'The long version.', 'description');
is($doc->{method}, 'GET', 'method, upper cased');
is($doc->{path}, '/pets/{petId}', 'path');
is_deeply($doc->{tags}, ['pets'], 'tags');
is($doc->{deprecated}, 0, 'deprecated defaults to false');
is_deeply($doc->{'x-mcp'}, { title => 'Fetch a pet' },
          'x- extension keys are carried through');
is($api->operation_doc('nope'), undef, 'undef for an unknown operationId');

# ---- operation_schema ------------------------------------------------------

my $get = $api->operation_schema('get_pet');
is($get->{type}, 'object', 'a schema object');
is(ref $get->{properties}, 'HASH', 'with properties');

# A path-item parameter and an operation parameter both appear, which is the
# same merge oa_compile_params does - a tool that disagreed with the validator
# about which inputs exist would fail validation it could not have predicted.
ok($get->{properties}{petId},   'the path-item parameter is a property');
ok($get->{properties}{verbose}, 'the operation parameter is a property');
is($get->{properties}{petId}{type}, 'string', 'with its own type');
is_deeply($get->{required}, ['petId'], 'only the required one is required');

# The prose lives on the parameter, not its schema, and it is the only thing
# telling two same-typed parameters apart.
is($get->{properties}{petId}{description}, 'which pet',
   "the parameter's description is carried onto its schema");

is($api->operation_schema('nope'), undef, 'undef for an unknown operationId');

# ---- body, refs and $defs --------------------------------------------------

my $post = $api->operation_schema('update_pet');
ok($post->{properties}{body}, 'a JSON request body becomes the body property');
ok((grep { $_ eq 'body' } @{ $post->{required} || [] }),
   'a required body is required');

is($post->{properties}{body}{'$ref'}, '#/$defs/Pet',
   'a components.schemas ref is rewritten to $defs');
ok($post->{'$defs'}{Pet}, 'the referenced schema is carried');
ok($post->{'$defs'}{Tag}, '...and so is one it reaches transitively');
ok(!$post->{'$defs'}{Unused},
   '...while a schema this operation cannot reach is left out');
is($post->{'$defs'}{Pet}{properties}{tag}{'$ref'}, '#/$defs/Tag',
   'refs inside a carried schema are rewritten too');

# Nothing anywhere may still point at components.schemas, or a compile throws.
my $json = do {
    my $seen = '';
    my $walk; $walk = sub {
        my ($n) = @_;
        if (ref $n eq 'HASH')  { $walk->($_) for values %$n; return }
        if (ref $n eq 'ARRAY') { $walk->($_) for @$n; return }
        $seen .= " $n" if defined $n && !ref $n;
    };
    $walk->($post);
    $seen;
};
unlike($json, qr{\#/components/schemas/}, 'no unrewritten component ref remains');

# ---- it is real JSON Schema ------------------------------------------------

my $compiled = eval { JSON::Schema::Fast->compile($post) };
ok($compiled, 'the assembled schema compiles under JSON::Schema::Fast')
    or diag $@;

if ($compiled) {
    ok($compiled->is_valid({ petId => 'abc', body => { name => 'rex' } }),
       'valid arguments validate');
    ok(!$compiled->is_valid({ petId => 'abc', body => { tag => 'dog' } }),
       'a body missing its required property does not');
    ok(!$compiled->is_valid({ body => { name => 'rex' } }),
       'a missing required parameter does not');
}

# ---- the collision ---------------------------------------------------------

my $coll = Open::API->new(spec => {
    openapi => '3.1.0',
    info    => { title => 'T', version => '1.0.0' },
    paths   => { '/x' => { post => {
        operationId => 'clash',
        parameters  => [ { name => 'body', in => 'query',
                           schema => { type => 'string' } } ],
        requestBody => { content => { 'application/json' =>
                           { schema => { type => 'object' } } } },
        responses   => { 200 => { description => 'ok' } },
    } } },
});
my $cs = $coll->operation_schema('clash');
ok($cs->{properties}{param_body}, 'a parameter named body is carried as param_body');
ok($cs->{properties}{body},       '...leaving body for the request body');
like($cs->{properties}{param_body}{description}, qr/\bbody\b/,
     '...and saying so in its description');

# ---- every operation of every fixture --------------------------------------

for my $file (sort glob "$FindBin::Bin/spec/*.json") {
    my $name = $file; $name =~ s{.*/}{};
    my $a = eval { Open::API->new(spec => $file) };
    if (!$a) { fail("$name compiles"); diag $@; next }
    my $ops = $a->operations;
    my $bad = 0;
    for my $op (@$ops) {
        my $id = $op->{operationId};
        next unless defined $id && length $id;
        my $s = $a->operation_schema($id);
        if (!$s) { $bad++; diag("$name: no schema for $id"); next }
        my $c = eval { JSON::Schema::Fast->compile($s) };
        if (!$c) { $bad++; diag("$name / $id: $@") }
    }
    is($bad, 0, "$name: every operation's schema compiles (" . @$ops . " operations)");
}

# ---- the 3.0 twin ----------------------------------------------------------
#
# A 3.0 document is up-converted at load, so the same operation should present
# the same inputs whichever dialect it was written in. Compared by shape - the
# property names and the required set - because annotations legitimately
# differ between the two spellings.

my $v30 = eval { Open::API->new(spec => "$FindBin::Bin/spec/petstore-3.0.json") };
my $v31 = eval { Open::API->new(spec => "$FindBin::Bin/spec/petstore-3.1-twin.json") };
SKIP: {
    skip 'petstore twins not both present', 1 unless $v30 && $v31;
    my $same = 1;
    for my $op (@{ $v30->operations }) {
        my $id = $op->{operationId};
        next unless defined $id;
        my $a = $v30->operation_schema($id) or next;
        my $b = $v31->operation_schema($id) or next;
        my @pa = sort keys %{ $a->{properties} || {} };
        my @pb = sort keys %{ $b->{properties} || {} };
        $same = 0, diag("$id properties: @pa vs @pb") if "@pa" ne "@pb";
        my $ra = join ',', sort @{ $a->{required} || [] };
        my $rb = join ',', sort @{ $b->{required} || [] };
        $same = 0, diag("$id required: $ra vs $rb") if $ra ne $rb;
    }
    ok($same, 'the 3.0 and 3.1 twins present the same inputs');
}

# ---- a $ref pointing INTO a component schema -------------------------------
#
# `#/components/schemas/A/properties/b` is a pointer into A, not a schema
# named "A/properties/b". The pruner keyed the whole remainder as a def name,
# missed, and stored an EMPTY schema under that literal key - and {} is valid
# JSON Schema that accepts anything, so the result compiled and then validated
# nothing. The assertion that catches that is the last one here, not the
# structural ones: an always-true schema passes every compile check.

{
    my $nested = Open::API->new(spec => {
        openapi => '3.1.0',
        info    => { title => 'T', version => '1.0.0' },
        paths   => { '/x' => { post => {
            operationId => 'nested_ref',
            requestBody => { required => 1, content => { 'application/json' => {
                schema => { '$ref' => '#/components/schemas/A/properties/b' } } } },
            responses   => { 200 => { description => 'ok' } },
        } } },
        components => { schemas => {
            A => { type => 'object', properties => { b => { type => 'integer' } } },
        } },
    });

    my $s = $nested->operation_schema('nested_ref');
    is_deeply([ sort keys %{ $s->{'$defs'} || {} } ], ['A'],
              'a pointer into a component carries the component it points into');
    is($s->{properties}{body}{'$ref'}, '#/$defs/A/properties/b',
       '...with the pointer itself left intact');

    my $jsf = JSON::Schema::Fast->compile($s);
    ok($jsf, 'the result still compiles');
    ok($jsf->is_valid({ body => 7 }), 'and accepts a value matching the target');
    ok(!$jsf->is_valid({ body => 'not-an-int' }),
       'and REJECTS one that does not - an empty $defs entry would accept it');
}

done_testing;
