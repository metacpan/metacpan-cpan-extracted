#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use Punk::Test;

# Security headers (punk_headers.h), driven through to_app. Two behaviours
# here are the reason the code lives in the dispatcher and not a hook, and
# both are asserted directly: the policy reaches the 404s and 405s that never
# build a context, and it reaches the CORS preflight reply. The third pillar
# is set-if-absent - a header the response already carries is never repeated
# or overridden.

sub all_headers {
    my ($res) = @_;
    my @h = @{ $res->[1] };
    my %out;
    while (my ($k, $v) = splice @h, 0, 2) {
        push @{ $out{lc $k} }, $v;
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
            PATH_INFO      => $a{path}   // '/ok',
            QUERY_STRING   => '',
            SERVER_NAME    => 'localhost', SERVER_PORT => 80,
            HTTP_HOST      => 'localhost', 'psgi.url_scheme' => 'http',
            'psgi.input'   => $in,
        };
        $env->{HTTP_ORIGIN} = $a{origin} if $a{origin};
        $env->{HTTP_ACCESS_CONTROL_REQUEST_METHOD} = $a{want} if $a{want};
        $env->{'psgi.nonblocking'} = 1 if $a{nonblocking};
        my $res = $app->($env);
        return ($res, ref $res eq 'ARRAY' ? all_headers($res) : undef);
    };
}

my @DEFAULTS = (
    [ 'x-content-type-options', 'nosniff' ],
    [ 'x-frame-options',        'SAMEORIGIN' ],
    [ 'referrer-policy',        'strict-origin-when-cross-origin' ],
);

sub has_defaults {
    my ($h, $what) = @_;
    for my $d (@DEFAULTS) {
        my ($k, $v) = @$d;
        is_deeply($h->{$k}, [ $v ], "$what carries $k");
    }
}

my $ORIGIN = 'https://app.example.com';

# ---- the bare keyword, on every response shape --------------------------------

{
    package Bare;
    use Punk;
    headers;
    cors origins => [ $ORIGIN ];
    get  '/ok'   => sub { $_[0]->text('fine') };
    post '/only' => sub { $_[0]->text('made') };
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
my $bare = caller_for(Bare->to_app);

{
    my ($res, $h) = $bare->(path => '/ok');
    is($res->[0], 200, 'an ordinary response');
    has_defaults($h, 'a 200');
}
{
    my ($res, $h) = $bare->(path => '/missing');
    is($res->[0], 404, 'a path no route serves');
    has_defaults($h, 'the 404 that never builds a context');
}
{
    my ($res, $h) = $bare->(path => '/only', method => 'GET');
    is($res->[0], 405, 'a method the path does not answer');
    has_defaults($h, 'the 405');
}
{
    my ($res, $h) = $bare->(path => '/ok', method => 'OPTIONS',
                            origin => $ORIGIN, want => 'GET');
    is($res->[0], 204, 'a CORS preflight');
    has_defaults($h, 'the preflight reply');
    is_deeply($h->{'access-control-allow-origin'}, [ $ORIGIN ],
        'and CORS still speaks on it');
}
{
    my ($res) = $bare->(path => '/stream');
    is(ref $res, 'CODE', 'a streaming handler still returns a coderef');
    my $streamed;
    $res->(sub { $streamed = shift; return });
    ok($streamed, 'the responder was called');
    has_defaults(all_headers($streamed),
        'a streaming response, decorated on its way past');
}
{
    my ($res) = $bare->(path => '/future', nonblocking => 1);
    if (ref $res && eval { $res->can('then') }) {
        my $got;
        $res->on_done(sub { $got = $_[0] });
        ok($got, 'the future settled');
        has_defaults(all_headers($got),
            'a Future response, decorated when it resolves');
    }
    else {
        has_defaults(all_headers($res),
            'a resolved future came back as a triplet, decorated');
    }
}

# ---- set-if-absent ------------------------------------------------------------

{
    package Own;
    use Punk;
    headers;
    get '/own' => sub {
        my ($c) = @_;
        $c->header('X-Frame-Options' => 'DENY');
        $c->text('mine');
    };
}
{
    my ($res, $h) = caller_for(Own->to_app)->(path => '/own');
    is_deeply($h->{'x-frame-options'}, [ 'DENY' ],
        'a handler-set header wins, once - the policy neither repeats '
        . 'nor overrides it');
    is_deeply($h->{'x-content-type-options'}, [ 'nosniff' ],
        'while the rest of the policy still applies');
}

# ---- overrides, extras, undef removes, off ------------------------------------

{
    package Tuned;
    use Punk;
    headers 'Content-Security-Policy' => "default-src 'self'",
            'X-Frame-Options'         => 'DENY',
            'Referrer-Policy'         => undef;
    get '/ok' => sub { $_[0]->text('fine') };
    package main;
    my $t = Punk::Test->new('Tuned');
    $t->get_ok('/ok')
      ->header_is('Content-Security-Policy' => "default-src 'self'")
      ->header_is('X-Frame-Options' => 'DENY')
      ->header_is('X-Content-Type-Options' => 'nosniff');
    ok(!defined $t->header('Referrer-Policy'),
        'an undef value removes that default');
}
{
    package Off;
    use Punk;
    headers;
    headers 0;
    get '/ok' => sub { $_[0]->text('fine') };
    package main;
    my $t = Punk::Test->new('Off');
    $t->get_ok('/ok');
    ok(!defined $t->header('X-Content-Type-Options'),
        'headers 0 turns the policy off');
}
{
    my $err = '';
    eval q{ package BadVal; use Punk; headers 'X-Thing' => []; 1 } or $err = $@;
    like($err, qr/must be a string/,
        'a reference value croaks at keyword time, naming the header');
}

# ---- scoped policies ($scope->headers) ----------------------------------------

{
    package Scoped;
    use Punk;
    headers;
    my $admin = under '/admin' => sub { return };
    $admin->headers('X-Frame-Options' => 'DENY',
                    'X-Robots-Tag'    => 'noindex',
                    'Referrer-Policy' => undef);
    my $embed = $admin->under('/embed');
    $embed->headers('X-Frame-Options' => 'ALLOWALL');
    get '/'  => sub { $_[0]->text('root') };
    $admin->get('/panel' => sub { $_[0]->text('panel') });
    $embed->get('/frame' => sub { $_[0]->text('frame') });
}
{
    my $s = caller_for(Scoped->to_app);
    my (undef, $h) = $s->(path => '/');
    is_deeply($h->{'x-frame-options'}, [ 'SAMEORIGIN' ],
        'outside the scope, the app-wide policy holds');
    ok(!$h->{'x-robots-tag'}, 'and the scope adds nothing there');

    (undef, $h) = $s->(path => '/admin/panel');
    is_deeply($h->{'x-frame-options'}, [ 'DENY' ],
        'under the scope, its mention of a name wins');
    is_deeply($h->{'x-robots-tag'}, [ 'noindex' ],
        'a header the scope adds');
    ok(!$h->{'referrer-policy'},
        'an undef value drops an app-wide header for the subtree');
    is_deeply($h->{'x-content-type-options'}, [ 'nosniff' ],
        'while the untouched policy still applies');

    (undef, $h) = $s->(path => '/admin/embed/frame');
    is_deeply($h->{'x-frame-options'}, [ 'ALLOWALL' ],
        'a nested scope is more specific: the longest prefix wins');
    is_deeply($h->{'x-robots-tag'}, [ 'noindex' ],
        'and the outer scope still speaks where the inner is silent');

    my ($res, $h404) = $s->(path => '/admin/missing');
    is($res->[0], 404, 'a 404 under the prefix');
    is_deeply($h404->{'x-frame-options'}, [ 'DENY' ],
        'carries the scoped policy - it rides the response path, '
        . 'not the route');
}
{
    package ScopeOnly;
    use Punk;
    my $api = under '/api' => sub { return };
    $api->headers('Cache-Control' => 'no-store');
    get '/' => sub { $_[0]->text('r') };
    $api->get('/v' => sub { $_[0]->text('v') });
}
{
    my $s = caller_for(ScopeOnly->to_app);
    my (undef, $h) = $s->(path => '/api/v');
    is_deeply($h->{'cache-control'}, [ 'no-store' ],
        'a scope policy works without the app-wide keyword');
    (undef, $h) = $s->(path => '/');
    ok(!$h->{'cache-control'}, 'and stays inside its prefix');
}

# ---- the config block ----------------------------------------------------------

SKIP: {
    skip 'YAML::XS required for the config round-trip', 4
        unless eval { require YAML::XS; 1 };
    require File::Temp;
    my $dir = File::Temp->newdir;
    open my $fh, '>', "$dir/punk.yml" or die $!;
    print $fh <<'YAML';
headers:
  Content-Security-Policy: "default-src 'self'"
  X-Frame-Options: ~
YAML
    close $fh;
    {
        package FromConfig;
        use Punk;
        config "$dir/punk.yml";
        get '/ok' => sub { $_[0]->text('fine') };
    }
    my $t = Punk::Test->new('FromConfig');
    $t->get_ok('/ok')
      ->header_is('Content-Security-Policy' => "default-src 'self'")
      ->header_is('X-Content-Type-Options' => 'nosniff');
    ok(!defined $t->header('X-Frame-Options'),
        'the config block can drop a default too');
}

done_testing;
