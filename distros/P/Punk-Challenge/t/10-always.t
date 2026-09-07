#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Temp ();
use Punk::Test;
use Punk::Challenge::Token ();
use Punk::Challenge::Solver ();

# `always` rules through a request: the interstitial for a browser, the JSON
# for anything else, exempt, prefix and static untouched, a clearance
# through, and the first applicable rule deciding.

# `our`, because the package blocks below read $main::STATIC: a lexical
# here would hand `static` an undef root, which Punk accepts at boot.
our $STATIC = File::Temp::tempdir(CLEANUP => 1);
{
    open my $fh, '>', "$STATIC/site.css" or die "$STATIC/site.css: $!";
    print $fh "body { color: #333 }\n";
    close $fh;
}

{
    package Rules;
    use Punk;
    use Punk::Plugin::Challenge;

    plugin 'Challenge' => { secret => 'k', bits => 8, exempt => ['/health'] };
    static '/static' => $main::STATIC;

    challenge for => '/login', always => 1, bits => 10;
    challenge for => '/api',   always => 1;
    challenge for => '/login/deeper', always => 1, bits => 12;   # never reached

    get '/'            => sub { $_[0]->text('home') };
    get '/login'       => sub { $_[0]->text('login') };
    get '/login/deeper'=> sub { $_[0]->text('deeper') };
    get '/loginx'      => sub { $_[0]->text('loginx') };
    get '/api/x'       => sub { $_[0]->text('x') };
    get '/api/:name'   => sub { $_[0]->text('named') };
    get '/health'      => sub { $_[0]->text('ok') };
    get '/challenge/anything' => sub { $_[0]->text('mine') };
}

my $T = Punk::Challenge::Token::;
my %cfg = ( secret => 'k', bits => 8 );
my $A = { REMOTE_ADDR => '192.0.2.7' };
my $HTML = { Accept => 'text/html,application/xhtml+xml,*/*;q=0.8' };

my $t = Punk::Test->new('Rules');

# ---- untouched -------------------------------------------------------------------

$t->get_ok('/', env => $A)->status_is(200)->content_is('home', 'no rule covers the root');
$t->get_ok('/static/site.css', env => $A)->status_is(200)
  ->content_like(qr/color/, 'a static file is served: a mount never reaches a rule');
$t->get_ok('/loginx', env => $A)->status_is(200)->content_is('loginx', 'a prefix is a path segment, not a string prefix');
$t->get_ok('/health', env => $A)->status_is(200)->content_is('ok', 'an exempt path passes');
$t->get_ok('/challenge/anything', env => $A)->status_is(200)->content_is('mine', "the plugin's own prefix passes");

# ---- a browser gets the page ---------------------------------------------------------

$t->get_ok('/login', env => $A, headers => $HTML)
  ->status_is(503, 'a browser without a clearance gets a 503')
  ->header_like('Content-Type', qr{^text/html}, '  as html')
  ->header_is('Cache-Control', 'no-store', '  not cached')
  ->header_is('Retry-After', '0', '  retry now')
  ->header_like('Vary', qr/Accept/, '  varying on Accept')
  ->content_like(qr/<meta name="robots" content="noindex">/, '  noindex')
  ->content_like(qr/data-puzzle="v1\.\d+\.10\.[0-9a-z-]+\.[A-Za-z0-9_-]{22}"/, "  the rule's puzzle, at the rule's bits")
  ->content_like(qr/data-bits="10"/, '  the bits')
  ->content_like(qr{data-verify="/challenge/verify"}, '  the verify route')
  ->content_like(qr{data-to="/login"}, '  the return path')
  ->content_like(qr{<form method="post" action="/challenge/verify">}, '  the form posts to verify')
  ->content_like(qr{<input type="hidden" name="to" value="/login">}, '  carrying the return path')
  ->content_like(qr{<script src="/challenge/challenge\.js\?v=\Q$Punk::Challenge::VERSION\E"></script>}, '  and loads the solver by version')
  ->content_unlike(qr/<script>/, '  with no inline script')
  ->content_unlike(qr/<style/, '  and no inline style');
ok(!defined $t->header('X-Challenge'), '  and no X-Challenge header on the page');

{
    my ($puzzle) = $t->body =~ /data-puzzle="([^"]+)"/;
    is(scalar $T->verify(\%cfg, $T->subject('192.0.2.7'), Punk::Challenge::Solver::solve($puzzle), undef, bits => 10), 10,
        '  the puzzle in the page is bound to the request subject');
}

# The return path reflects this request's URL, encoded and escaped.
$t->get_ok('/login?next=%2Faccount&x=1', env => $A, headers => $HTML)
  ->content_like(qr{data-to="/login\?next=%2Faccount&amp;x=1"}, 'the query travels with the return path, escaped');
$t->get_ok('/api/a b"<c', env => $A, headers => $HTML)
  ->status_is(503)
  ->content_like(qr{data-to="/api/a%20b%22%3Cc"}, 'a decoded path is encoded again before it is reflected');

# A path no route matches is a 404 before any rule runs: before_dispatch
# runs after routing. Nothing is paid for a URL that does not exist.
$t->get_ok('/nowhere/at/all', env => $A, headers => $HTML)
  ->status_is(404, 'an unrouted path is a 404, not a challenge');
$t->get_ok('/api/x', env => { %$A, SCRIPT_NAME => '/app' }, headers => $HTML)
  ->content_like(qr{data-verify="/app/challenge/verify"}, 'under a mount, the verify route follows SCRIPT_NAME')
  ->content_like(qr{data-to="/app/api/x"}, '  and so does the return path')
  ->content_like(qr{<script src="/app/challenge/challenge\.js}, '  and the solver');

# ---- anything else gets JSON ---------------------------------------------------------------

$t->get_ok('/api/x', env => $A)
  ->status_is(403, 'a client with no Accept gets a 403')
  ->header_like('Content-Type', qr{^application/json}, '  as JSON')
  ->header_is('Cache-Control', 'no-store', '  not cached')
  ->header_like('Vary', qr/Accept/, '  varying on Accept')
  ->header_like('X-Challenge', qr/^v1\.\d+\.8\./, '  with the puzzle in X-Challenge at the default bits')
  ->json_is('/error', 'challenge')
  ->json_is('/challenge/bits', 8)
  ->json_is('/challenge/verify', '/challenge/verify')
  ->json_is('/challenge/header', 'X-Challenge-Response');
is($t->json->{challenge}{puzzle}, $t->header('X-Challenge'), '  the body and the header carry the same puzzle');

$t->get_ok('/api/x', env => $A, headers => { Accept => '*/*' })
  ->status_is(403, "curl's wildcard is not a browser");
$t->get_ok('/api/x', env => $A, headers => { Accept => 'application/json' })
  ->status_is(403, 'and JSON asked for is JSON');
$t->get_ok('/api/x', env => $A, headers => { Accept => 'text/html' })
  ->status_is(503, 'only text/html is the page');

# ---- a clearance goes through ----------------------------------------------------------------

{
    my $c = Punk::Test->new('Rules');
    my $subject = $T->subject('192.0.2.7');
    $c->get_ok('/api/x', env => $A, headers => { 'X-Clearance' => $T->clear(\%cfg, $subject, bits => 8) })
      ->status_is(200)->content_is('x', 'an eight-bit clearance clears the eight-bit rule');
    $c->get_ok('/login', env => $A, headers => { 'X-Clearance' => $T->clear(\%cfg, $subject, bits => 8) })
      ->status_is(403, '  and not the ten-bit rule');
    $c->get_ok('/login', env => $A, headers => { 'X-Clearance' => $T->clear(\%cfg, $subject, bits => 10) })
      ->status_is(200)->content_is('login', '  which a ten-bit one does');
    $c->get_ok('/api/x', env => { REMOTE_ADDR => '198.51.100.7' },
               headers => { 'X-Clearance' => $T->clear(\%cfg, $subject, bits => 8) })
      ->status_is(403, '  and a clearance from another subject is no clearance');
    my $p = $T->issue(\%cfg, $subject, bits => 8);
    $c->get_ok('/api/x', env => $A, headers => { 'X-Challenge-Response' => Punk::Challenge::Solver::solve($p) })
      ->status_is(200)->content_is('x', 'a solution in X-Challenge-Response clears');
}

# ---- the first rule wins ------------------------------------------------------------------

$t->get_ok('/login/deeper', env => $A, headers => $HTML)
  ->status_is(503)
  ->content_like(qr/data-bits="10"/, 'the first rule covering the path decides, not the more specific one below it');

# ---- through the guard, the same answer ----------------------------------------------------

{
    package Guarded;
    use Punk;
    use Punk::Plugin::Challenge;
    plugin 'Challenge' => { secret => 'k', bits => 8 };
    static '/static' => $main::STATIC;
    challenge for => '/', always => 1;
    my $acct = under '/account' => challenge_guard(bits => 9);
    $acct->get('/' => sub { $_[0]->text('account') });
    get '/open' => sub { $_[0]->text('open') };
}
{
    my $g = Punk::Test->new('Guarded');
    $g->get_ok('/static/site.css', env => $A)->status_is(200,
        'nobody solves a puzzle to fetch a stylesheet, even under a rule on /');
    $g->get_ok('/open', env => $A)->status_is(403, '  while the route beside it is challenged');
}
{
    package GuardOnly;
    use Punk;
    use Punk::Plugin::Challenge;
    plugin 'Challenge' => { secret => 'k', bits => 8 };
    my $acct = under '/account' => challenge_guard(bits => 9);
    $acct->get('/' => sub { $_[0]->text('account') });
    get '/open' => sub { $_[0]->text('open') };
}
{
    my $g = Punk::Test->new('GuardOnly');
    $g->get_ok('/open', env => $A)->status_is(200)->content_is('open', 'no rule, no guard: through');
    $g->get_ok('/account', env => $A, headers => $HTML)
      ->status_is(503)->content_like(qr/data-bits="9"/, 'the guard demands at its own bits');
    $g->get_ok('/account', env => $A)->status_is(403)->json_is('/challenge/bits', 9, '  as JSON too');
    $g->get_ok('/account', env => $A,
               headers => { 'X-Clearance' => $T->clear(\%cfg, $T->subject('192.0.2.7'), bits => 9) })
      ->status_is(200)->content_is('account', '  and a clearance at nine goes through');
}

done_testing;
