#!perl
use 5.008003;
use strict;
use warnings;
use FindBin ();
use Test::More;
use Open::API;

# The compiled JSF handles actually validate - including through
# #/components/... $refs (the schemas are wrapped with the spec's components
# at compile time) and with coercion on string-sourced parameters.

my $api = Open::API->new(spec => "$FindBin::Bin/spec/petstore.json");

# ---- body via $ref #/components/schemas/NewPet ------------------------------
is($api->_body_check('createPet', 'application/json', { name => 'rex' }), 1,
    'valid body through a components $ref');
is($api->_body_check('createPet', 'application/json', { name => '' }), 0,
    'minLength inside the referenced schema enforced');
is($api->_body_check('createPet', 'application/json', { tag => 'x' }), 0,
    'required inside the referenced schema enforced');
is($api->_body_check('createPet', 'text/plain', 'anything'), -2,
    'non-json content type is pass-through (no schema)');
is($api->_body_check('createPet', 'application/xml', {}), -1,
    'undeclared content type unknown');

# ---- parameters (coerce=1: string sources satisfy typed schemas) ------------
is($api->_param_check('getPet', 'path', 'petId', '5'), 1,
    'string "5" coerces to integer for a path param');
is($api->_param_check('getPet', 'path', 'petId', 'abc'), 0,
    'non-numeric string fails the integer schema');
is($api->_param_check('listPets', 'query', 'limit', '50'), 1,
    'query limit within range');
is($api->_param_check('listPets', 'query', 'limit', '500'), 0,
    'query limit over maximum fails');
is($api->_param_check('getPet', 'header', 'X-Request-Id', 'abcd'), 1,
    'header param minLength ok');
is($api->_param_check('getPet', 'header', 'X-Request-Id', 'ab'), 0,
    'header param minLength enforced');
is($api->_param_check('getPet', 'path', 'nope', '1'), -1,
    'unknown param name');
is($api->_param_check('nope', 'path', 'x', '1'), -1,
    'unknown operation');

# ---- compile/destroy cycles stay stable --------------------------------------
{
    my $ok = 1;
    for (1 .. 50) {
        my $a = Open::API->new(spec => "$FindBin::Bin/spec/petstore.json");
        $ok &&= $a->_body_check('createPet', 'application/json', { name => 'x' }) == 1;
    }
    ok($ok, '50 compile/validate/destroy cycles behave');
}

done_testing();
