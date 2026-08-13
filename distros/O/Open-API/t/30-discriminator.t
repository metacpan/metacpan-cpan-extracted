#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;
use Open::API;

# `discriminator`, in both the forms OpenAPI defines (include/oa_normalize.h).
#
# Once a schema is compiled, JSON::Schema::Fast owns the traversal - C cannot
# step in partway down to choose a branch - so the discriminator is expanded at
# load into constructs 2020-12 already has: a guard that the property is present
# and names a known branch, then one if/then per branch. These tests assert the
# behaviour that expansion buys, and the diagnostics, because a discriminator
# whose only effect is a bare "failed oneOf" is not worth having.

# One POST whose body is $ref'd to `$root`, with `%schemas` as components.
sub api_for {
    my ($root, %schemas) = @_;
    return Open::API->new(spec => {
        openapi => '3.1.0',
        info    => { title => 'T', version => '1.0.0' },
        paths   => { '/t' => {
            post => {
                operationId => 'post_t',
                requestBody => { required => 1, content => {
                    'application/json' => {
                        schema => { '$ref' => "#/components/schemas/$root" } } } },
                responses => { 200 => { description => 'ok', content => {
                    'application/json' => {
                        schema => { '$ref' => "#/components/schemas/$root" } } } } },
            },
        } },
        components => { schemas => \%schemas },
    });
}

sub verdict {
    my ($api, $json) = @_;
    my ($ok, $res) = $api->validate_request('post_t', {
        header => { 'content-type' => 'application/json' },
        body   => $json,
    });
    return $ok ? 'accept' : ($res->[0]{keyword} || '?');
}

# ---- form A: a discriminated union ----------------------------------------

my %union = (
    PetUnion => {
        oneOf => [ { '$ref' => '#/components/schemas/Dog' },
                   { '$ref' => '#/components/schemas/Cat' } ],
        discriminator => { propertyName => 'petType',
                           mapping => { dog => 'Dog', cat => 'Cat' } },
    },
    Dog => { type => 'object', required => ['petType', 'bark'],
             properties => { petType => { type => 'string' },
                             bark    => { type => 'string' } } },
    Cat => { type => 'object', required => ['petType', 'meow'],
             properties => { petType => { type => 'string' },
                             meow    => { type => 'string' } } },
);

{
    my $api = api_for('PetUnion', %union);

    is(verdict($api, '{"petType":"dog","bark":"woof"}'), 'accept', 'a valid dog');
    is(verdict($api, '{"petType":"cat","meow":"mew"}'),  'accept', 'a valid cat');

    # the point of a discriminator: the payload is weighed against the branch
    # it named, so the error is about that branch and not about the union
    is(verdict($api, '{"petType":"dog"}'), 'required',
       'a dog missing a dog field fails on that field, not on oneOf');
    is(verdict($api, '{"petType":"cat","bark":"woof"}'), 'required',
       'a cat carrying dog fields is still judged as a cat');

    is(verdict($api, '{"petType":"hamster"}'), 'enum',
       'an unmapped discriminator value is rejected by the guard');
    is(verdict($api, '{"bark":"woof"}'), 'required',
       'a missing discriminator property is rejected');

    # the error names the property, which is the whole point of the guard
    my (undef, $errs) = $api->validate_request('post_t', {
        header => { 'content-type' => 'application/json' },
        body   => '{"petType":"hamster"}' });
    like($errs->[0]{instanceLocation}, qr{petType},
         'the unknown-value error points at the discriminator property');
}

# an implicit mapping: no `mapping`, keys are the schema names
{
    my %s = %union;
    $s{PetUnion} = { oneOf => $union{PetUnion}{oneOf},
                     discriminator => { propertyName => 'petType' } };
    my $api = api_for('PetUnion', %s);

    is(verdict($api, '{"petType":"Dog","bark":"woof"}'), 'accept',
       'an implicit mapping keys on the schema name');
    is(verdict($api, '{"petType":"dog","bark":"woof"}'), 'enum',
       'and is case-sensitive, as the document wrote it');

    is_deeply($api->spec->{components}{schemas}{PetUnion}{discriminator}{mapping},
              { Dog => '#/components/schemas/Dog',
                Cat => '#/components/schemas/Cat' },
              'the derived mapping is written back, in full pointer form');
}

# a union whose branches are not all plain $refs cannot be keyed on anything
{
    my %s = %union;
    $s{PetUnion} = { oneOf => [ { '$ref' => '#/components/schemas/Dog' },
                                { type => 'object' } ],
                     discriminator => { propertyName => 'petType' } };
    my $api = api_for('PetUnion', %s);
    ok(!exists $api->spec->{components}{schemas}{PetUnion}{allOf},
       'a mixed union is left alone');
    is_deeply($api->spec->{components}{schemas}{PetUnion}{oneOf},
              $s{PetUnion}{oneOf}, 'and keeps its oneOf');
}

# ---- form B: inheritance ---------------------------------------------------

my %tree = (
    Pet => { type => 'object', required => ['petType', 'name'],
             properties => { petType => { type => 'string' },
                             name    => { type => 'string' } },
             discriminator => { propertyName => 'petType' } },
    Dog => { allOf => [ { '$ref' => '#/components/schemas/Pet' },
                        { type => 'object', required => ['bark'],
                          properties => { bark => { type => 'string' } } } ] },
    Cat => { allOf => [ { '$ref' => '#/components/schemas/Pet' },
                        { type => 'object', required => ['meow'],
                          properties => { meow => { type => 'string' } } } ] },
);

{
    my $api = api_for('Pet', %tree);

    is(verdict($api, '{"petType":"Dog","name":"Rex","bark":"woof"}'), 'accept',
       'a valid Dog validated against the base');
    is(verdict($api, '{"petType":"Cat","name":"Tom","meow":"mew"}'), 'accept',
       'a valid Cat validated against the base');

    # without the discriminator this would pass: the base alone is satisfied
    is(verdict($api, '{"petType":"Dog","name":"Rex"}'), 'required',
       'the base now enforces what the child adds');
    is(verdict($api, '{"petType":"Fish","name":"Nemo"}'), 'enum',
       'a type with no schema is rejected');

    is_deeply($api->spec->{components}{schemas}{Pet}{discriminator}{mapping},
              { Dog => '#/components/schemas/Dog',
                Cat => '#/components/schemas/Cat' },
              'the children are found by their allOf reference to the base');
}

# The recursion the inheritance form invites: the base dispatches to the child,
# and the child inherits the base. Validating against the CHILD has to
# terminate - which is why the generated `then` inlines the child's own
# constraints rather than naming it.
{
    my $api = api_for('Dog', %tree);
    is(verdict($api, '{"petType":"Dog","name":"Rex","bark":"woof"}'), 'accept',
       'a Dog validated against Dog terminates');
    is(verdict($api, '{"petType":"Dog","name":"Rex"}'), 'required',
       'and still enforces the child');

    my $then = $api->spec->{components}{schemas}{Pet}{allOf}[1]{then};
    ok(!exists $then->{'$ref'},
       'the generated then does not name the child (that would loop)');
}

# a base nobody inherits from, and no mapping: nothing to expand
{
    my $api = api_for('Pet', Pet => $tree{Pet});
    ok(!exists $api->spec->{components}{schemas}{Pet}{allOf},
       'a childless base is left as an annotation');
    is(verdict($api, '{"petType":"anything","name":"x"}'), 'accept',
       'and constrains nothing beyond itself');
}

# ---- the mock generator agrees with the validator --------------------------
# oa_mock.h walks the document, so it has to know about the discriminator too:
# folding the generated if/then chain would produce a body its own schema
# rejects, and in the inheritance form would recurse base -> child -> base.
{
    for my $case (['union', 'PetUnion', \%union], ['inheritance', 'Pet', \%tree]) {
        my ($what, $root, $schemas) = @$case;
        my $api  = api_for($root, %$schemas);
        my $trip = $api->synthesize('post_t');
        ok($trip, "$what: synthesizes");
        my $errs = $api->check_response('post_t', $trip);
        ok(!$errs, "$what: the synthesized body validates against its own schema")
            or diag(explain($errs));
        is(join('', @{ $api->synthesize('post_t')->[2] }),
           join('', @{ $trip->[2] }), "$what: deterministic");
    }
}

# ---- idempotency -----------------------------------------------------------
# The expansion is regenerated on every pass - previously generated members are
# recognised by their marker and dropped first - so a normalised document fed
# back through new() must come out identical.
{
    for my $case (['union', 'PetUnion', \%union], ['inheritance', 'Pet', \%tree]) {
        my ($what, $root, $schemas) = @$case;
        my $one   = api_for($root, %$schemas);
        my $two   = Open::API->new(spec => $one->spec);
        my $three = Open::API->new(spec => $two->spec);
        is_deeply($two->spec,   $one->spec, "$what: a second pass changes nothing");
        is_deeply($three->spec, $one->spec, "$what: nor does a third");
        is(verdict($two, '{"petType":"Dog","name":"Rex","bark":"woof"}'),
           verdict($one, '{"petType":"Dog","name":"Rex","bark":"woof"}'),
           "$what: and behaves the same");
    }
}

# ---- 3.0 documents get the same treatment ----------------------------------
# `discriminator` is spelled identically in 3.0, and the two passes have to
# compose: the union members are converted AND the chain is generated.
{
    my $api = Open::API->new(spec => {
        openapi => '3.0.3',
        info    => { title => 'T', version => '1.0.0' },
        paths   => { '/t' => { post => {
            operationId => 'post_t',
            requestBody => { required => 1, content => { 'application/json' => {
                schema => { '$ref' => '#/components/schemas/PetUnion' } } } },
            responses => { 200 => { description => 'ok' } },
        } } },
        components => { schemas => {
            PetUnion => {
                oneOf => [ { '$ref' => '#/components/schemas/Dog' },
                           { '$ref' => '#/components/schemas/Cat' } ],
                discriminator => { propertyName => 'petType',
                                   mapping => { dog => 'Dog', cat => 'Cat' } } },
            Dog => { type => 'object', required => ['petType', 'bark'],
                     properties => { petType => { type => 'string' },
                                     bark    => { type => 'string',
                                                  nullable => \1 } } },
            Cat => { type => 'object', required => ['petType', 'meow'],
                     properties => { petType => { type => 'string' },
                                     meow    => { type => 'string' } } },
        } },
    });

    is(verdict($api, '{"petType":"dog","bark":"woof"}'), 'accept',
       '3.0: a valid dog');
    is(verdict($api, '{"petType":"dog","bark":null}'), 'accept',
       '3.0: nullable inside a discriminated branch still converts');
    is(verdict($api, '{"petType":"cat","meow":null}'), 'type',
       '3.0: and a non-nullable one still rejects null');
    is(verdict($api, '{"petType":"hamster"}'), 'enum',
       '3.0: an unmapped value is rejected');
}

done_testing();
