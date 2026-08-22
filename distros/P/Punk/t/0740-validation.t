#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use Punk::Test;
use JSON::Schema::Fast ();

# The imperative validation surface: $c->validate collects instead of
# croaking, the errors carry the Open::API shape plus name, valid() hands
# back typed filtered params, schemas compile once per canonical shape, and
# the data source follows the request's content type.

my %SCHEMA = (
    type       => 'object',
    required   => ['title'],
    properties => {
        title => { type => 'string',  minLength => 1 },
        year  => { type => 'integer', minimum   => 1900 },
        fresh => { type => 'boolean' },
    },
);

{
    package VApp;
    use Punk;

    post '/books' => sub {
        my ($c) = @_;
        my $v = $c->validate(\%SCHEMA);
        return $c->json({ errors => $v->errors }, 400) if $v->has_errors;
        return $c->json({ ok => 1, got => $v->valid });
    };
    post '/first-error' => sub {
        my ($c) = @_;
        my $v = $c->validate(\%SCHEMA);
        $c->json({ title => $v->error('title'), year => $v->error('year') });
    };
    post '/precompiled' => sub {
        my ($c) = @_;
        state $s = JSON::Schema::Fast->compile(\%SCHEMA, coerce => 1);
        my $v = $c->validate($s);
        $c->json({ errors => scalar @{ $v->errors },
                   valid  => $v->valid });
    };
    post '/explicit' => sub {
        my ($c) = @_;
        my $v = $c->validate(\%SCHEMA, { title => 'x', year => 2001 });
        $c->json({ has => $v->has_errors ? 1 : 0 });
    };
    get '/q' => sub {
        my ($c) = @_;
        my $v = $c->validate({
            type       => 'object',
            properties => { page => { type => 'integer', minimum => 1 } },
        });
        return $c->json({ errors => $v->errors }, 400) if $v->has_errors;
        $c->json({ page => $v->valid('page') });
    };
    post '/stashed' => sub {
        my ($c) = @_;
        $c->validate(\%SCHEMA);
        my $read = $c->validate;               # zero args: the reader
        $c->json({ same => ($read && $read->has_errors) ? 1 : 0 });
    };
    get '/nothing' => sub {
        my ($c) = @_;
        $c->json({ empty => defined $c->validate ? 0 : 1 });
    };
}

my $t = Punk::Test->new('VApp');

# ---- collect, not croak; the error shape --------------------------------------

$t->post_ok('/books', json => { year => 1850 })
  ->status_is(400, 'invalid data is a 400, not a die');
{
    my $errors = $t->json->{errors};
    is(ref $errors, 'ARRAY', 'errors is an arrayref');
    my ($req) = grep { $_->{keyword} eq 'required' } @$errors;
    my ($min) = grep { $_->{keyword} eq 'minimum'  } @$errors;
    ok($req, 'a required failure is reported');
    is($req->{name}, 'title', 'expanded to the missing property by name');
    like($req->{message}, qr/title/, 'and the message names the field');
    ok($min, 'the minimum failure is reported too');
    is($min->{name}, 'year', 'named after its field');
    is($min->{instanceLocation}, '/year', 'with the JSON::Schema::Fast field');
    ok(exists $min->{schemaLocation} && exists $min->{message},
        'and the rest of the Open::API shape');
}

# ---- valid(): typed and filtered ----------------------------------------------

$t->post_ok('/books', type => 'application/json',
    body => '{"title":"Neuromancer","year":1984,"fresh":true,"extra":"dropped"}')
  ->status_is(200)
  ->json_is('/ok' => 1)
  ->json_is('/got/title' => 'Neuromancer')
  ->json_is('/got/year'  => 1984)
  ->json_has('/got/fresh');
ok(!exists $t->json->{got}{extra}, 'undeclared keys are filtered out');

# form params arrive as strings; coercion accepts and valid() types them
$t->post_ok('/books', form => { title => 'Idoru', year => '1996',
                                fresh => 'false' })
  ->status_is(200, 'a numeric string satisfies integer under coercion');
{
    my $got = $t->json->{got};
    cmp_ok($got->{year}, '==', 1996, 'valid() numified the year');
    is($t->body =~ /"year":1996/ ? 1 : 0, 1,
        '...as a real JSON number, not a string');
    is($got->{fresh}, 0, "boolean 'false' canonicalized to 0");
}

# ---- error($name) -------------------------------------------------------------

$t->post_ok('/first-error', json => { year => 1850 })
  ->json_like('/year' => qr/minimum/)
  ->json_like('/title' => qr/required|missing/);

# ---- the precompiled fast path ------------------------------------------------

$t->post_ok('/precompiled', json => { title => 'ok', year => 2000 })
  ->json_is('/errors' => 0)
  ->json_is('/valid/title' => 'ok',
      'a JSON::Schema::Fast::Compiled passes straight through');

# ---- explicit data + query source ---------------------------------------------

$t->post_ok('/explicit', json => { garbage => 1 })
  ->json_is('/has' => 0, 'an explicit data hashref overrides the body');

$t->get_ok('/q?page=3')->status_is(200)
  ->json_is('/page' => 3, 'query params are the source for a GET');
$t->get_ok('/q?page=0')->status_is(400, 'and are validated');

# ---- the result is stashed ----------------------------------------------------

$t->post_ok('/stashed', json => {})
  ->json_is('/same' => 1, 'a bare $c->validate reads the stashed result');
$t->get_ok('/nothing')
  ->json_is('/empty' => 1, 'and is undef when nothing has validated');

# ---- a malformed schema croaks (boot-shaped, even imperatively) ---------------

{
    package BadSchemaApp;
    use Punk;
    get '/' => sub { $_[0]->validate('not-a-schema'); $_[0]->text('x') };
}
{
    my $b = Punk::Test->new('BadSchemaApp');
    $b->get_ok('/')->status_is(500)
      ->json_like('/errors/0/message' => qr/hashref or a/);
}

# ---- the Result's own JSON shape --------------------------------------------
# TO_JSON is what makes a Result the 400 body. Every test above reads that body
# after the framework has encoded it, so what was never checked is that the
# Result encodes to that shape when anything ELSE encodes it - an application
# putting one in its own response, a log line, a nested field.
{
    package ResultApp;
    use Punk;
    post '/check' => sub {
        my ($c) = @_;
        my $r = $c->validate({ type => 'object',
                               required => ['name'],
                               properties => { name => { type => 'string' } } });
        # the Result inside a structure of the application's own making
        return $c->json({ wrapped => $r, ok => $r->has_errors ? 0 : 1 });
    };
    package main;

    my $t = Punk::Test->new('ResultApp');

    $t->post_ok('/check', json => {});
    $t->json_is('/ok' => 0, 'an invalid body has errors');
    $t->json_has('/wrapped/errors',
        'and the Result nested in the application\'s own JSON encodes as '
      . '{ errors => [...] } - which is the documented shape, and the reason '
      . 'a 400 body looks the way it does');
    $t->json_like('/wrapped/errors/0/name' => qr/name/,
        'carrying the field that failed');

    $t->post_ok('/check', json => { name => 'ok' });
    $t->json_is('/ok' => 1, 'a valid body has none');
    $t->json_is('/wrapped/errors' => [],
        'and encodes as an EMPTY errors list rather than as null or a bare '
      . 'object - a consumer can read it the same way either way');
}

done_testing();
