#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Punk::Test;
use Punk::Challenge::Token ();
use Punk::Challenge::Solver ();

# The gate through a request: the helpers issue for the request's subject,
# clear onto the response, and see a clearance in the jar, the X-Clearance
# header, or a solution in X-Challenge-Response.

{
    package Gate;
    use Punk;
    use Punk::Plugin::Challenge;

    plugin 'Challenge' => { secret => 'k', bits => 8, ttl => 60 };

    get '/issue'   => sub { $_[0]->text($_[0]->challenge_issue) };
    get '/issue12' => sub { $_[0]->text($_[0]->challenge_issue(bits => 12)) };
    get '/cleared' => sub { $_[0]->text($_[0]->challenge_cleared ? 'yes' : 'no') };
    get '/cleared12' => sub { $_[0]->text($_[0]->challenge_cleared(bits => 12) ? 'yes' : 'no') };
    get '/clear'   => sub { $_[0]->challenge_clear; $_[0]->text('set') };
    get '/clear12' => sub { $_[0]->challenge_clear(bits => 12); $_[0]->text('set') };
}

my %cfg = ( secret => 'k', bits => 8, ttl => 60 );
my $T = Punk::Challenge::Token::;
my $A = { REMOTE_ADDR => '192.0.2.7' };       # one /24
my $B = { REMOTE_ADDR => '192.0.2.200' };     # the same /24
my $C = { REMOTE_ADDR => '198.51.100.7' };    # another

my $t = Punk::Test->new('Gate');

# ---- issue is for the request's subject ---------------------------------------

$t->get_ok('/issue', env => $A)->status_is(200);
my $puzzle = $t->body;
like($puzzle, qr/^v1\.\d+\.8\./, 'a puzzle at the default bits');
my $sol = Punk::Challenge::Solver::solve($puzzle);
is(scalar $T->verify(\%cfg, $T->subject('192.0.2.7'), $sol), 8,
    '  bound to the /24 of the address');
is(scalar $T->verify(\%cfg, $T->subject('198.51.100.7'), $sol), undef,
    '  and not to another');
$t->get_ok('/issue12', env => $A)->content_like(qr/^v1\.\d+\.12\./, 'bits is overridable');

# ---- nothing presented ---------------------------------------------------------------

$t->get_ok('/cleared', env => $A)->content_is('no', 'nothing presented is not cleared');

# ---- the cookie ------------------------------------------------------------------------

$t->get_ok('/clear', env => $A)->status_is(200)
  ->header_like('Set-Cookie', qr/^_clearance=v1\.\d+\.8\.[A-Za-z0-9_-]{22}; /, 'clear sets the cookie')
  ->header_like('Set-Cookie', qr/Path=\//i,        '  Path=/')
  ->header_like('Set-Cookie', qr/Max-Age=60\b/i,   '  Max-Age is the ttl')
  ->header_like('Set-Cookie', qr/HttpOnly/i,       '  HttpOnly')
  ->header_like('Set-Cookie', qr/SameSite=Lax/i,   '  SameSite=Lax');
unlike($t->header('Set-Cookie'), qr/Secure/i, '  not Secure over http');
ok(defined $t->cookie('_clearance'), 'the jar kept it');

$t->get_ok('/cleared', env => $A)->content_is('yes', 'the next request is cleared');
$t->get_ok('/cleared', env => $B)->content_is('yes', '  from anywhere in the /24');
$t->get_ok('/cleared', env => $C)->content_is('no',  '  and not from another /24');
$t->get_ok('/cleared12', env => $A)->content_is('no', '  and not at twelve bits');

$t->get_ok('/clear12', env => $A)->status_is(200);
$t->get_ok('/cleared12', env => $A)->content_is('yes', 'a twelve-bit clearance clears twelve');
$t->get_ok('/cleared', env => $A)->content_is('yes', '  and eight');

{
    my $s = Punk::Test->new('Gate');
    $s->get_ok('/clear', env => { %$A, 'psgi.url_scheme' => 'https' })
      ->header_like('Set-Cookie', qr/Secure/i, 'Secure over https');
}

# ---- the X-Clearance header, with a fresh jar --------------------------------------------

{
    my $h = Punk::Test->new('Gate');
    my $value = $T->clear(\%cfg, $T->subject('192.0.2.7'));
    $h->get_ok('/cleared', env => $A)->content_is('no', 'a fresh jar is not cleared');
    $h->get_ok('/cleared', env => $A, headers => { 'X-Clearance' => $value })
      ->content_is('yes', 'X-Clearance carries a clearance');
    $h->get_ok('/cleared', env => $C, headers => { 'X-Clearance' => $value })
      ->content_is('no', '  bound to its subject');
    $h->get_ok('/cleared', env => $A, headers => { 'X-Clearance' => 'v1.1.8.x' })
      ->content_is('no', '  and garbage is not a clearance');
    ok(!defined $h->cookie('_clearance'), '  and nothing was set in the jar for it');

    # Expiry, without waiting for it: a clearance minted as if an hour ago
    # under a sixty-second ttl has already passed its exp.
    my $old = $T->clear(\%cfg, $T->subject('192.0.2.7'), now => time - 3600);
    $h->get_ok('/cleared', env => $A, headers => { 'X-Clearance' => $old })
      ->content_is('no', 'an expired clearance is no clearance');
    my $fresh = $T->clear(\%cfg, $T->subject('192.0.2.7'), now => time - 30);
    $h->get_ok('/cleared', env => $A, headers => { 'X-Clearance' => $fresh })
      ->content_is('yes', '  and one inside its ttl still clears');
    my $low = $T->clear(\%cfg, $T->subject('192.0.2.7'), bits => 4);
    $h->get_ok('/cleared', env => $A, headers => { 'X-Clearance' => $low })
      ->content_is('no', 'a clearance below the demanded bits is refused');
}

# ---- a solution in X-Challenge-Response ----------------------------------------------------

{
    my $h = Punk::Test->new('Gate');
    $h->get_ok('/cleared', env => $A, headers => { 'X-Challenge-Response' => $sol })
      ->content_is('yes', 'a solution in X-Challenge-Response clears');
    $h->get_ok('/cleared12', env => $A, headers => { 'X-Challenge-Response' => $sol })
      ->content_is('no', '  at its own bits, not more');
    $h->get_ok('/cleared', env => $C, headers => { 'X-Challenge-Response' => $sol })
      ->content_is('no', '  bound to its subject');
    $h->get_ok('/cleared', env => $A, headers => { 'X-Challenge-Response' => $puzzle })
      ->content_is('no', '  an unsolved puzzle does not');
}

# ---- the cookie name follows the option ------------------------------------------------------

{
    package GateNamed;
    use Punk;
    use Punk::Plugin::Challenge;
    plugin 'Challenge' => { secret => 'k', bits => 8, cookie => 'clr' };
    get '/cleared' => sub { $_[0]->text($_[0]->challenge_cleared ? 'yes' : 'no') };
    get '/clear'   => sub { $_[0]->challenge_clear; $_[0]->text('set') };
}
{
    my $n = Punk::Test->new('GateNamed');
    $n->get_ok('/clear', env => $A)->header_like('Set-Cookie', qr/^clr=v1\./, 'a named cookie');
    $n->get_ok('/cleared', env => $A)->content_is('yes', '  is read back by that name');
}

done_testing;
