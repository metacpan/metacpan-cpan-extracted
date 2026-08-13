#!perl
use 5.008003;
use strict;
use warnings;
use FindBin ();
use Test::More;
use Open::API;

# A 3.0 petstore and its hand-written 3.1 equivalent must behave identically.
#
# t/28-openapi30.t checks each conversion rule on its own; this is the whole
# document at once, against a twin nobody generated - if the up-conversion
# drifts from what a human would have written in 3.1, one of these diverges.

my $v30 = Open::API->new(spec => "$FindBin::Bin/spec/petstore-3.0.json");
my $v31 = Open::API->new(spec => "$FindBin::Bin/spec/petstore-3.1-twin.json");

is($v30->openapi_version, '3.0.3', 'the 3.0 twin knows what it was');
is($v31->openapi_version, '3.1.0', 'the 3.1 twin knows what it is');

# ---- the operation table ---------------------------------------------------

my @o30 = sort { $a->{operationId} cmp $b->{operationId} } @{ $v30->operations };
my @o31 = sort { $a->{operationId} cmp $b->{operationId} } @{ $v31->operations };
is_deeply(\@o30, \@o31, 'same operations from both twins');

for my $id (map { $_->{operationId} } @o31) {
    my ($a, $b) = ($v30->operation($id), $v31->operation($id));
    # content-type / status order comes from a hash walk - normalise it
    for my $o ($a, $b) {
        @{ $o->{body}{content} } = sort @{ $o->{body}{content} }
            if $o->{body} && $o->{body}{content};
        @{ $o->{responses} } = sort @{ $o->{responses} } if $o->{responses};
    }
    is_deeply($a, $b, "operation($id) identical");
}

# ---- request bodies --------------------------------------------------------

my @bodies = (
    [ 'a minimal pet',        { name => 'Rex' },                        1 ],
    [ 'a null tag',           { name => 'Rex', tag => undef },          1 ],
    [ 'a string tag',         { name => 'Rex', tag => 'good' },         1 ],
    [ 'no name',              { tag => 'good' },                        0 ],
    [ 'an empty name',        { name => '' },                           0 ],
    [ 'a wrong-typed name',   { name => 42 },                           0 ],
);

for my $case (@bodies) {
    my ($what, $body, $want) = @$case;
    my $got30 = $v30->_body_check('createPet', 'application/json', $body) ? 1 : 0;
    my $got31 = $v31->_body_check('createPet', 'application/json', $body) ? 1 : 0;
    is($got30, $want,  "body: $what");
    is($got30, $got31, "body: $what - twins agree");
}

# ---- parameters ------------------------------------------------------------

my @params = (
    [ 'limit at the exclusive bound', 'listPets', 'query', 'limit', '1',   0 ],
    [ 'limit above it',               'listPets', 'query', 'limit', '2',   1 ],
    [ 'limit at the maximum',         'listPets', 'query', 'limit', '100', 1 ],
    [ 'limit over the maximum',       'listPets', 'query', 'limit', '101', 0 ],
    [ 'a petId',                      'getPet',   'path',  'petId', '7',   1 ],
    [ 'a non-numeric petId',          'getPet',   'path',  'petId', 'x',   0 ],
);

for my $case (@params) {
    my ($what, $op, $in, $name, $value, $want) = @$case;
    my $got30 = $v30->_param_check($op, $in, $name, $value) ? 1 : 0;
    my $got31 = $v31->_param_check($op, $in, $name, $value) ? 1 : 0;
    is($got30, $want,  "param: $what");
    is($got30, $got31, "param: $what - twins agree");
}

# ---- responses (the Pet schema, where most of the conversion lives) --------

my @responses = (
    [ 'a whole pet',
      '{"id":1,"name":"Rex","tag":"good","photo":"AA==","owner":{"name":"Ann"},'
      . '"score":["a",1,true]}',                                          1 ],
    [ 'a null tag',        '{"id":1,"name":"Rex","tag":null}',             1 ],
    [ 'a null owner',      '{"id":1,"name":"Rex","owner":null}',           1 ],
    [ 'an owner object',   '{"id":1,"name":"Rex","owner":{"name":"Ann"}}', 1 ],
    [ 'an invalid owner',  '{"id":1,"name":"Rex","owner":{}}',             0 ],
    [ 'id at the exclusive bound', '{"id":0,"name":"Rex"}',                0 ],
    [ 'a missing name',    '{"id":1}',                                     0 ],
    [ 'a tuple in order',  '{"id":1,"name":"R","score":["a",1]}',          1 ],
    [ 'a tuple out of order', '{"id":1,"name":"R","score":[1,"a"]}',       0 ],
    [ 'a bad tuple tail',  '{"id":1,"name":"R","score":["a",1,"no"]}',     0 ],
);

for my $case (@responses) {
    my ($what, $json, $want) = @$case;
    my $trip = [200, ['Content-Type' => 'application/json'], [$json]];
    my $e30 = $v30->check_response('getPet', $trip) ? 0 : 1;
    my $e31 = $v31->check_response('getPet', $trip) ? 0 : 1;
    is($e30, $want, "response: $what");
    is($e30, $e31,  "response: $what - twins agree");
}

# ---- and the mock generator agrees with the validator ----------------------
# oa_mock.h walks the document rather than the compiled handles, so this is
# what proves the conversion had to happen at document level.
{
    my $trip = $v30->synthesize('getPet', {});
    ok($trip, 'the 3.0 spec synthesizes a response');
    my $errs = $v30->check_response('getPet', $trip);
    ok(!$errs, 'and the synthesized body validates against its own schema')
        or diag(explain($errs));
}

done_testing();
