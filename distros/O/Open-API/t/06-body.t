#!perl
use 5.008003;
use strict;
use warnings;
use FindBin ();
use Test::More;
use Open::API;

# Request bodies: JSON decode + validate, required enforcement, undeclared
# and pass-through content types, pre-decoded refs.

my $api = Open::API->new(spec => "$FindBin::Bin/spec/petstore.json");

sub V { $api->validate_request('createPet', { header => $_[1] || { 'content-type' => 'application/json' }, body => $_[0] }) }

# ---- valid body ----------------------------------------------------------------
{
    my ($ok, $params) = V('{"name":"rex","tag":"dog"}');
    is($ok, 1, 'valid JSON body');
    is($params->{body}{name}, 'rex', 'decoded body in params');
}

# ---- schema failure --------------------------------------------------------------
{
    my ($ok, $errs) = V('{"tag":"dog"}');
    is($ok, 0, 'missing required property fails');
    is($errs->[0]{in}, 'body', 'in=body');
    ok($errs->[0]{instanceLocation} || $errs->[0]{keyword},
        'JSF error fields present');
}

# ---- broken JSON -------------------------------------------------------------------
{
    my ($ok, $errs) = V('{"name":');
    is($ok, 0, 'broken JSON fails');
    is($errs->[0]{keyword}, 'json', 'json parse error keyword');
}

# ---- required body missing ----------------------------------------------------------
{
    my ($ok, $errs) = $api->validate_request('createPet', {});
    is($ok, 0, 'missing required body fails');
    is($errs->[0]{keyword}, 'required', 'required body error');
}

# ---- undeclared content type ----------------------------------------------------------
{
    my ($ok, $errs) = V('<xml/>', { 'content-type' => 'application/xml' });
    is($ok, 0, 'undeclared content type fails');
    is($errs->[0]{keyword}, 'content-type', 'content-type error keyword');
}

# ---- declared pass-through type ---------------------------------------------------------
{
    my ($ok, $params) = V('anything at all', { 'content-type' => 'text/plain' });
    is($ok, 1, 'declared non-json type passes through');
    is($params->{body}, 'anything at all', 'raw body preserved');
}

# ---- content-type with parameters ----------------------------------------------------------
{
    my ($ok) = V('{"name":"x"}', { 'content-type' => 'application/json; charset=utf-8' });
    is($ok, 1, 'content-type parameters ignored for matching');
}

# ---- pre-decoded body ref ---------------------------------------------------------------------
{
    my ($ok, $params) = $api->validate_request('createPet', {
        header => { 'content-type' => 'application/json' },
        body   => { name => 'ref' },
    });
    is($ok, 1, 'pre-decoded hashref body validates without decode');
    is($params->{body}{name}, 'ref', 'ref body stored');
}

# ---- ops without a declared body ignore any body ------------------------------------------------
{
    my ($ok) = $api->validate_request('listPets', { body => 'ignored' });
    is($ok, 1, 'body ignored on an op without requestBody');
}

done_testing();
