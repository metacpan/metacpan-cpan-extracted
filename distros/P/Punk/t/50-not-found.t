#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use Punk::Test;

# on_not_found: the app's own 404 page, with the on_error contract - a
# reference return becomes the response, declining keeps the C default
# byte-identical, the 405 Allow semantics are untouched, after hooks run
# on the custom page (sessions work), a string target resolves at boot,
# and a die inside the handler goes through on_error.

{
    package NfApp;
    use Punk;
    session secret => 'test-key';

    get  '/here' => sub { $_[0]->text('found') };
    post '/only-post' => sub { $_[0]->text('posted') };

    on_not_found sub {
        my ($c) = @_;
        $c->session->{misses} = ($c->session->{misses} // 0) + 1;
        return $c->html('<h1>lost: ' . $c->req->path . '</h1>', 404);
    };
}

my $t = Punk::Test->new('NfApp');

# ---- the custom page ----------------------------------------------------------

$t->get_ok('/nope')
  ->status_is(404)
  ->header_like('Content-Type' => qr{^text/html})
  ->content_like(qr{<h1>lost: /nope</h1>}, 'the handler rendered the 404');

# ---- matched routes and 405 are untouched -------------------------------------

$t->get_ok('/here')->status_is(200)->content_is('found');

$t->get_ok('/only-post')
  ->status_is(405, 'a known path with the wrong method is still a 405')
  ->header_is(Allow => 'POST', 'with its Allow header')
  ->content_unlike(qr/lost/, 'and never reaches on_not_found');

# ---- after hooks ran: the session survived the 404 ----------------------------

$t->get_ok('/also-nope')->status_is(404);
$t->get_ok('/still-nope')
  ->content_like(qr{still-nope}, 'a third miss');
{
    # the session counted every miss - the write-back after hook ran on
    # the custom 404 responses
    my $c = Punk::Test->new('NfApp');
    $c->get_ok('/a')->get_ok('/b');
    $c->get_ok('/c')->content_like(qr{/c});
    # misses accumulated in the cookie across requests proves writeback
    ok(defined $c->cookie('punk.sid'),
        'the 404 responses set the session cookie');
}

# ---- declining keeps the exact default ----------------------------------------

{
    package DeclineNf;
    use Punk;
    on_not_found sub { return 0 };
    get '/x' => sub { $_[0]->text('x') };
}
{
    my $d = Punk::Test->new('DeclineNf');
    $d->get_ok('/gone')
      ->status_is(404)
      ->header_is('Content-Type' => 'application/json')
      ->content_is('{"errors":[{"message":"Not Found"}]}',
          'a non-reference return keeps the C default byte-identical');
}

# ---- a string target resolves at boot -----------------------------------------

{
    package TgtApp::Controller::Web::Err;
    sub not_found { my ($c) = @_; $c->text('ctrl 404', 404) }

    package TgtApp;
    use Punk;
    on_not_found 'Web::Err#not_found';
    get '/x' => sub { $_[0]->text('x') };
}
{
    my $s = Punk::Test->new('TgtApp');
    $s->get_ok('/gone')->status_is(404)->content_is('ctrl 404',
        'a Controller#method target resolves like any other');
}

# ---- a typo in the target croaks at boot --------------------------------------

{
    package BadTgtApp;
    use Punk;
    on_not_found 'Web::Nope#missing';
    get '/x' => sub { $_[0]->text('x') };
}
{
    my $err = '';
    eval { BadTgtApp->to_app } or $err = $@;
    like($err, qr/on_not_found/, 'an unresolvable target croaks at to_app');
}

# ---- a die inside the handler goes through on_error ---------------------------

{
    package DieNf;
    use Punk;
    on_not_found sub { die "404 page exploded\n" };
    on_error sub { my ($c, $e) = @_; $c->json({ rescued => "$e" }, 599) };
    get '/x' => sub { $_[0]->text('x') };
}
{
    my $d = Punk::Test->new('DieNf');
    $d->get_ok('/gone')
      ->status_is(599)
      ->json_is('/rescued' => "404 page exploded\n",
          'a dying 404 handler lands in on_error');
}

done_testing();
