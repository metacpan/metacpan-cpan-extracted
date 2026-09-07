#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/../../../blib/lib", "$FindBin::Bin/../../../blib/arch";
use Test::More;

# Unpacked from the tarball with nothing installed and nothing built, this
# example has no Punk::Challenge to run against. Say so plainly rather than
# dying with a require error - and say it BEFORE any assertion, or the plan
# and the count disagree.
BEGIN {
    plan skip_all => 'Punk::Challenge is not installed, and there is no blib '
                   . 'beside this example to run it from'
        unless eval { require Punk::Challenge; require Punk::Plugin::Challenge; 1 };

    # The secrets config/punk.yml reads from the environment. Fixed here, so
    # the test can mint its own clearances against the same key.
    $ENV{GATE_CHALLENGE_KEY} = 'the-demo-challenge-key';
    $ENV{GATE_SESSION_KEY}   = 'the-demo-session-key';
    # No Hyperman arena under prove: the `after` rule is inert and the
    # application says so once at startup. Captured below, not silenced.
    $ENV{PUNK_NO_HM_ABI} = 1;
}

use Punk::Test;
use Punk::Challenge::Solver ();

chdir "$FindBin::Bin/.." or die "cannot chdir to the application root: $!\n";

my @warned;
my $t;
{
    local $SIG{__WARN__} = sub { push @warned, $_[0] };
    $t = Punk::Test->new('Gate');
}
is(scalar @warned, 1, 'one startup warning');
like($warned[0], qr/`after` rule for '\/api' is inert/, '  naming the inert after rule');

my $A = { REMOTE_ADDR => '192.0.2.7' };
my $HTML = { Accept => 'text/html' };

# ---- the pages that are free ---------------------------------------------------

$t->get_ok('/', env => $A, headers => $HTML)->status_is(200)
  ->content_like(qr/What this shows/)
  ->content_like(qr{Cleared: <code>0</code>}, 'the home page is free, and not yet cleared');
$t->get_ok('/static/style.css', env => $A)->status_is(200, 'the stylesheet is free');
$t->get_ok('/api/time', env => $A)->status_is(200)
  ->json_is('/cleared', 0, 'the API is free under plackup: the after rule is inert');

# ---- the login form is behind always --------------------------------------------

$t->get_ok('/login', env => $A, headers => $HTML)
  ->status_is(503, 'a browser asking for the form gets the puzzle first')
  ->content_like(qr/One moment/)
  ->content_like(qr{data-verify="/challenge/verify"})
  ->content_like(qr{data-to="/login"});
my ($puzzle) = $t->body =~ /data-puzzle="([^"]+)"/;
like($puzzle, qr/^v1\.\d+\.16\./, '  at sixteen bits');

# What the browser does, done here: solve, post as JSON, keep the cookie.
# (Sixteen bits is a moment even for the solver in Perl's process.)
my $solution = Punk::Challenge::Solver::solve($puzzle);
$t->post_ok('/challenge/verify', env => $A, json => { solution => $solution })
  ->status_is(200, 'the solution verifies')
  ->json_like('/clearance', qr/^v1\./);
ok(defined $t->cookie('_clearance'), '  and the jar holds the clearance');

$t->get_ok('/login', env => $A, headers => $HTML)->status_is(200)
  ->content_like(qr/Your name/, 'with the clearance, the form');
$t->get_ok('/', env => $A, headers => $HTML)
  ->content_like(qr{Cleared: <code>1</code>}, '  and the home page sees it');

# ---- sign in, with csrf on -----------------------------------------------------

$t->post_ok('/login', env => $A, form => { name => 'Sid' }, csrf => 1)
  ->status_is(303)->header_like('Location', qr{/welcome$});
$t->get_ok('/welcome', env => $A, headers => $HTML)->status_is(200)
  ->content_like(qr/Hello, Sid/, 'signed in');
$t->post_ok('/login', env => $A, form => { name => '' }, csrf => 1)
  ->status_is(422, 'an empty name is refused')->content_like(qr/A name, up to forty/);
$t->post_ok('/login', env => $A, form => { name => 'Nancy' })
  ->status_is(403, 'a form without its csrf token is refused by csrf');
$t->post_ok('/logout', env => $A, csrf => 1)->status_is(303);
$t->get_ok('/welcome', env => $A, headers => $HTML)->status_is(303)
  ->header_like('Location', qr{/login$}, 'signed out');

# ---- a program at the form, from a shell --------------------------------------------

{
    my $p = Punk::Test->new('Gate');
    $p->get_ok('/login', env => $A)->status_is(403, 'curl gets the JSON')
      ->json_is('/error', 'challenge')
      ->json_is('/challenge/header', 'X-Challenge-Response');
    my $sol = Punk::Challenge::Solver::solve($p->header('X-Challenge'));
    $p->get_ok('/login', env => $A, headers => { 'X-Challenge-Response' => $sol })
      ->status_is(200, '  and a solution in the header gets the form');
}

done_testing();
