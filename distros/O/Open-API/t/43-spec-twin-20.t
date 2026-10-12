#!perl
use 5.008003;
use strict;
use warnings;
use FindBin ();
use Test::More;
use Open::API;

# The official Swagger 2.0 petstore-expanded and its HAND-WRITTEN 3.0 twin must
# behave identically. The twin of t/29-spec-twin-30.t.
#
# t/42-swagger2.t checks each conversion rule on its own; this is a whole
# document at once, against a twin nobody generated: it was written from the
# specification and the plan's field map BEFORE the pre-pass's output was looked
# at, so if the conversion drifts from what a human writes in 3.0, one of these
# diverges. The 2.0 document is the OpenAPI Initiative's own (see
# t/compliance/swagger2/README), copied to t/spec/ so t/33's glob compiles its
# operation schemas too.

my $v20 = Open::API->new(spec => "$FindBin::Bin/spec/petstore-2.0.json");
my $v30 = Open::API->new(spec => "$FindBin::Bin/spec/petstore-2.0-twin-30.json");

is($v20->openapi_version, '2.0',   'the 2.0 twin knows what it was');
is($v30->openapi_version, '3.0.3', 'the 3.0 twin knows what it is');

# ---- the root --------------------------------------------------------------

is_deeply($v20->spec->{servers}, [ { url => 'http://petstore.swagger.io/api' } ],
          'host, basePath and schemes became the one server the twin declares');
is_deeply([ sort keys %{ $v20->spec->{components}{schemas} } ],
          [ sort keys %{ $v30->spec->{components}{schemas} } ],
          'definitions became the same component schemas');
ok(!exists $v20->spec->{$_}, "no 2.0 root key '$_' survives")
    for qw(host basePath schemes consumes produces definitions);

# ---- the operation table ---------------------------------------------------

my @o20 = sort { $a->{operationId} cmp $b->{operationId} } @{ $v20->operations };
my @o30 = sort { $a->{operationId} cmp $b->{operationId} } @{ $v30->operations };
is_deeply(\@o20, \@o30, 'same operations from both twins');

for my $id (map { $_->{operationId} } @o30) {
    my ($a, $b) = ($v20->operation($id), $v30->operation($id));
    for my $o ($a, $b) {
        @{ $o->{body}{content} } = sort @{ $o->{body}{content} }
            if $o->{body} && $o->{body}{content};
        @{ $o->{responses} } = sort @{ $o->{responses} } if $o->{responses};
    }
    is_deeply($a, $b, "operation($id) identical");
}

# ---- request bodies --------------------------------------------------------

my @bodies = (
    [ 'a minimal pet',      { name => 'Rex' },                1 ],
    [ 'a tagged pet',       { name => 'Rex', tag => 'good' }, 1 ],
    [ 'no name',            { tag => 'good' },                0 ],
    [ 'a wrong-typed name', { name => 42 },                   0 ],
);
for my $case (@bodies) {
    my ($what, $body, $want) = @$case;
    my $got20 = $v20->_body_check('addPet', 'application/json', $body) ? 1 : 0;
    my $got30 = $v30->_body_check('addPet', 'application/json', $body) ? 1 : 0;
    is($got20, $want,  "body: $what");
    is($got20, $got30, "body: $what - twins agree");
}

# ---- parameters ------------------------------------------------------------

my @params = (
    [ 'an integer limit',     'findPets',       'query', 'limit', '10',  1 ],
    [ 'a non-numeric limit',  'findPets',       'query', 'limit', 'x',   0 ],
    [ 'a pet id',             'find pet by id', 'path',  'id',    '7',   1 ],
    [ 'a non-numeric pet id', 'find pet by id', 'path',  'id',    'x',   0 ],
    [ 'an id to delete',      'deletePet',      'path',  'id',    '3',   1 ],
);
for my $case (@params) {
    my ($what, $op, $in, $name, $value, $want) = @$case;
    my $got20 = $v20->_param_check($op, $in, $name, $value) ? 1 : 0;
    my $got30 = $v30->_param_check($op, $in, $name, $value) ? 1 : 0;
    is($got20, $want,  "param: $what");
    is($got20, $got30, "param: $what - twins agree");
}

# the csv tags array: 2.0's default collectionFormat is csv, which the twin
# spells as form + explode false, and both must read `a,b` as two tags
for my $api ([ '2.0', $v20 ], [ '3.0', $v30 ]) {
    my ($ok, $res) = $api->[1]->validate_request(findPets => { query => 'tags=a,b&limit=5' });
    ok($ok, "$api->[0]: the csv tags query validates");
    is_deeply($res->{query}{tags}, [ 'a', 'b' ], "$api->[0]: ...and splits on the comma");
    is($res->{query}{limit}, 5, "$api->[0]: ...with limit coerced");
}

# ---- responses -------------------------------------------------------------

my @responses = (
    [ 'a whole pet',      '{"id":1,"name":"Rex","tag":"good"}', 1 ],
    [ 'a missing name',   '{"id":1}',                           0 ],
    [ 'a missing id',     '{"name":"Rex"}',                     0 ],
    [ 'a string id',      '{"id":"1","name":"Rex"}',            0 ],
);
for my $case (@responses) {
    my ($what, $json, $want) = @$case;
    my $trip = [200, ['Content-Type' => 'application/json'], [$json]];
    my $e20 = $v20->check_response('find pet by id', $trip) ? 0 : 1;
    my $e30 = $v30->check_response('find pet by id', $trip) ? 0 : 1;
    is($e20, $want, "response: $what");
    is($e20, $e30,  "response: $what - twins agree");
}

# the default response, selected for a status nothing else declares
{
    my $trip = [418, ['Content-Type' => 'application/json'], ['{"wrong":1}']];
    my $e20 = $v20->check_response('findPets', $trip);
    my $e30 = $v30->check_response('findPets', $trip);
    ok($e20 && @$e20, 'the default response schema refuses a wrong error body');
    is(!!($e20 && @$e20), !!($e30 && @$e30), '...in both twins');
}

# ---- the mock generator agrees with the validator ----------------------------
# oa_mock.h walks the document rather than the compiled handles, which is why
# the conversion had to happen at document level.
for my $id ('findPets', 'find pet by id', 'addPet') {
    my $trip = $v20->synthesize($id, {});
    ok($trip, "$id: the 2.0 document synthesizes a response");
    my $errs = $v20->check_response($id, $trip);
    ok(!$errs, "$id: and the synthesized body validates against its own schema")
        or diag(explain($errs));
}

# ---- and the tools see one document --------------------------------------------
for my $id ('findPets', 'addPet') {
    my $a = $v20->operation_schema($id);
    my $b = $v30->operation_schema($id);
    is_deeply([ sort keys %{ $a->{properties} || {} } ],
              [ sort keys %{ $b->{properties} || {} } ],
              "operation_schema($id): the same inputs from both twins");
}

done_testing();
