#!perl
use 5.008003;
use strict;
use warnings;
use FindBin ();
use Test::More;
use Open::API;
use Open::API::Plack;
use File::Raw::JSON qw(file_json_decode);

# Server options on to_app: secure response headers (defaults on, overridable
# and removable), max_body_size (413), CORS (preflight + actual request), and
# content negotiation (415 / 406) with the RFC 7807 problem+json error format.

my $api = Open::API->new(spec => "$FindBin::Bin/spec/petstore.json");

sub req {
    my ($app, %o) = @_;
    my $body = defined $o{body} ? $o{body} : '';
    open my $in, '<', \$body or die;
    return $app->({
        REQUEST_METHOD => $o{method} || 'GET',
        PATH_INFO      => $o{path}   || '/',
        QUERY_STRING   => $o{query}  || '',
        CONTENT_LENGTH => (exists $o{clen} ? $o{clen} : length $body),
        ($o{ctype} ? (CONTENT_TYPE => $o{ctype}) : ()),
        'psgi.input'   => $in,
        %{ $o{env} || {} },
    });
}
# case-insensitive header lookup over a PSGI triplet
sub hdr {
    my ($r, $name) = @_;
    my @h = @{ $r->[1] };
    for (my $i = 0; $i < @h; $i += 2) {
        return $h[$i + 1] if lc $h[$i] eq lc $name;
    }
    return undef;
}
sub body_json { file_json_decode($_[0][2][0]) }

my %H = (
    listPets  => sub { [ 200, ['Content-Type' => 'application/json'], ['[]'] ] },
    getPet    => sub { [ 200, ['Content-Type' => 'application/json'], ['{}'] ] },
    createPet => sub { [ 201, ['Content-Type' => 'application/json'], ['{}'] ] },
    deletePet => sub { [ 200, ['Content-Type' => 'application/json'], ['{}'] ] },
);
my $VALID = '{"id":1,"name":"rex"}';

# ---- security headers: secure defaults on ---------------------------------------
{
    my $app = Open::API::Plack->new(api => $api, handlers => \%H)->to_app;
    my $r = req($app, path => '/pets');
    is(hdr($r, 'X-Content-Type-Options'), 'nosniff', 'default nosniff');
    like(hdr($r, 'Content-Security-Policy'), qr/default-src 'none'/, 'default CSP');
    is(hdr($r, 'X-Frame-Options'), 'DENY', 'default X-Frame-Options');
    is(hdr($r, 'Referrer-Policy'), 'no-referrer', 'default Referrer-Policy');

    # present on error responses too
    is(hdr(req($app, path => '/nope'), 'X-Content-Type-Options'), 'nosniff',
       'headers on a 404');
    my $bad = req($app, method => 'POST', path => '/pets',
                  ctype => 'application/json', body => '{"id":"nope"}');
    is($bad->[0], 400, 'a validation 400 status');
    is(hdr($bad, 'X-Frame-Options'), 'DENY', 'headers on a 400');
}

# ---- security headers: override, remove, add, handler wins ----------------------
{
    my $app = Open::API::Plack->new(api => $api, handlers => {
        %H,
        listPets => sub {   # handler sets its own X-Frame-Options
            [ 200, ['Content-Type' => 'application/json',
                    'X-Frame-Options' => 'SAMEORIGIN'], ['[]'] ];
        },
    }, headers => {
        'Content-Security-Policy'   => "default-src 'self'",   # override
        'Referrer-Policy'           => undef,                  # remove
        'Strict-Transport-Security' => 'max-age=63072000',     # add (HSTS)
    })->to_app;
    my $r = req($app, path => '/pets/5');
    is(hdr($r, 'Content-Security-Policy'), "default-src 'self'", 'CSP overridden');
    is(hdr($r, 'Referrer-Policy'), undef, 'Referrer-Policy removed via undef');
    is(hdr($r, 'Strict-Transport-Security'), 'max-age=63072000', 'HSTS added');
    is(hdr($r, 'X-Content-Type-Options'), 'nosniff', 'other defaults still on');

    my $lp = req($app, path => '/pets');
    is(hdr($lp, 'X-Frame-Options'), 'SAMEORIGIN',
       'a header the handler set is not clobbered (set-if-absent)');
}

# ---- max_body_size -> 413 -------------------------------------------------------
{
    my $app = Open::API::Plack->new(api => $api, handlers => \%H, max_body_size => 100)->to_app;
    my $over = req($app, method => 'POST', path => '/pets',
                   ctype => 'application/json',
                   clen => 5000, body => $VALID);
    is($over->[0], 413, 'oversize Content-Length is rejected with 413');
    my $ok = req($app, method => 'POST', path => '/pets',
                 ctype => 'application/json', body => $VALID);
    is($ok->[0], 201, 'a body under the limit passes');
}

# ---- CORS: actual request + preflight -------------------------------------------
{
    my $app = Open::API::Plack->new(api => $api, handlers => \%H,
        cors => { origins => [ 'https://app.example.com' ], max_age => 600 })->to_app;

    my $ok = req($app, path => '/pets',
                 env => { HTTP_ORIGIN => 'https://app.example.com' });
    is(hdr($ok, 'Access-Control-Allow-Origin'), 'https://app.example.com',
       'CORS: allowed origin echoed on the actual response');
    is(hdr($ok, 'Vary'), 'Origin', 'CORS: Vary: Origin set');

    my $no = req($app, path => '/pets',
                 env => { HTTP_ORIGIN => 'https://evil.example.net' });
    is(hdr($no, 'Access-Control-Allow-Origin'), undef,
       'CORS: disallowed origin gets no ACAO');

    my $pre = req($app, method => 'OPTIONS', path => '/pets',
                  env => { HTTP_ORIGIN => 'https://app.example.com',
                           HTTP_ACCESS_CONTROL_REQUEST_METHOD => 'POST' });
    is($pre->[0], 204, 'preflight is a 204');
    like(hdr($pre, 'Access-Control-Allow-Methods'), qr/\bPOST\b/,
         'preflight Allow-Methods carries the declared methods');
    is(hdr($pre, 'Access-Control-Allow-Origin'), 'https://app.example.com',
       'preflight echoes the origin');
    is(hdr($pre, 'Access-Control-Max-Age'), 600, 'preflight Max-Age set');
}

# ---- CORS: wildcard default + credentials footgun -------------------------------
{
    my $app = Open::API::Plack->new(api => $api, handlers => \%H, cors => {})->to_app;
    is(hdr(req($app, path => '/pets',
               env => { HTTP_ORIGIN => 'https://anywhere.example' }),
           'Access-Control-Allow-Origin'), '*',
       'default CORS is public (wildcard ACAO)');

    my $cred = Open::API::Plack->new(api => $api, handlers => \%H,
        cors => { origins => [ 'https://app.example.com' ], credentials => 1 })->to_app;
    my $r = req($cred, path => '/pets',
                env => { HTTP_ORIGIN => 'https://app.example.com' });
    is(hdr($r, 'Access-Control-Allow-Credentials'), 'true',
       'credentials => 1 sets Allow-Credentials');
    is(hdr($r, 'Access-Control-Allow-Origin'), 'https://app.example.com',
       'credentialed ACAO echoes the concrete origin');

    my $err;
    eval { Open::API::Plack->new(api => $api, handlers => \%H, cors => { credentials => 1 })->to_app }
        or $err = $@;
    like($err, qr/wildcard '\*' origin cannot be used with credentials/,
         'wildcard origin + credentials is refused at to_app');
}

# ---- content negotiation: 415 / 406 (opt-in) ------------------------------------
{
    my $app = Open::API::Plack->new(api => $api, handlers => \%H, negotiate => 1)->to_app;

    is(req($app, method => 'POST', path => '/pets',
           ctype => 'application/xml', body => '<pet/>')->[0], 415,
       '415 for an undeclared request Content-Type');
    is(req($app, method => 'POST', path => '/pets',
           ctype => 'application/json', body => $VALID)->[0], 201,
       'a declared Content-Type passes');

    is(req($app, path => '/pets',
           env => { HTTP_ACCEPT => 'application/xml' })->[0], 406,
       '406 when Accept admits none of the declared response types');
    is(req($app, path => '/pets',
           env => { HTTP_ACCEPT => 'application/json' })->[0], 200,
       'a matching Accept passes');
    is(req($app, path => '/pets',
           env => { HTTP_ACCEPT => '*/*' })->[0], 200,
       'a wildcard Accept passes');
}

# ---- RFC 7807 problem+json ------------------------------------------------------
{
    my $app = Open::API::Plack->new(api => $api, handlers => \%H, error_format => 'problem')->to_app;

    my $nf = req($app, path => '/nope');
    is($nf->[0], 404, 'a 404 status');
    is(hdr($nf, 'Content-Type'), 'application/problem+json',
       'problem+json content-type on errors');
    my $p = body_json($nf);
    is($p->{status}, 404, 'problem body has status');
    is($p->{title},  'Not Found', 'problem body has title');
    is($p->{type},   'about:blank', 'problem body has type');

    my $bad = req($app, method => 'POST', path => '/pets',
                  ctype => 'application/json', body => '{"id":"nope"}');
    is($bad->[0], 400, 'a validation 400 status');
    my $pb = body_json($bad);
    is($pb->{status}, 400, 'problem body carries the 400');
    ok(ref $pb->{errors} eq 'ARRAY', 'validation errors preserved under errors');

    # a successful (2xx) response is untouched by problem conversion
    my $okp = req($app, path => '/pets');
    is(hdr($okp, 'Content-Type'), 'application/json', '2xx stays application/json');
}

done_testing();
