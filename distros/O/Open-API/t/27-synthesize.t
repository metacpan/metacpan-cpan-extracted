#!perl
use 5.008003;
use strict;
use warnings;
use FindBin ();
use Test::More;
use Open::API;
use File::Raw::JSON qw(file_json_decode);

# Response synthesis: a body for an operation + status from the document
# alone, deterministic, and - the gate - never something the document's
# own validator would reject.

my $api = Open::API->new(spec => "$FindBin::Bin/spec/mock.json");

sub body_of {
    my ($trip) = @_;
    return $trip->[2][0];
}
sub data_of { file_json_decode(body_of($_[0])) }

# ---- precedence: example > examples[first] > default > generated ------------

{
    my $t = $api->synthesize('withExample');
    is($t->[0], 200, 'lowest declared 2xx by default');
    is_deeply(data_of($t), { id => 42, name => 'example-wins' },
        'the media example wins over examples and schema');
    my %h = @{ $t->[1] };
    is($h{'Content-Type'}, 'application/json', 'content type declared');
    is($h{'Content-Length'}, length(body_of($t)), 'content length measured');
}

{
    my $t = $api->synthesize('withNamed');
    is_deeply(data_of($t), { id => 1, name => 'alpha' },
        'no example: the first examples entry, by name, not by hash order');
}

{
    my $t = $api->synthesize('withDefault');
    is_deeply(data_of($t), { id => 7, name => 'from-default' },
        'no examples at all: the schema default');
}

# ---- generation from the schema ---------------------------------------------

{
    my $t = $api->synthesize('generated');
    is($t->[0], 201, 'the only declared 2xx');
    my $d = data_of($t);
    is($d->{state}, 'open', 'enum: the first member');
    is($d->{constant}, 'fixed', 'const: the value');
    is($d->{count}, 5, 'integer: minimum nudged onto multipleOf');
    cmp_ok($d->{ratio}, '>', 0.5, 'number: above its exclusiveMinimum');
    is($d->{when}, '1970-01-01T00:00:00Z', 'format date-time');
    is($d->{ident}, '00000000-0000-0000-0000-000000000000', 'format uuid');
    # minItems is a floor, not the count. An array generated at its
    # minimum is usually one or two elements, and one or two elements is
    # a shape nobody can build a table, a pagination control or an
    # empty state against - so the default is five and minItems only
    # raises it.
    is(scalar @{ $d->{tags} }, 5, 'an array is generated at five, over its minItems of two');
    ok(length $d->{tags}[0] >= 3, 'items honour minLength');
    is_deeply([ sort keys %{ $d->{nested} } ], [ 'id', 'name' ],
        '$ref resolved; required members only');
    is($d->{either}, 9, 'oneOf: generated from the first branch');
    is_deeply([ sort keys %{ $d->{combined} } ], [ 'a', 'b' ],
        'allOf: properties and required folded across members');
    ok(defined $d->{maybe}, 'type union: the first non-null type');
}

{
    my $t = $api->synthesize('noContent');
    is($t->[0], 204, 'a 204 is the declared status');
    is(body_of($t), '', 'and has no body');
    my %h = @{ $t->[1] };
    ok(!exists $h{'Content-Type'}, 'no content type for no content');
}

# ---- Prefer: status and named example selection -----------------------------

{
    my $t = $api->synthesize('withNamed', { code => 404 });
    is($t->[0], 404, 'code selects a declared status');
    is_deeply(data_of($t), { error => 'no such thing' },
        'and its own example body');

    $t = $api->synthesize('withNamed', { prefer => 'code=404' });
    is($t->[0], 404, 'a raw Prefer header selects it too');

    $t = $api->synthesize('withNamed', { prefer => ' code = "404" , foo' });
    is($t->[0], 404, 'quoted and spaced Prefer tokens parse');

    $t = $api->synthesize('withNamed', { example => 'beta' });
    is_deeply(data_of($t), { id => 2, name => 'beta' },
        'example selects a named example');

    $t = $api->synthesize('withNamed', { prefer => 'example=beta' });
    is_deeply(data_of($t), { id => 2, name => 'beta' },
        'Prefer: example=name does too');

    $t = $api->synthesize('withNamed', { prefer => 'example=nonesuch' });
    is_deeply(data_of($t), { id => 1, name => 'alpha' },
        'an unknown example name falls back down the precedence');

    $t = $api->synthesize('generated', { code => 418 });
    is($t->[0], 418, 'an undeclared preferred code is still answered');
    is_deeply(data_of($t), { error => 'synthesized from default' },
        'with the default response body when one is declared');

    $t = $api->synthesize('withExample', { code => 500 });
    is($t->[0], 500, 'undeclared code, no default response: the status');
    is(body_of($t), '', 'and an empty body rather than an invented one');

    $t = $api->synthesize('withExample', { prefer => 'code=999' });
    is($t->[0], 200, 'a status outside 100-599 is ignored as junk');
}

# ---- determinism: the same request gives byte-identical bodies --------------

{
    for my $op (qw(withExample withNamed withDefault generated)) {
        my $first = body_of($api->synthesize($op));
        my $same = 1;
        for (1 .. 99) {
            $same = 0, last if body_of($api->synthesize($op)) ne $first;
        }
        ok($same, "$op: 100 syntheses, byte-identical bodies");
    }
}

# ---- the property test: the mock cannot generate what its own validator
# ---- rejects, over every operation of whole specs ---------------------------

for my $spec (qw(mock.json petstore.json)) {
    my $checker = Open::API->new(spec => "$FindBin::Bin/spec/$spec");
    my $checked = 0;
    for my $op (@{ $checker->operations }) {
        my $id   = $op->{operationId};
        my $info = $checker->operation_info($id);

        # the default synthesis, and every status that declares a schema
        my @codes = (undef,
            map { $_->{status} =~ /^\d+$/ ? $_->{status} : () }
                grep { $_->{validated} } @{ $info->{responses} });
        my %seen;
        for my $code (@codes) {
            next if defined $code && $seen{$code}++;
            my $trip = $checker->synthesize($id,
                defined $code ? { code => $code } : ());
            my $errs = $checker->check_response($id, $trip, {});
            is($errs, undef,
                "$spec/$id" . (defined $code ? "/$code" : '')
                . ': synthesized body validates against its own schema')
                or diag explain $errs;
        }
        my $cov = $checker->response_coverage($id);
        $checked += $cov->{checked};
    }
    ok($checked > 0, "$spec: the property test actually decoded and "
        . "checked bodies ($checked), not skipped its way to a pass");
}

# ---- arrays: how many, and telling the elements apart -----------------------

# A one-operation document whose 200 has this schema. Composed rather
# than written out, because a wall of nested braces is how a fixture
# ends up testing something other than what it says it does.
sub doc_for {
    my (%ops) = @_;
    my %paths;
    for my $id (sort keys %ops) {
        my ($schema, $params) = @{ $ops{$id} };
        $paths{"/$id"} = { get => {
            operationId => $id,
            ($params ? (parameters => $params) : ()),
            responses => { 200 => {
                description => 'ok',
                content => { 'application/json' => { schema => $schema } },
            } },
        } };
    }
    return Open::API->new(spec => {
        openapi => '3.1.0',
        info    => { title => 'fixture', version => '1' },
        paths   => \%paths,
    });
}

my $PET = { type => 'object', required => [ 'id', 'name' ],
            properties => { id   => { type => 'integer' },
                            name => { type => 'string' } } };

{
    my $api = doc_for(
        listPets => [ { type => 'array', items => $PET } ],
        few      => [ { type => 'array', maxItems => 2,
                        items => { type => 'integer' } } ],
        none     => [ { type => 'array', maxItems => 0,
                        items => { type => 'integer' } } ],
        many     => [ { type => 'array', minItems => 9,
                        items => { type => 'integer' } } ],
    );

    my $list = data_of($api->synthesize('listPets'));
    is(scalar @$list, 5,
        'an array with nothing declared gets five elements - not zero, '
      . 'which validates and shows nothing');

    is_deeply([ map { $_->{id} } @$list ], [ 0 .. 4 ],
        'and the identifiers increment, so five rows are five rows '
      . 'rather than the same row five times');

    is(data_of($api->synthesize('listPets'))->[3]{id}, 3,
        'still deterministic: position, not a counter');

    is(scalar @{ data_of($api->synthesize('few')) },  2, 'maxItems caps it');
    is(scalar @{ data_of($api->synthesize('none')) }, 0,
        'maxItems: 0 means empty, and the document is believed');
    is(scalar @{ data_of($api->synthesize('many')) }, 9, 'minItems raises it');
}

# ---- the request, where it answers better than the schema -------------------
{
    my $strp = sub { [ { name => $_[0], in => 'path', required => 1,
                         schema => { type => 'string' } } ] };
    my $api = doc_for(
        showPet   => [ $PET, $strp->('petId') ],
        showThing => [ { type => 'object', required => [ 'name' ],
                         properties => { name => { type => 'string' } } },
                       $strp->('name') ],
        bounded   => [ { type => 'object', required => [ 'id' ],
                         properties => { id => { type => 'integer',
                                                 maximum => 100 } } },
                       $strp->('petId') ],
    );

    # `{petId}` naming the `id` of the thing it identifies is the
    # convention every REST document uses, so it is the one case matched
    # across a change of name
    is(data_of($api->synthesize('showPet', { path => { petId => '42' } }))->{id},
       42, 'GET /pets/42 answers with id 42, not the schema placeholder');

    is(data_of($api->synthesize('showThing', { path => { name => 'rex' } }))->{name},
       'rex', 'a capture and a property of the same name match directly');

    # the guarantee that outranks convenience: the mock may not generate
    # something its own validator would reject
    is(data_of($api->synthesize('showPet', { path => { petId => 'abc' } }))->{id},
       0, 'a capture that will not fit the type falls back to the schema');

    is(data_of($api->synthesize('bounded', { path => { petId => '9999' } }))->{id},
       0, '...and one outside the declared bounds does too');

    is(data_of($api->synthesize('showPet'))->{id}, 0,
        'with no captures at all it generates, exactly as before');

    is(data_of($api->synthesize('showPet', { path => { petId => '7' } }))->{id},
       data_of($api->synthesize('showPet', { path => { petId => '7' } }))->{id},
       'the same request still gives the same body');
}

done_testing;
