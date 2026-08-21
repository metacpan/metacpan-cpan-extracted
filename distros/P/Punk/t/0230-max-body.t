#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Punk ();

# The `max_body` keyword and its per-route override.
#
# THIS IS POLICY, NOT MEMORY PROTECTION, and the distinction is the reason
# the POD says so twice. By the time punk_serve runs, the request body is
# already fully resident in the server's read buffer - the memory was spent
# before Punk was called. What this check buys is the body parse, the
# multipart walk, the guards, the handler, and an honest 413 instead of a
# mysterious success. The memory bound is the server's own ceiling
# (Hyperman's `max_body`), and this cannot stand in for it.

our @RAN;   # side effects, to prove what did NOT run

{
    package App;
    use Punk;

    max_body 1000;

    post '/plain'  => sub { $_[0]->text('ok') };
    post '/raised' => sub { $_[0]->text('ok') }, { max_body => 100_000 };
    post '/lowered'=> sub { $_[0]->text('ok') }, { max_body => 10 };
    post '/off'    => sub { $_[0]->text('ok') }, { max_body => 0 };

    # a guard with a visible side effect: the limit must beat it
    my $guard = sub { push @main::RAN, 'guard'; return };
    my $scope = under '/guarded' => $guard;
    $scope->post('/x' => sub { push @main::RAN, 'handler'; $_[0]->text('ok') });

    package main;
}

my $app = App->to_app;

sub hit {
    my ($path, $len) = @_;
    open my $in, '<', \'';
    my $res = $app->({
        REQUEST_METHOD => 'POST',
        PATH_INFO      => $path,
        QUERY_STRING   => '',
        SERVER_NAME    => 'localhost', SERVER_PORT => 80,
        HTTP_HOST      => 'localhost', 'psgi.url_scheme' => 'http',
        'psgi.input'   => $in,
        (defined $len ? (CONTENT_LENGTH => $len) : ()),
    });
    my $body = ref $res->[2] eq 'ARRAY' ? join('', @{ $res->[2] }) : '';
    return ($res->[0], $body, { @{ $res->[1] } });
}

# ---- the app-wide ceiling --------------------------------------------------

is +(hit('/plain', 500))[0],  200, 'a body under the app-wide ceiling passes';
is +(hit('/plain', 1000))[0], 200, 'exactly at the ceiling passes';
is +(hit('/plain', 1001))[0], 413, 'one byte over is refused';
is +(hit('/plain', 99999))[0], 413, 'far over is refused';

# No CONTENT_LENGTH means a chunked request, which the server has already
# decoded and bounded by the time we see it. Nothing to check here.
is +(hit('/plain', undef))[0], 200,
   'a request with no CONTENT_LENGTH is passed through';

# ---- per-route overrides ---------------------------------------------------

is +(hit('/raised', 50_000))[0], 200,
   'a route may raise the ceiling above the app-wide one';
is +(hit('/raised', 200_000))[0], 413, '...and its own value still binds';

is +(hit('/lowered', 500))[0], 413,
   'a route may lower the ceiling below the app-wide one';
is +(hit('/lowered', 5))[0], 200, '...under its own value it passes';

# 0 on a route is legitimate and means "do not check here" - unlike the
# server's ceiling, this one is not the memory backstop, so switching it off
# is a real choice and not a footgun.
is +(hit('/off', 5_000_000))[0], 200,
   'max_body => 0 on a route disables the check there';

# ---- the check runs BEFORE the guards --------------------------------------

# This is the whole point of where it sits. An oversize request must cost no
# auth lookup, no validation, no body parse and no Perl frame - so the
# guard's side effect must NOT have happened.
{
    local @RAN = ();
    my ($st) = hit('/guarded/x', 5_000);
    is $st, 413, 'an oversize request under a guard is refused';
    is_deeply \@RAN, [],
       '...and neither the guard nor the handler ran';
}
{
    local @RAN = ();
    my ($st) = hit('/guarded/x', 10);
    is $st, 200, 'an ordinary request under the same guard is served';
    is_deeply \@RAN, ['guard', 'handler'], '...running both';
}

# ---- the 413 itself --------------------------------------------------------

{
    my (undef, $body, $h) = hit('/plain', 99999);
    is $h->{'Content-Type'}, 'application/json',
       'the 413 is JSON, like the house 404 and 405';
    like $body, qr/Payload Too Large/, '...with a message saying so';
}

# The OpenAPI mount has always had its own `max_body_size` doing exactly
# this. Since 0.17 both go through one function, so a client cannot tell a
# plain route's refusal from an operation's.
SKIP: {
    eval { require Open::API; 1 } or skip 'Open::API not available', 1;
    my $spec = {
        openapi => '3.1.0',
        info    => { title => 't', version => '1' },
        paths   => {
            '/thing' => {
                post => {
                    operationId => 'makeThing',
                    responses   => { '200' => { description => 'ok' } },
                },
            },
        },
    };
    our $SPEC = $spec;
    my $built = eval {
        package ApiApp66;
        use Punk;
        api $main::SPEC => {
            max_body_size => 1000,
            handlers      => { makeThing => sub { $_[0]->json({ ok => 1 }) } },
        };
        __PACKAGE__->to_app;
    };
    skip "api mount unavailable: $@", 1 unless $built;

    open my $in, '<', \'';
    my $res = $built->({
        REQUEST_METHOD => 'POST', PATH_INFO => '/thing',
        QUERY_STRING => '', SERVER_NAME => 'localhost', SERVER_PORT => 80,
        HTTP_HOST => 'localhost', 'psgi.url_scheme' => 'http',
        'psgi.input' => $in, CONTENT_LENGTH => 99999,
    });
    my $api_body = ref $res->[2] eq 'ARRAY' ? join('', @{ $res->[2] }) : '';
    my (undef, $route_body) = hit('/plain', 99999);
    is $api_body, $route_body,
       'an OpenAPI operation and a plain route give byte-identical 413s';
}

# ---- boot-time validation --------------------------------------------------

sub boot_fails {
    my ($body, $like, $what) = @_;
    my $pkg = 'MBoot' . int(rand 1e9);
    eval "package $pkg; use Punk; $body; ${pkg}->to_app; 1";
    like $@ || '', $like, $what;
}

boot_fails 'max_body',        qr/needs a byte count/,
    'a bare max_body croaks';
boot_fails 'max_body -1',     qr/must not be negative/,
    'a negative ceiling croaks';
boot_fails 'max_body [1000]', qr/not a reference/,
    'a reference croaks';
boot_fails q{post '/x' => sub { 1 }, { max_bdy => 10 }},
    qr/unknown route option 'max_bdy'/,
    'a misspelled route option still croaks, naming itself';

done_testing;
