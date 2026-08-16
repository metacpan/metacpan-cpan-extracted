#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use Punk::Test;
use File::Raw::JSON qw(file_json_decode);

# Development error pages (Punk::DevError, wired by compile_extras). The
# properties that matter: a browser in dev gets a debug page carrying the
# throw site and the request; an API client in dev gets the production
# JSON shape plus a trace; production stays byte-identical to the C
# default; a user on_error keeps absolute priority; and nothing secret
# reaches the page bytes.
#
# Development is an opt-in (the default environment is production), so
# every dev app below compiles under an explicit PUNK_ENV.
$ENV{PUNK_ENV} = 'development';

# every secret below is assembled at runtime: the page legitimately renders
# source snippets, so a literal secret in this file would appear in its own
# call-site frame and fail the very redaction it is testing
my $SECRET_VALUE = join '-', qw(hunter2 in the session);
my $PASSWORD     = join '',  qw(let me in);
my $BEARER       = join '',  qw(abc 123);
my $HDR_TOKEN    = join '-', qw(sekret header value);

{
    package DevApp;
    use Punk;
    session secret => 'test-key';

    get '/boom' => sub {
        my ($c) = @_;
        $c->session->{card} = $SECRET_VALUE;
        die "kapow\n";
    };
    get '/deep/:id' => sub { deeper() };
    sub deeper { die 'from deeper' }
    get '/fine' => sub { $_[0]->text('fine') };
}

my $t = Punk::Test->new('DevApp');

# ---- the HTML page ------------------------------------------------------------

$t->get_ok("/boom?password=$PASSWORD&plain=visible",
           headers => { Accept        => 'text/html,application/xhtml+xml',
                        'X-Api-Token' => $HDR_TOKEN,
                        Authorization => "Bearer $BEARER" },
           name => 'a browser asks for the dying route')
  ->status_is(500)
  ->header_like('Content-Type' => qr{^text/html})
  ->content_like(qr/kapow/,                'the message is on the page')
  ->content_like(qr/GET/,                  'so is the method')
  ->content_like(qr{/boom},                'and the path')
  ->content_like(qr/46-dev-error\.t/,      'a frame names the throw site')
  ->content_like(qr/class="snippet"/,      'with a source snippet')
  ->content_like(qr/class="ln hit"/,       'marking the dying line')
  ->content_like(qr/plain.*visible/s,      'ordinary params are shown')
  ->content_unlike(qr/\Q$PASSWORD\E/,      'a password param is redacted, query line included')
  ->content_unlike(qr/\Q$BEARER\E/,        'the Authorization value is redacted')
  ->content_unlike(qr/\Q$HDR_TOKEN\E/,     'a token-named header is redacted')
  ->content_unlike(qr/\Q$SECRET_VALUE\E/,  'session contents never reach the page');

# the session cookie itself must not be rendered either
$t->get_ok('/boom', headers => { Accept => 'text/html' })->status_is(500);
ok(defined $t->cookie('punk.sid'), 'the session cookie exists by now');
$t->content_unlike(qr/\Q${\ $t->cookie('punk.sid') }\E/,
    'and its value is not in the page bytes');

# ---- JSON for API clients ------------------------------------------------------

$t->get_ok('/deep/7', name => 'an API client (no text/html accept)')
  ->status_is(500)
  ->header_is('Content-Type' => 'application/json')
  ->json_like('/errors/0/message' => qr/from deeper/)
  ->json_has('/errors/0/trace');
{
    my $trace = $t->json->{errors}[0]{trace};
    ok(ref $trace eq 'ARRAY' && @$trace, 'the trace has frames');
    ok((grep { /46-dev-error\.t:\d+/ } @$trace),
        'one of them is the throw site, file:line');
    ok((grep { /DevApp::deeper/ } @$trace),
        'and the enclosing sub is named');
}

# ---- a healthy route is untouched ---------------------------------------------

$t->get_ok('/fine')->status_is(200)->content_is('fine');

# ---- the user's on_error still wins -------------------------------------------

{
    package RescueDevApp;
    use Punk;
    on_error sub { my ($c, $err) = @_; $c->json({ rescued => "$err" }, 599) };
    get '/boom' => sub { die "oops\n" };
    get '/decline' => sub { die "fell through\n" };
}
{
    my $r = Punk::Test->new('RescueDevApp');
    $r->get_ok('/boom', headers => { Accept => 'text/html' })
      ->status_is(599, 'a user handler returning a ref wins, even in dev')
      ->json_is('/rescued' => "oops\n");
}

{
    package DeclineDevApp;
    use Punk;
    on_error sub { return 0 };            # declines - no reference
    get '/boom' => sub { die "fell through\n" };
}
{
    my $d = Punk::Test->new('DeclineDevApp');
    $d->get_ok('/boom')
      ->status_is(500)
      ->json_like('/errors/0/message' => qr/fell through/)
      ->json_has('/errors/0/trace',
          'a declining handler falls to the dev page, not the bare 500');
}

# ---- production is byte-identical to the C default ----------------------------

{
    package ProdApp;
    use Punk;
    get '/boom' => sub { die "kapow\n" };
}
{
    my $app = do { local $ENV{PUNK_ENV} = 'production'; ProdApp->to_app };
    my $p = Punk::Test->new($app);
    $p->get_ok('/boom', headers => { Accept => 'text/html' })
      ->status_is(500)
      ->header_is('Content-Type' => 'application/json')
      ->content_is('{"errors":[{"message":"kapow\n"}]}',
          'the production 500 is the exact C default, trace-free');
}

# a production app compiled in a process that never saw a dev app must not
# even load the module - proven in a child with a clean %INC
{
    local $ENV{PUNK_ENV} = 'production';
    my $out = `$^X -Iblib/lib -Iblib/arch -e '{ package P; use Punk; get q(/x) => sub { die q(x) }; } my \$app = P->to_app; print \$INC{q(Punk/DevError.pm)} ? q(loaded) : q(not-loaded)'`;
    is($out, 'not-loaded', 'production never loads Punk::DevError at all');
}

# ---- the trace does not leak across requests ----------------------------------

{
    package TwoApp;
    use Punk;
    get '/a' => sub { die "first\n" };
    get '/b' => sub { my ($c) = @_; eval { die "inner\n" }; die "second\n" };
}
{
    my $x = Punk::Test->new('TwoApp');
    $x->get_ok('/a')->json_like('/errors/0/message' => qr/first/);
    $x->get_ok('/b')
      ->json_like('/errors/0/message' => qr/second/)
      ->json_has('/errors/0/trace');
    my $trace = join "\n", @{ $x->json->{errors}[0]{trace} };
    unlike($trace, qr/first/, 'no frames from the previous request');
}

done_testing();
