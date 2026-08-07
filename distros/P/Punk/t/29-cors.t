#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;

# Cross-origin handling (punk_cors.h), driven through to_app. Two things here
# are not incidental: the preflight is answered before routing, and the headers
# reach responses that never build a context. Both are asserted directly,
# because both are the reason this is in the dispatcher rather than a hook.

sub cors_headers {
    my ($res) = @_;
    my @h = @{ $res->[1] };
    my %out;
    while (my ($k, $v) = splice @h, 0, 2) {
        push @{ $out{$k} }, $v if $k =~ /\A(?:Access-Control-|Vary\z)/;
    }
    return \%out;
}

sub caller_for {
    my ($app) = @_;
    return sub {
        my (%a) = @_;
        open my $in, '<', \'';
        my $env = {
            REQUEST_METHOD => $a{method} // 'GET',
            PATH_INFO      => $a{path}   // '/books',
            QUERY_STRING   => '',
            SERVER_NAME    => 'localhost', SERVER_PORT => 80,
            HTTP_HOST      => 'localhost', 'psgi.url_scheme' => 'http',
            'psgi.input'   => $in,
        };
        $env->{HTTP_ORIGIN} = $a{origin} if $a{origin};
        $env->{HTTP_ACCESS_CONTROL_REQUEST_METHOD}  = $a{want}  if $a{want};
        $env->{HTTP_ACCESS_CONTROL_REQUEST_HEADERS} = $a{ask}   if $a{ask};
        $env->{'psgi.nonblocking'} = 1 if $a{nonblocking};
        my $res = $app->($env);
        return ($res, cors_headers($res));
    };
}

my $ORIGIN = 'https://app.example.com';

# ---- named origins with credentials -------------------------------------------

{
    package Named;
    use Punk;
    cors origins     => [ $ORIGIN, 'https://admin.example.com' ],
         credentials => 1,
         expose      => [ 'X-Request-Id' ];
    get  '/books'     => sub { $_[0]->json({ ok => 1 }) };
    post '/books'     => sub { $_[0]->json({ made => 1 }) };
    get  '/books/:id' => sub { $_[0]->json({ id => $_[0]->param('id') }) };
}
my $named = caller_for(Named->to_app);

{
    my ($res, $h) = $named->(origin => $ORIGIN);
    is($res->[0], 200, 'a simple cross-origin GET is served');
    is($h->{'Access-Control-Allow-Origin'}[0], $ORIGIN,
        'the origin is echoed, not starred');
    is($h->{'Access-Control-Allow-Credentials'}[0], 'true',
        'credentials are allowed');
    is($h->{'Access-Control-Expose-Headers'}[0], 'X-Request-Id',
        'exposed headers are listed');
    ok((grep { $_ eq 'Origin' } @{ $h->{Vary} || [] }),
        'Vary: Origin, without which a shared cache crosses origins');
}

{
    my ($res, $h) = $named->(origin => 'https://admin.example.com');
    is($h->{'Access-Control-Allow-Origin'}[0], 'https://admin.example.com',
        'a second listed origin is allowed');
}

{
    my ($res, $h) = $named->(origin => 'https://evil.example');
    is($res->[0], 200, 'an unlisted origin still gets the response');
    is(scalar keys %$h, 0,
        '...but no CORS headers, so the browser will not hand it over');
}

{
    my ($res, $h) = $named->();
    is($res->[0], 200, 'a same-origin request is untouched');
    is(scalar keys %$h, 0, 'and carries no CORS headers at all');
}

# ---- preflight ----------------------------------------------------------------

{
    my ($res, $h) = $named->(method => 'OPTIONS', path => '/books',
                             origin => $ORIGIN, want => 'POST',
                             ask => 'content-type, x-csrf-token');
    is($res->[0], 204, 'a preflight is answered 204');
    is($h->{'Access-Control-Allow-Origin'}[0], $ORIGIN, 'with the origin');

    # The point of answering here: the method list is the router's, so it can
    # never promise something the application does not serve.
    is($h->{'Access-Control-Allow-Methods'}[0], 'GET, POST',
        'Allow-Methods is what the router says that path answers');
    is($h->{'Access-Control-Allow-Headers'}[0], 'content-type, x-csrf-token',
        'the requested headers are echoed when none are configured');
    is($h->{'Access-Control-Max-Age'}[0], 600, 'with a default max-age');
    ok((grep { /Access-Control-Request-Method/ } @{ $h->{Vary} || [] }),
        'and Vary names what the reply depends on');
    is($res->[2][0], '', 'the body is empty');
}

{   # answered before routing: /books has no OPTIONS route, so without this it
    # would be the router's 405
    my ($res) = $named->(method => 'OPTIONS', path => '/books',
                         origin => $ORIGIN, want => 'GET');
    is($res->[0], 204, 'a preflight needs no OPTIONS route');
}

{
    my ($res, $h) = $named->(method => 'OPTIONS', path => '/books',
                             origin => $ORIGIN, want => 'DELETE');
    is($res->[0], 403,
        'a preflight for a method the path does not answer is refused');
    is(scalar keys %$h, 0, 'with no headers to mislead the browser');
}

{
    my ($res) = $named->(method => 'OPTIONS', path => '/books',
                         origin => 'https://evil.example', want => 'GET');
    is($res->[0], 403, 'a preflight from an unlisted origin is refused');
}

{   # a dynamic path resolves through the router the same way
    my ($res, $h) = $named->(method => 'OPTIONS', path => '/books/7',
                             origin => $ORIGIN, want => 'GET');
    is($res->[0], 204, 'a preflight on a dynamic path is answered');
    is($h->{'Access-Control-Allow-Methods'}[0], 'GET',
        '...with that path\'s own methods');
}

{   # a plain OPTIONS with no Access-Control-Request-Method is not a preflight
    my ($res) = $named->(method => 'OPTIONS', path => '/books',
                         origin => $ORIGIN);
    isnt($res->[0], 204, 'a bare OPTIONS is left to the router');
}

# ---- responses that never build a context -------------------------------------
# The reason this is not an after-dispatch hook.

{
    my ($res, $h) = $named->(path => '/no-such-path', origin => $ORIGIN);
    is($res->[0], 404, 'an unknown path is still 404');
    is($h->{'Access-Control-Allow-Origin'}[0], $ORIGIN,
        '...and carries CORS headers, so script can read the status');
}

{
    my ($res, $h) = $named->(method => 'DELETE', path => '/books',
                             origin => $ORIGIN);
    is($res->[0], 405, 'a wrong method is still 405');
    is($h->{'Access-Control-Allow-Origin'}[0], $ORIGIN,
        '...and carries them too');
}

# ---- api mounts -----------------------------------------------------------
# The router only knows web routes. For an api-first application - the shape
# `punk new --api` produces - every method lives in the mount instead, and a
# preflight that consulted only the router would refuse all of them.

SKIP: {
    my $spec = "$FindBin::Bin/test/MyApp/openapi.json";
    skip 'the fixture spec is missing', 5 unless -f $spec;

    {
        package Mounted;
        use Punk;
        cors origins => [ $ORIGIN ];
        get '/health' => sub { $_[0]->text('ok') };
        under('/api')->api($spec, { stub => 1 });
    }
    my $m = caller_for(Mounted->to_app);

    my ($res, $h) = $m->(method => 'OPTIONS', path => '/api/books',
                         origin => $ORIGIN, want => 'GET');
    is($res->[0], 204, 'a preflight on a spec operation is allowed');
    like($h->{'Access-Control-Allow-Methods'}[0], qr/\bGET\b/,
        'the method set comes from the specification');
    like($h->{'Access-Control-Allow-Methods'}[0], qr/\bPOST\b/,
        '...including the other methods that path declares');

    my ($bad) = $m->(method => 'OPTIONS', path => '/api/books',
                     origin => $ORIGIN, want => 'PATCH');
    is($bad->[0], 403, 'a method the specification does not declare is refused');

    my (undef, $simple) = $m->(path => '/api/books', origin => $ORIGIN);
    is($simple->{'Access-Control-Allow-Origin'}[0], $ORIGIN,
        'and an api response is decorated like any other');
}

# ---- the bare form ------------------------------------------------------------

{
    package Bare;
    use Punk;
    cors;
    get '/books' => sub { $_[0]->json({ ok => 1 }) };
}
{
    my $bare = caller_for(Bare->to_app);
    my ($res, $h) = $bare->(origin => 'https://anywhere.example');
    is($h->{'Access-Control-Allow-Origin'}[0], '*',
        'a bare cors allows any origin');
    ok(!$h->{'Access-Control-Allow-Credentials'},
        '...and never credentials, which is what makes * safe');
    ok(!(grep { $_ eq 'Origin' } @{ $h->{Vary} || [] }),
        'a flat * does not depend on the origin, so no Vary');
}

# ---- credentials cannot be combined with * ------------------------------------

{
    for my $case ([ 'no origins at all' => sub {
                        package CredA; use Punk; cors credentials => 1;
                        get '/' => sub { 1 }; CredA->to_app } ],
                  [ 'origins => "*"'    => sub {
                        package CredB; use Punk;
                        cors credentials => 1, origins => '*';
                        get '/' => sub { 1 }; CredB->to_app } ]) {
        my ($what, $build) = @$case;
        my $err = '';
        eval { $build->() } or $err = $@;
        like($err, qr/needs explicit origins/,
            "credentials with $what is refused at boot");
    }
}

# ---- paths --------------------------------------------------------------------

{
    package Scoped;
    use Punk;
    cors paths => [ '/api' ];
    get '/'         => sub { $_[0]->text('html') };
    get '/api/list' => sub { $_[0]->json({ ok => 1 }) };
}
{
    my $s = caller_for(Scoped->to_app);
    my (undef, $api)  = $s->(path => '/api/list', origin => 'https://x.example');
    my (undef, $html) = $s->(path => '/',         origin => 'https://x.example');
    is($api->{'Access-Control-Allow-Origin'}[0], '*',
        'a path under the prefix is decorated');
    is(scalar keys %$html, 0, 'one outside it is left alone');
}

# ---- a coderef origin check ---------------------------------------------------

{
    package Dynamic;
    use Punk;
    cors origins => sub { $_[0] =~ m{\Ahttps://[a-z]+\.example\.com\z} };
    get '/books' => sub { $_[0]->json({ ok => 1 }) };
}
{
    my $d = caller_for(Dynamic->to_app);
    my (undef, $yes) = $d->(origin => 'https://shop.example.com');
    my (undef, $no)  = $d->(origin => 'https://shop.evil.com');
    is($yes->{'Access-Control-Allow-Origin'}[0], 'https://shop.example.com',
        'a coderef may allow an origin, and it is echoed');
    is(scalar keys %$no, 0, '...and refuse another');
}

# ---- the other two response shapes --------------------------------------------

{
    package Shapes;
    use Punk;
    cors origins => [ $ORIGIN ];
    # a streaming response: the server hands the app a responder
    get '/stream' => sub {
        return sub {
            my ($responder) = @_;
            $responder->([ 200, [ 'Content-Type', 'text/plain' ], [ 'hi' ] ]);
        };
    };
    get '/future' => sub {
        my ($c) = @_;
        my $f = Punk::Future->new;
        $f->done($c->json({ later => 1 }));
        return $f;
    };
}
{
    my $sh = Shapes->to_app;
    open my $in, '<', \'';
    my %base = (REQUEST_METHOD => 'GET', QUERY_STRING => '',
                SERVER_NAME => 'l', SERVER_PORT => 80, HTTP_HOST => 'l',
                'psgi.url_scheme' => 'http', 'psgi.input' => $in,
                HTTP_ORIGIN => $ORIGIN);

    my $streamed;
    my $out = $sh->({ %base, PATH_INFO => '/stream' });
    is(ref $out, 'CODE', 'a streaming handler still returns a coderef');
    $out->(sub { $streamed = shift; return });
    ok($streamed, 'the responder was called');
    my %h = @{ $streamed->[1] };
    is($h{'Access-Control-Allow-Origin'}, $ORIGIN,
        'a streaming response is decorated on its way past');

    my $f = $sh->({ %base, PATH_INFO => '/future', 'psgi.nonblocking' => 1 });
    if (ref $f && eval { $f->can('then') }) {
        my $got;
        $f->on_done(sub { $got = $_[0] });
        ok($got, 'the future settled');
        if ($got) {
            my %fh = @{ $got->[1] };
            is($fh{'Access-Control-Allow-Origin'}, $ORIGIN,
                'a Future response is decorated when it resolves');
        }
        else { fail('a Future response is decorated when it resolves') }
    }
    else {
        my %fh = @{ $f->[1] };
        is($fh{'Access-Control-Allow-Origin'}, $ORIGIN,
            'a resolved future came back as a triplet, decorated');
        pass('(no pending future on this path)');
    }
}

# ---- CORS does not open the CSRF door -----------------------------------------

{
    package Both;
    use Punk;
    session secret => 'k';
    csrf;
    cors origins => [ $ORIGIN ], credentials => 1;
    post '/write' => sub { $_[0]->text('written') };
}
{
    my $b = caller_for(Both->to_app);
    my ($res, $h) = $b->(method => 'POST', path => '/write', origin => $ORIGIN);
    is($res->[0], 403,
        'a permitted cross-origin write with no token is still refused');
    like($res->[2][0], qr/invalid csrf token/, 'by the csrf check');
    is($h->{'Access-Control-Allow-Origin'}[0], $ORIGIN,
        '...and even that refusal is readable cross-origin');
}

done_testing();
