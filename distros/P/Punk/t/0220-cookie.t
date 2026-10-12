#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use PunkTest;

# $c->cookie: set a Set-Cookie on the response, read a request cookie, delete.

{
    package CApp;
    use Punk;
    get '/set' => sub { my $c = shift;
        $c->cookie(sid => 'abc', max_age => 3600, httponly => 1,
                   samesite => 'Lax', secure => 1);
        $c->text('ok');
    };
    get '/two' => sub { my $c = shift;
        $c->cookie(a => 1); $c->cookie(b => 2); $c->text('ok');
    };
    get '/del'  => sub { my $c = shift; $c->cookie(sid => undef); $c->text('bye') };
    get '/enc'  => sub { my $c = shift; $c->cookie(x => 'a b;c'); $c->text('ok') };
    get '/read' => sub { my $c = shift; $c->text($c->cookie('sid') // 'none') };
    package main;
}

my $app = CApp->to_app;
sub set_cookies {
    my ($r) = @_;
    my @c;
    for (my $i = 0; $i < @{ $r->[1] }; $i += 2) {
        push @c, $r->[1][$i + 1] if $r->[1][$i] eq 'Set-Cookie';
    }
    return @c;
}

my ($sc) = set_cookies(hit($app, path => '/set'));
like($sc, qr/^sid=abc;/, 'sets the cookie value');
like($sc, qr/Path=\//,        'Path=/ by default');
like($sc, qr/Max-Age=3600/,   'Max-Age');
like($sc, qr/HttpOnly/,       'HttpOnly');
like($sc, qr/SameSite=Lax/,   'SameSite');
like($sc, qr/Secure/,         'Secure');

my @two = set_cookies(hit($app, path => '/two'));
is(scalar @two, 2, 'two cookies -> two Set-Cookie headers');

my ($del) = set_cookies(hit($app, path => '/del'));
like($del, qr/sid=; .*Max-Age=0/, 'undef value deletes the cookie');

my ($enc) = set_cookies(hit($app, path => '/enc'));
like($enc, qr/^x=a%20b%3Bc;/, 'unsafe value bytes are percent-encoded');

my $r = hit($app, path => '/read', env => { HTTP_COOKIE => 'sid=abc; k=v' });
is($r->[2][0], 'abc', 'one-arg cookie() reads the request cookie');

# ---- nothing unencoded can carry an attribute or a header ---------------------

{
    package CBad;
    use Punk;
    get '/bad' => sub {
        my ($c) = @_;
        my $what = $c->param('what');
        my $v    = $c->param('v');
        my $ok = eval {
            $what eq 'name' ? $c->cookie($v => 'x') : $c->cookie(x => 'y', $what => $v);
            1;
        };
        $c->text($ok ? 'set' : "refused: $@");
    };
    package main;
}
{
    my $bad = CBad->to_app;
    my @cases = (
        [ path     => '/%0d%0aSet-Cookie:%20a=b', 'CRLF in path' ],
        [ path     => '/%3B%20Domain=evil.example',  'a semicolon in path' ],
        [ domain   => 'a.example%0aX:%20y',        'LF in domain' ],
        [ domain   => 'a.example%00',              'NUL in domain' ],
        [ samesite => 'Lax%3B%20Secure',             'a semicolon in samesite' ],
        [ name     => 'a%0d%0ab',                  'CRLF in the name' ],
        [ name     => 'a%3Bb',                     'a semicolon in the name' ],
        [ name     => 'a=b',                       'an equals in the name' ],
        [ name     => '',                          'an empty name' ],
    );
    for my $case (@cases) {
        my ($what, $v, $label) = @$case;
        my $r = hit($bad, path => '/bad', query => "what=$what&v=$v");
        like($r->[2][0], qr/\Arefused: Punk: a cookie /, "$label is refused");
        is(scalar set_cookies($r), 0, '...and nothing is set');
    }
    my $r = hit($bad, path => '/bad', query => 'what=path&v=/app/x');
    is($r->[2][0], 'set', 'an ordinary path passes');
    like((set_cookies($r))[0], qr/\Ax=y; Path=\/app\/x\z/, '...verbatim');

    for my $opt ([ path => "/\r\nX: y" ], [ domain => 'a;b' ],
                 [ cookie => "s\nid" ], [ samesite => 'Lax; x' ]) {
        my $err = '';
        eval { Punk::App->new->session(secret => 'k', @$opt); 1 } or $err = $@;
        like($err, qr/session `$opt->[0]` may not contain/,
            "the session keyword refuses a bad $opt->[0] at boot");
    }
}

done_testing;
