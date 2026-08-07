#!perl
use 5.008003;
use strict;
use warnings;
use FindBin ();
use Test::More;
use Open::API;
use Open::API::Plack;
use File::Raw::JSON qw(file_json_decode);

# The Open::API::Plack object: configuration accumulates through new and the
# accessors (handlers/security merge across calls, setters chain), and
# to_app finalises it all into the PSGI app.

my $SPEC = "$FindBin::Bin/spec/petstore.json";

sub run_app {
    my ($app, %o) = @_;
    my $body = defined $o{body} ? $o{body} : '';
    open my $in, '<', \$body or die;
    return $app->({
        REQUEST_METHOD => $o{method} || 'GET',
        PATH_INFO      => $o{path}   || '/',
        QUERY_STRING   => $o{query}  || '',
        CONTENT_TYPE   => ($body ne '' ? 'application/json' : ''),
        CONTENT_LENGTH => length $body,
        'psgi.input'   => $in,
        %{ $o{env} || {} },
    });
}

# ---- new(spec) + incremental handlers (pairs, then a hashref) ---------------
{
    my $plack = Open::API::Plack->new(spec => $SPEC);
    isa_ok($plack, 'Open::API::Plack', 'new');
    isa_ok($plack->api, 'Open::API', 'spec compiled into ->api');

    $plack->handlers(listPets => sub { [ { id => 1, name => 'rex' } ] });
    $plack->handlers({ getPet => sub { { id => $_[0]{path}{petId} } } });

    my $app = $plack->to_app;
    my $r = run_app($app, path => '/pets');
    is($r->[0], 200, 'handler registered as a pair serves');
    $r = run_app($app, path => '/pets/7');
    is(file_json_decode($r->[2][0])->{id}, 7, 'handler merged as a hashref serves');
}

# ---- no handlers registered is legal: matched operations answer 501 ---------
{
    my $r = run_app(Open::API::Plack->new(spec => $SPEC)->to_app, path => '/pets');
    is($r->[0], 501, 'no handlers registered: matched op answers 501');
}

# ---- setters chain + hooks via accessors ------------------------------------
{
    my @order;
    my $api = Open::API->new(spec => $SPEC);
    my $plack = Open::API::Plack->new(api => $api);
    my $ret = $plack->before(sub { push @order, 'before'; return })
                    ->after(sub { push @order, 'after'; return });
    is(ref $ret, 'Open::API::Plack', 'setters return the object');
    $ret->handlers(listPets => sub { push @order, 'handler'; [] });
    my $r = run_app($plack->to_app, path => '/pets');
    is($r->[0], 200, 'chained configuration serves');
    is_deeply(\@order, [qw(before handler after)], 'hooks set via accessors fire');
}

# ---- getters round-trip; handlers getter is the live map --------------------
{
    my $plack = Open::API::Plack->new(spec => $SPEC,
        max_body_size => 42, error_format => 'problem');
    is($plack->max_body_size, 42, 'scalar getter round-trips new()');
    is($plack->error_format, 'problem', 'error_format getter');
    $plack->negotiate(1);
    ok($plack->negotiate, 'negotiate set then get');
    ok(!defined $plack->before, 'unset option getter is undef');

    $plack->handlers(listPets => sub { [] }, getPet => sub { {} });
    my $h = $plack->handlers;
    is(ref $h, 'HASH', 'handlers getter returns the map');
    is(scalar keys %$h, 2, 'both handlers registered in one call');
    delete $h->{getPet};
    is(scalar keys %{ $plack->handlers }, 1, 'getter exposes the live map');
}

# ---- security accessor + the startup coverage croak --------------------------
{
    my $spec = {
        openapi => '3.1.0', info => { title => 's', version => '1' },
        components => { securitySchemes => {
            ApiKey => { type => 'apiKey', in => 'header', name => 'X-API-Key' },
        } },
        paths => { '/k' => { get => {
            operationId => 'keyOp',
            security    => [ { ApiKey => [] } ],
            responses   => { 200 => { description => 'ok' } },
        } } },
    };
    my $plack = Open::API::Plack->new(spec => $spec,
        handlers => { keyOp => sub { [ 200, [], ['ok'] ] } });
    my $err = '';
    eval { $plack->to_app } or $err = $@;
    like($err, qr/requires securityScheme 'ApiKey' but no checker/,
        'to_app still croaks on an uncovered scheme');

    $plack->security(ApiKey => sub { $_[0] eq 'k' ? { u => 1 } : 0 });
    my $app = $plack->to_app;
    is(run_app($app, path => '/k', env => { HTTP_X_API_KEY => 'k' })->[0], 200,
        'checker added via accessor authorizes');
    is(run_app($app, path => '/k')->[0], 401, 'missing credential still 401');
}

# ---- api/spec set after new; to_app with neither croaks ---------------------
{
    my $plack = Open::API::Plack->new;
    my $err = '';
    eval { $plack->to_app } or $err = $@;
    like($err, qr/give 'api' or 'spec'/, 'no api or spec croaks at to_app');

    $plack->spec($SPEC);
    $plack->handlers(listPets => sub { [] });
    is(run_app($plack->to_app, path => '/pets')->[0], 200,
        'spec set via accessor after new');

    my $err2 = '';
    eval { Open::API::Plack->new(api => 'nope') } or $err2 = $@;
    like($err2, qr/'api' must be an Open::API/, 'api is type-checked at new');
}

# ---- one object, many apps: to_app leaves the configuration intact ----------
{
    my $plack = Open::API::Plack->new(spec => $SPEC,
        handlers => { listPets => sub { [ { id => 1 } ] } });
    my $app1 = $plack->to_app;
    $plack->handlers(listPets => sub { [ { id => 2 } ] });
    my $app2 = $plack->to_app;
    is(file_json_decode(run_app($app1, path => '/pets')->[2][0])->[0]{id}, 1,
        'first app keeps the handlers it was built with');
    is(file_json_decode(run_app($app2, path => '/pets')->[2][0])->[0]{id}, 2,
        'second app sees the updated handler');
}

done_testing();
