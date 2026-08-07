#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;

# Single-use CSRF tokens over the session (punk_csrf.h). The property that
# matters is the one a comment cannot guarantee: a token that has been spent
# must not work a second time. Everything here drives a real application
# through to_app with a cookie jar, because that is the only way to test a
# scheme whose whole state lives in the cookies.

{
    package CsrfApp;
    use Punk;
    session secret => 'test-key';
    csrf;

    get  '/'      => sub { my ($c) = @_; $c->text($c->csrf_token) };
    get  '/form'  => sub { my ($c) = @_; $c->html($c->csrf_field) };
    post '/save'  => sub { my ($c) = @_; $c->text('saved:' . ($c->param('a') // '-')) };
    put  '/put'   => sub { $_[0]->text('put') };
    post '/hooks/stripe' => sub { $_[0]->text('hook') };
}

my $app = CsrfApp->to_app;

# A browser: keeps the session cookie, and reads the script-visible mirror.
my ($JAR, $MIRROR);

sub hit {
    my (%a) = @_;
    my $body = $a{body};
    open my $in, '<', \(defined $body ? $body : '');
    my $env = {
        REQUEST_METHOD => $a{method} // 'GET',
        PATH_INFO      => $a{path}   // '/',
        QUERY_STRING   => '',
        SERVER_NAME    => 'localhost', SERVER_PORT => 80,
        HTTP_HOST      => 'localhost', 'psgi.url_scheme' => 'http',
        'psgi.input'   => $in,
    };
    if (defined $body) {
        $env->{CONTENT_LENGTH} = length $body;
        $env->{CONTENT_TYPE}   = $a{type}
            // 'application/x-www-form-urlencoded';
    }
    $env->{HTTP_COOKIE}        = $JAR  if $JAR && !$a{no_cookie};
    $env->{HTTP_X_CSRF_TOKEN}  = $a{token} if defined $a{token};
    $env->{HTTP_AUTHORIZATION} = $a{auth}  if $a{auth};

    my $r = $app->($env);
    my (@set, @hdr);
    @hdr = @{ $r->[1] };
    while (my ($k, $v) = splice @hdr, 0, 2) { push @set, $v if $k eq 'Set-Cookie' }
    for (@set) {
        $JAR    = $1 if /\A(punk\.sid=[^;]*)/;
        $MIRROR = $1 if /\Acsrf=([^;]*)/;
    }
    return { status => $r->[0], body => ($r->[2][0] // ''), set => \@set };
}

sub mirror_cookie { my ($r) = @_; return grep { /\Acsrf=/ } @{ $r->{set} } }

# ---- issuing ------------------------------------------------------------------

my $first = hit();
is($first->{status}, 200, 'GET / is served');
like($first->{body}, qr/\A[A-Za-z0-9_-]{43}\z/,
    'csrf_token is 43 characters of base64url - 32 random bytes');
my $token = $first->{body};

{
    my ($sid)  = grep { /\Apunk\.sid=/ } @{ $first->{set} };
    my ($mir)  = mirror_cookie($first);
    ok($sid, 'the session cookie carries the token');
    like($sid, qr/HttpOnly/, '...and stays HttpOnly');
    ok($mir, 'a mirror cookie is set for script to read');
    unlike($mir, qr/HttpOnly/i,
        '...and is deliberately not HttpOnly - fetch has to read it');
    like($mir, qr/\Acsrf=\Q$token\E/, 'the mirror holds the same token');
}

{
    my $f = hit(path => '/form');
    like($f->{body}, qr/\A<input type="hidden" name="_csrf" value="[A-Za-z0-9_-]{43}">\z/,
        'csrf_field is a ready-made hidden input');
}

# ---- single use ---------------------------------------------------------------
# The whole point. Spend it once, and it must never work again.

{
    my $ok = hit(method => 'POST', path => '/save', token => $token,
                 body => 'a=1');
    is($ok->{status}, 200, 'a POST carrying the token succeeds');
    is($ok->{body}, 'saved:1', '...and reaches the handler');

    my ($mir) = mirror_cookie($ok);
    ok($mir, 'the response re-issues the mirror cookie');
    unlike($mir, qr/\Acsrf=\Q$token\E;/, 'carrying a different token');
    isnt($MIRROR, $token, 'the token rotated');

    my $replay = hit(method => 'POST', path => '/save', token => $token,
                     body => 'a=2');
    is($replay->{status}, 403, 'the same token a second time is refused');
    like($replay->{body}, qr/invalid csrf token/, 'with the reason');

    my $fresh = hit(method => 'POST', path => '/save', token => $MIRROR,
                    body => 'a=3');
    is($fresh->{status}, 200, 'the rotated token works');
}

{   # The cost of strict single tokens, pinned so it is a decision and not a
    # surprise: a form rendered before a rotation is dead.
    my $stale = $MIRROR;
    hit(method => 'POST', path => '/save', token => $stale, body => 'a=4');
    my $second = hit(method => 'POST', path => '/save', token => $stale,
                     body => 'a=5');
    is($second->{status}, 403,
        'a second form rendered before the rotation is refused (keep => 1)');
}

# ---- what is and is not challenged --------------------------------------------

{
    for my $m (qw(GET HEAD OPTIONS)) {
        my $r = hit(method => $m, path => '/');
        isnt($r->{status}, 403, "$m is never challenged");
    }

    my $none = hit(method => 'POST', path => '/save', body => 'a=1');
    is($none->{status}, 403, 'an unsafe method with no token is refused');

    my $wrong = hit(method => 'POST', path => '/save', body => 'a=1',
                    token => 'x' x 43);
    is($wrong->{status}, 403, 'a wrong token is refused');

    my $put = hit(method => 'PUT', path => '/put');
    is($put->{status}, 403, 'PUT is challenged too');

    # Not riding on cookies, so not a CSRF target.
    my $bearer = hit(method => 'POST', path => '/save', body => 'a=1',
                     auth => 'Bearer abc123');
    is($bearer->{status}, 200, 'an Authorization header skips the check');
}

# ---- both ways in -------------------------------------------------------------

{
    my $tok = hit()->{body};
    my $field = hit(method => 'POST', path => '/save',
                    body => "_csrf=$tok&a=field");
    is($field->{status}, 200, 'the token may arrive in the form field');
    is($field->{body}, 'saved:field',
        '...and the body still reaches the handler afterwards');
}

{   # A multipart body must not be pulled into memory hunting for the field -
    # the mount's own max_body_size check has to get there first. So multipart
    # requires the header.
    my $tok = hit()->{body};
    my $mp  = qq{--X\r\nContent-Disposition: form-data; name="a"\r\n\r\nup\r\n--X--\r\n};
    my $no  = hit(method => 'POST', path => '/save', body => $mp,
                  type => 'multipart/form-data; boundary=X');
    is($no->{status}, 403, 'multipart with no header is refused');

    my $tok2 = hit()->{body};
    my $yes  = hit(method => 'POST', path => '/save', body => $mp,
                   type => 'multipart/form-data; boundary=X', token => $tok2);
    is($yes->{status}, 200, 'multipart with the header passes');
    is($yes->{body}, 'saved:up', '...and the upload still parses');
}

# ---- exempt paths -------------------------------------------------------------

{
    package ExemptApp;
    use Punk;
    session secret => 'k';
    csrf exempt => [ '/hooks/' ];
    post '/hooks/stripe' => sub { $_[0]->text('hook') };
    post '/other'        => sub { $_[0]->text('other') };
}
{
    my $ex = ExemptApp->to_app;
    my $env = sub {
        my ($p) = @_;
        open my $in, '<', \'';
        return { REQUEST_METHOD => 'POST', PATH_INFO => $p, QUERY_STRING => '',
                 SERVER_NAME => 'l', SERVER_PORT => 80, HTTP_HOST => 'l',
                 'psgi.url_scheme' => 'http', 'psgi.input' => $in };
    };
    is($ex->($env->('/hooks/stripe'))->[0], 200, 'an exempt prefix is skipped');
    is($ex->($env->('/other'))->[0], 403, 'everything else is still checked');
}

# ---- configuration ------------------------------------------------------------

{
    package NamedApp;
    use Punk;
    session secret => 'k';
    csrf field => 'authenticity_token', header => 'X-Token', cookie => 'xsrf';
    get  '/'  => sub { my ($c) = @_; $c->text($c->csrf_token) };
    get  '/f' => sub { my ($c) = @_; $c->html($c->csrf_field) };
    post '/s' => sub { $_[0]->text('ok') };
}
{
    my $na = NamedApp->to_app;
    my $jar;
    my $call = sub {
        my (%a) = @_;
        open my $in, '<', \($a{body} // '');
        my $e = { REQUEST_METHOD => $a{method} // 'GET', PATH_INFO => $a{path} // '/',
                  QUERY_STRING => '', SERVER_NAME => 'l', SERVER_PORT => 80,
                  HTTP_HOST => 'l', 'psgi.url_scheme' => 'http',
                  'psgi.input' => $in };
        $e->{HTTP_COOKIE}  = $jar if $jar;
        $e->{HTTP_X_TOKEN} = $a{token} if $a{token};
        if (defined $a{body}) {
            $e->{CONTENT_LENGTH} = length $a{body};
            $e->{CONTENT_TYPE} = 'application/x-www-form-urlencoded';
        }
        my $r = $na->($e);
        my @h = @{ $r->[1] };
        while (my ($k, $v) = splice @h, 0, 2) {
            $jar = $1 if $k eq 'Set-Cookie' && $v =~ /\A(punk\.sid=[^;]*)/;
        }
        return $r;
    };
    my $g = $call->();
    my $t = $g->[2][0];
    my @sc = do { my @h = @{ $g->[1] }; my @o;
                  while (my ($k,$v) = splice @h,0,2) { push @o,$v if $k eq 'Set-Cookie' } @o };
    ok((grep { /\Axsrf=/ } @sc), 'the mirror cookie name is configurable');
    like($call->(path => '/f')->[2][0], qr/name="authenticity_token"/,
        'the field name is configurable');
    is($call->(method => 'POST', path => '/s', token => $t)->[0], 200,
        'the header name is configurable');
}

# ---- it needs somewhere to live -----------------------------------------------

{
    package NoSession;
    use Punk;
    csrf;
    get '/' => sub { $_[0]->text('x') };
}
{
    my $err = '';
    eval { NoSession->to_app } or $err = $@;
    like($err, qr/needs a session/,
        'csrf without a session croaks at to_app, naming the fix');
}

done_testing();
