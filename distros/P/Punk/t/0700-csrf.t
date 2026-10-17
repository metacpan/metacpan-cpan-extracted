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
        QUERY_STRING   => $a{query}  // '',
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

    # A browser attaches these by itself, cross-site, exactly as it does a
    # cookie - so they are no evidence a script built the request.
    for my $ambient ('Basic dXNlcjpwYXNz', 'basic dXNlcjpwYXNz',
                     'Digest username="u"', 'Negotiate YII=', 'NTLM TlRM',
                     'Bearer', '   ') {
        my $r = hit(method => 'POST', path => '/save', body => 'a=1',
                    auth => $ambient);
        is($r->{status}, 403, "Authorization: '$ambient' does not skip it");
    }
    for my $explicit ('bearer abc123', 'Token abc', 'DPoP abc') {
        my $r = hit(method => 'POST', path => '/save', body => 'a=1',
                    auth => $explicit);
        is($r->{status}, 200, "Authorization: '$explicit' does");
    }
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

{   # The query string is not a way in: a token there is a token in every
    # access log and Referer the URL reaches.
    my $tok = hit()->{body};
    my $q = hit(method => 'POST', path => '/save', body => 'a=query',
                query => "_csrf=$tok");
    is($q->{status}, 403, 'a token in the query string is refused');
    my $both = hit(method => 'POST', path => '/save',
                   body => "_csrf=$tok&a=both", query => '_csrf=wrong');
    is($both->{status}, 200,
        '...and one there does not shadow the one in the form');
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

{
    package SegmentApp;
    use Punk;
    session secret => 'k';
    csrf exempt => [ '/hooks', '/cb/' ];
    post '/hooks'             => sub { $_[0]->text('root') };
    post '/hooks/stripe'      => sub { $_[0]->text('hook') };
    post '/hooksadmin/delete' => sub { $_[0]->text('admin') };
    post '/cb/x'              => sub { $_[0]->text('cb') };
    post '/cb'                => sub { $_[0]->text('cbroot') };
}
{
    my $seg = SegmentApp->to_app;
    my $post = sub {
        my ($p) = @_;
        open my $in, '<', \'';
        return $seg->({ REQUEST_METHOD => 'POST', PATH_INFO => $p,
                        QUERY_STRING => '', SERVER_NAME => 'l',
                        SERVER_PORT => 80, HTTP_HOST => 'l',
                        'psgi.url_scheme' => 'http', 'psgi.input' => $in })->[0];
    };
    is($post->('/hooks'), 200, 'an exempt path covers itself');
    is($post->('/hooks/stripe'), 200, '...and what is under it');
    is($post->('/hooksadmin/delete'), 403,
        '...and not a sibling that only shares its spelling');
    is($post->('/cb/x'), 200, 'a prefix with a trailing slash covers what is under it');
    is($post->('/cb'), 403, '...and not the path without the slash');
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

# ---- the bare form from punk.yml --------------------------------------------
# YAML::XS hands Punk::Config a JSON::PP::Boolean for a bare `true` - a
# blessed scalar ref, not the scalar 1 - and `csrf: true` has to register
# from that exactly as `csrf;` does. It silently did not, once: the bare
# form was tested as "a true non-reference", and a boolean object is
# neither, so the keyword never registered and the first csrf_field was a
# 500 at request time.
SKIP: {
    skip 'YAML::XS required for the config half', 12
        unless eval { require YAML::XS; 1 };
    require File::Temp;
    require Punk::Test;
    my $dir = File::Temp->newdir;
    my $n = 0;
    for my $case ([ 'true', 1 ], [ 'false', 0 ], [ '{}', 1 ]) {
        my ($yml, $on) = @$case;
        open my $fh, '>', "$dir/punk.yml" or die $!;
        print $fh "session:\n  secret: { \$literal: " . ('x' x 32) . " }\ncsrf: $yml\n";
        close $fh;
        my $pkg = 'YmlCsrf' . $n++;
        eval qq{
            package $pkg;
            use Punk;
            config "$dir/punk.yml";
            get  '/'     => sub { \$_[0]->html(\$_[0]->csrf_field) };
            post '/save' => sub { \$_[0]->text('saved') };
            1;
        } or die $@;
        my $t = Punk::Test->new($pkg);
        if ($on) {
            $t->get_ok('/')->status_is(200)
              ->content_like(qr/name="_csrf"/, "csrf: $yml registers the keyword");
            $t->post_ok('/save')
              ->status_is(403, '  and an unsafe request without a token is refused');
        }
        else {
            $t->post_ok('/save')->status_is(200, "csrf: $yml leaves it off");
        }
    }
}

# ---- the refusal survives a stack the hook grew ---------------------------------
# _check pushes its 403 after pcf_check ran Perl. A hook that grows the value
# stack moves it, and a push through the pointer captured on entry landed in
# freed memory: the dispatcher saw a GLOB where the triplet should have been.
{
    package CsrfGrow;
    use Punk;
    session secret => 'k';
    csrf on_error => sub { my @x = (1) x $main::GROW;
                           [ 403, [ 'Content-Type' => 'text/plain' ], ['refused'] ] };
    post '/p' => sub { $_[0]->text('posted') };
    package main;
    our $GROW;
    my $g = CsrfGrow->to_app;
    for my $n (1_000, 2_000_000) {
        $GROW = $n;
        my $body = 'a=1';
        open my $in, '<', \$body;
        my $r = $g->({ REQUEST_METHOD => 'POST', PATH_INFO => '/p',
                       QUERY_STRING => '', CONTENT_LENGTH => 3,
                       CONTENT_TYPE => 'application/x-www-form-urlencoded',
                       'psgi.input' => $in, HTTP_HOST => 'l',
                       REMOTE_ADDR => '1.1.1.1' });
        is(ref $r, 'ARRAY', "a forged POST is still a triplet after on_error grew the stack by $n");
        is($r->[0], 403, '...a 403');
        is($r->[2][0], 'refused', '...with the hook\'s body');
    }
}

# ---- options are checked at the keyword ----------------------------------------
# The mirror cookie is written inside a trapped after-hook, so a name the
# cookie builder refuses used to make the cookie silently disappear.
{
    my $err = '';
    eval { package CsrfBadCookie; use Punk; session secret => 'k';
           csrf cookie => 'a;b'; 1 } or $err = $@;
    like($err, qr/csrf `cookie` may not contain/,
        'a csrf cookie name with a ";" croaks at the keyword');
    $err = '';
    eval { package CsrfLongHeader; use Punk; session secret => 'k';
           csrf header => ('X' x 130); 1 } or $err = $@;
    like($err, qr/csrf `header` name is longer/,
        'a header name over the env key\'s size croaks at the keyword');
}

done_testing();
