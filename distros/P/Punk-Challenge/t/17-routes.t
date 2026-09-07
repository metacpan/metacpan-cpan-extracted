#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Punk::Test;
use Punk::Challenge::Token ();
use Punk::Challenge::Solver ();

# The two routes: the solver served immutable, and verify in its form and
# JSON shapes, with a clearance out and a fresh challenge on failure.

{
    package Routes;
    use Punk;
    use Punk::Plugin::Challenge;
    plugin 'Challenge' => { secret => 'k', bits => 8, ttl => 120 };
    challenge for => '/gated', always => 1;
    get '/gated' => sub { $_[0]->text('in') };
    get '/open'  => sub { $_[0]->text('open') };
}

{
    package NoAssets;
    use Punk;
    use Punk::Plugin::Challenge;
    plugin 'Challenge' => { secret => 'k', bits => 8, assets => 0, prefix => '/c' };
    get '/open' => sub { $_[0]->text('open') };
}

my $T = Punk::Challenge::Token::;
my %cfg = ( secret => 'k', bits => 8 );
my $A = { REMOTE_ADDR => '192.0.2.7' };
my $SUBJ = $T->subject('192.0.2.7');
my $HTML = { Accept => 'text/html' };
my $JSON = { Accept => 'application/json' };

sub puzzle_for {
    my ($t) = @_;
    $t->get_ok('/gated', env => $A)->status_is(403);
    return $t->header('X-Challenge');
}

# ---- the asset -------------------------------------------------------------------

{
    my $t = Punk::Test->new('Routes');
    $t->get_ok('/challenge/challenge.js', env => $A)
      ->status_is(200, 'the solver is served')
      ->header_like('Content-Type', qr{^application/javascript}, '  as JavaScript')
      ->header_is('Cache-Control', 'public, max-age=31536000, immutable', '  immutable for a year')
      ->content_like(qr/PunkChallenge/, '  and is the solver');
    my $file = $INC{'Punk/Challenge.pm'};
    $file =~ s{Challenge\.pm\z}{Plugin/Challenge/challenge.js};
    open my $fh, '<:raw', $file or die "$file: $!";
    my $bytes = do { local $/; <$fh> };
    is($t->body, $bytes, '  byte for byte the shipped file');
    is($t->header('Content-Length'), length $bytes, '  with its length');
}

{
    my $n = Punk::Test->new('NoAssets');
    $n->get_ok('/c/challenge.js', env => $A)->status_is(404, 'assets => 0 serves no script');
    $n->post_ok('/c/verify', env => $A, json => {})->status_is(403, '  but verify is still there, under the prefix');
}

# ---- verify, JSON --------------------------------------------------------------------

{
    my $t = Punk::Test->new('Routes');
    my $puzzle = puzzle_for($t);
    my $sol = Punk::Challenge::Solver::solve($puzzle);

    $t->post_ok('/challenge/verify', env => $A, json => { solution => $sol })
      ->status_is(200, 'a correct solution as JSON is a 200')
      ->header_like('Content-Type', qr{^application/json})
      ->json_like('/clearance', qr/^v1\.\d+\.8\.[A-Za-z0-9_-]{22}\z/, '  with the clearance in the body')
      ->header_like('Set-Cookie', qr/^_clearance=v1\.\d+\.8\./, '  and in the cookie');
    my $clearance = $t->json->{clearance};
    is($T->cleared(\%cfg, $SUBJ, $clearance), 8,
        '  the body value verifies for the subject at the puzzle\'s bits');
    $t->get_ok('/gated', env => $A)->status_is(200)->content_is('in', '  and the jar now clears the rule');

    my $h = Punk::Test->new('Routes');
    $h->get_ok('/gated', env => $A, headers => { 'X-Clearance' => $clearance })
      ->status_is(200)->content_is('in', '  as does the body value in X-Clearance from a fresh jar');
}

# ---- verify, form ---------------------------------------------------------------------

{
    my $t = Punk::Test->new('Routes');
    my $sol = Punk::Challenge::Solver::solve(puzzle_for($t));
    $t->post_ok('/challenge/verify', env => $A, form => { solution => $sol, to => '/gated?x=1' })
      ->status_is(303, 'a correct solution as a form is a 303')
      ->header_is('Location', '/gated?x=1', '  to where the page said')
      ->header_like('Set-Cookie', qr/^_clearance=v1\./, '  with the cookie');
    $t->get_ok('/gated', env => $A)->status_is(200)->content_is('in', '  and the jar clears the rule');
}

for my $bad ('//evil.example', 'http://evil.example/', "/x\tevil", '/a\\b', '') {
    my $t = Punk::Test->new('Routes');
    my $sol = Punk::Challenge::Solver::solve(puzzle_for($t));
    $t->post_ok('/challenge/verify', env => $A, form => { solution => $sol, to => $bad })
      ->status_is(303)
      ->header_is('Location', '/', "to => '$bad' goes to the root instead");
}
{
    my $t = Punk::Test->new('Routes');
    my $sol = Punk::Challenge::Solver::solve(puzzle_for($t));
    $t->post_ok('/challenge/verify', env => $A, form => { solution => $sol })
      ->status_is(303)->header_is('Location', '/', 'no to goes to the root');
}

# ---- failure is a fresh challenge -----------------------------------------------------

{
    my $t = Punk::Test->new('Routes');
    my $puzzle = puzzle_for($t);
    my $sol = Punk::Challenge::Solver::solve($puzzle);
    (my $wrong = $sol) =~ s/(\d+)\z/$1 + 1/e;

    $t->post_ok('/challenge/verify', env => $A, json => { solution => $wrong }, headers => $JSON)
      ->status_is(403, 'a wrong solution is a 403')
      ->json_is('/error', 'challenge', '  in the challenge shape')
      ->header_like('X-Challenge', qr/^v1\./, '  with a new puzzle');
    isnt($t->header('X-Challenge'), $puzzle, '  a different one');
    ok(!defined $t->header('Set-Cookie'), '  and no cookie');

    $t->post_ok('/challenge/verify', env => $A, form => { solution => $wrong, to => '/gated' }, headers => $HTML)
      ->status_is(503, 'a wrong solution from a form, to a browser, is the page again')
      ->content_like(qr/data-puzzle="v1\./, '  with a new puzzle');

    $t->post_ok('/challenge/verify', env => $A, json => { solution => $sol }, headers => $JSON)
      ->status_is(200, 'the right one still verifies afterwards: no lockout');
}

{
    my $t = Punk::Test->new('Routes');
    my $sol = Punk::Challenge::Solver::solve(puzzle_for($t));
    $t->post_ok('/challenge/verify', env => { REMOTE_ADDR => '198.51.100.7' }, json => { solution => $sol })
      ->status_is(403, 'a solution presented from another subject is refused');
    $t->post_ok('/challenge/verify', env => $A, body => '{not json', type => 'application/json')
      ->status_is(403, 'a body that is not the JSON it claims is a 403, not a 500');
    $t->post_ok('/challenge/verify', env => $A, json => { solution => [ 'x' ] })
      ->status_is(403, 'a solution that is not a string is refused');
    $t->post_ok('/challenge/verify', env => $A, json => {})
      ->status_is(403, 'no solution is refused');
    $t->post_ok('/challenge/verify', env => $A, form => {})
      ->status_is(403, 'an empty form is refused');
    $t->post_ok('/challenge/verify', env => $A, body => "solution=$sol", type => 'text/plain')
      ->status_is(403, 'a body under another type is not read as a form');
    $t->post_ok('/challenge/verify', env => $A, body => '{"solution":"' . ('x' x 5000) . '"}', type => 'application/json')
      ->status_is(413, 'a body over the ceiling is refused before it is read');
    $t->get_ok('/challenge/verify', env => $A)->status_is(405, 'verify is POST only');
}

done_testing;
