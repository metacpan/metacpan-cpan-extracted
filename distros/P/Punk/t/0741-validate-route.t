#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use Punk::Test;

# The route-level validate option: the schema compiles once at to_app, the
# generated guard runs after any scope guards (a 401 costs no body parse),
# the 400 carries the OpenAPI-mount error shape, on_invalid takes over the
# failure response (the flash + redirect form round-trip), and every wrong
# declaration croaks at boot naming the route.

my %BOOK = (
    type       => 'object',
    required   => ['title'],
    properties => {
        title => { type => 'string',  minLength => 1 },
        year  => { type => 'integer', minimum   => 1900 },
    },
);

my @GUARD_LOG;

{
    package RApp;
    use Punk;
    session secret => 'test-key';

    get '/books' => sub {
        my ($c) = @_;
        $c->json({ page => $c->validate->valid('page') // 1 });
    }, {
        validate => {
            type       => 'object',
            properties => { page => { type => 'integer', minimum => 1 } },
        },
    };

    post '/books' => sub { $_[0]->json({ ok => 1 }) },
        { validate => \%BOOK };

    # on_invalid: the classic form round-trip - flash the errors, redirect
    post '/form' => sub { $_[0]->json({ saved => 1 }) }, {
        validate => {
            schema     => \%BOOK,
            source     => 'params',
            on_invalid => sub {
                my ($c) = @_;
                my $v = $c->validate;
                $c->flash(errors => { map { $_->{name} => $_->{message} }
                                      @{ $v->errors } });
                return $c->redirect('/form');
            },
        },
    };
    get '/form' => sub {
        my ($c) = @_;
        $c->json({ errors => $c->flash('errors') // {} });
    };

    # a scoped auth guard must run before the validation guard
    my $auth = under '/private' => sub {
        my ($c) = @_;
        push @GUARD_LOG, 'auth';
        return $c->text('nope', 401)
            unless ($c->req->header('x-token') // '') eq 'ok';
        return;
    };
    $auth->post('/save' => sub {
        push @GUARD_LOG, 'handler';
        $_[0]->json({ ok => 1 });
    }, { validate => \%BOOK });
}

my $t = Punk::Test->new('RApp');

# ---- the guard validates before the handler -----------------------------------

$t->get_ok('/books?page=2')->status_is(200)
  ->json_is('/page' => 2, 'the handler reads the typed value via validation');

$t->get_ok('/books?page=0')
  ->status_is(400, 'an invalid query never reaches the handler');
{
    my $e = $t->json->{errors};
    is(ref $e, 'ARRAY', 'the 400 body is { errors => [...] }');
    is($e->[0]{name}, 'page', 'named for the field');
    ok(exists $e->[0]{instanceLocation} && exists $e->[0]{keyword}
        && exists $e->[0]{schemaLocation} && exists $e->[0]{message},
        'in the OpenAPI-mount error shape');
}

$t->post_ok('/books', json => { title => 'ok', year => 1999 })
  ->status_is(200)->json_is('/ok' => 1);
$t->post_ok('/books', json => { year => 1850 })
  ->status_is(400)
  ->json_like('/errors/0/message' => qr/./, 'a JSON body validates too');

# ---- on_invalid: flash + redirect round-trip ----------------------------------

$t->post_ok('/form', form => { year => 1850 })
  ->status_is(302, 'on_invalid took over the failure response')
  ->header_like(Location => qr{/form$});
$t->get_ok('/form')
  ->json_like('/errors/title' => qr/required|missing/,
      'the flashed field errors survived the redirect')
  ->json_like('/errors/year' => qr/minimum/);
$t->post_ok('/form', form => { title => 'x', year => 1999 })
  ->status_is(200)->json_is('/saved' => 1, 'valid input reaches the handler');

# ---- auth guards stay first ---------------------------------------------------

@GUARD_LOG = ();
$t->post_ok('/private/save', json => { year => 1850 })
  ->status_is(401, 'the auth guard answers first');
is_deeply(\@GUARD_LOG, ['auth'],
    'validation never ran for the unauthorised request');

@GUARD_LOG = ();
$t->post_ok('/private/save', json => { year => 1850 },
            headers => { 'X-Token' => 'ok' })
  ->status_is(400, 'authorised but invalid is the validation 400');
is_deeply(\@GUARD_LOG, ['auth'], 'and the handler never ran');

@GUARD_LOG = ();
$t->post_ok('/private/save', json => { title => 'ok' },
            headers => { 'X-Token' => 'ok' })
  ->status_is(200);
is_deeply(\@GUARD_LOG, [qw(auth handler)], 'the full chain in order');

# ---- boot croaks name the route -----------------------------------------------

{
    my $err = '';
    eval {
        package BadOptApp;
        use Punk;
        get '/x' => sub { }, { validate => \%BOOK, typo => 1 };
        package main;
        1;
    } or $err = $@;
    like($err, qr/unknown route option 'typo'/,
        'an unknown route option croaks at declaration');
}

{
    my $err = '';
    eval {
        package BadSchemaRouteApp;
        use Punk;
        get '/x' => sub { }, { validate => { schema => 'nope' } };
        package main;
        BadSchemaRouteApp->to_app;
    } or $err = $@;
    like($err, qr/invalid validate schema on GET \/x/,
        'a malformed schema croaks at boot naming the route');
}

{
    my $err = '';
    eval {
        package BadSourceApp;
        use Punk;
        get '/x' => sub { }, { validate => { schema => \%BOOK,
                                             source => 'body' } };
        package main;
        BadSourceApp->to_app;
    } or $err = $@;
    like($err, qr/source on GET \/x must be/,
        'a wrong source croaks at boot naming the route');
}

# a second to_app is deliberately once-per-class: the croak stays informative
{
    my $err = '';
    eval { RApp->to_app } or $err = $@;
    like($err, qr/already compiled/, 'to_app stays once-per-class');
}

# ---- too many bare route args still croak -------------------------------------

{
    my $err = '';
    eval {
        package TooManyApp;
        use Punk;
        get '/x' => sub { }, { validate => \%BOOK }, 'extra';
        package main;
    } or $err = $@;
    like($err, qr/at most one options hashref/,
        'extra route arguments croak instead of vanishing');
}

done_testing();
