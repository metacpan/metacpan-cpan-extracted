#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Punk::Test;
use Punk::Challenge::Token ();
use Punk::Challenge::Solver ();

# The subject follows REMOTE_ADDR, which `proxy` overwrites with the real
# client at the top of the dispatcher - so the plugin reads REMOTE_ADDR and
# nothing here has to know about forwarded headers. And the shared-subject
# case without it: every client on the internet is the proxy, one visitor's
# clearance is valid for everybody, and the plugin is worse than none
# because the operator believes it is working.

BEGIN { $ENV{PUNK_NO_HM_ABI} = 1 }

{
    package Proxied;
    use Punk;
    use Punk::Plugin::Challenge;
    proxy;
    plugin 'Challenge' => { secret => 'k', bits => 8 };
    challenge for => '/x', always => 1;
    challenge for => '/counted', after => { limit => 1, window => 60 }, tag => 'c';
    get '/x' => sub { $_[0]->text('x') };
    get '/counted' => sub { $_[0]->text('counted') };
    get '/whoami' => sub { $_[0]->text($_[0]->req->address) };
}

{
    package Bare;
    use Punk;
    use Punk::Plugin::Challenge;
    plugin 'Challenge' => { secret => 'k', bits => 8 };
    challenge for => '/x', always => 1;
    get '/x' => sub { $_[0]->text('x') };
}

my $T = Punk::Challenge::Token::;
my %cfg = ( secret => 'k', bits => 8 );
my $PROXY = { REMOTE_ADDR => '10.0.0.1' };
my $ALICE = { 'X-Forwarded-For' => '192.0.2.7' };
my $BOB   = { 'X-Forwarded-For' => '198.51.100.7' };

# ---- under proxy: the subject is the forwarded client -------------------------------

{
    my $t = Punk::Test->new('Proxied');
    local $SIG{__WARN__} = sub { };    # the after-rule boot warning, not this test's subject
    $t->get_ok('/whoami', env => $PROXY, headers => $ALICE)->content_is('192.0.2.7',
        'proxy resolved the client');

    $t->get_ok('/x', env => $PROXY, headers => $ALICE)->status_is(403);
    my $puzzle = $t->header('X-Challenge');
    my $sol = Punk::Challenge::Solver::solve($puzzle);
    is(scalar $T->verify(\%cfg, $T->subject('192.0.2.7'), $sol), 8,
        "the puzzle is bound to the client's /24");
    is(scalar $T->verify(\%cfg, $T->subject('10.0.0.1'), $sol), undef,
        "  and not to the proxy's");

    my $alice = $T->clear(\%cfg, $T->subject('192.0.2.7'));
    $t->get_ok('/x', env => $PROXY, headers => { %$ALICE, 'X-Clearance' => $alice })
      ->status_is(200)->content_is('x', "Alice's clearance clears Alice");
    $t->get_ok('/x', env => $PROXY, headers => { %$BOB, 'X-Clearance' => $alice })
      ->status_is(403, '  and not Bob, behind the same proxy');
    my $bob = $T->clear(\%cfg, $T->subject('198.51.100.7'));
    $t->get_ok('/x', env => $PROXY, headers => { %$BOB, 'X-Clearance' => $bob })
      ->status_is(200)->content_is('x', "  Bob's clears Bob");

    # a client that writes its own X-Forwarded-For does not choose its subject:
    # with one proxy trusted, the client is the rightmost entry
    $t->get_ok('/x', env => $PROXY, headers => { 'X-Forwarded-For' => '192.0.2.7, 198.51.100.7',
                                                  'X-Clearance' => $alice })
      ->status_is(403, 'a spoofed leftmost entry does not borrow a clearance');
}

# ---- the after counter is keyed by the client too -------------------------------------

{
    my @keys;
    no warnings 'redefine';
    local *Punk::Context::rate_hit = sub { push @keys, $_[1]; return (1, 0, time + 60) };
    my $t = Punk::Test->new('Proxied');
    local $SIG{__WARN__} = sub { };
    $t->get_ok('/counted', env => $PROXY, headers => $ALICE)->status_is(200);
    $t->get_ok('/counted', env => $PROXY, headers => $BOB)->status_is(200);
    is_deeply(\@keys, [ 'challenge:c:192.0.2.0/24', 'challenge:c:198.51.100.0/24' ],
        'under proxy, two clients behind one proxy are two counters');
}

# ---- without proxy: one subject for the whole internet ----------------------------------

{
    my $t = Punk::Test->new('Bare');
    $t->get_ok('/x', env => $PROXY, headers => $ALICE)->status_is(403);
    my $sol = Punk::Challenge::Solver::solve($t->header('X-Challenge'));
    is(scalar $T->verify(\%cfg, $T->subject('10.0.0.1'), $sol), 8,
        "without proxy, the puzzle is bound to the proxy's /24");

    my $proxy_clr = $T->clear(\%cfg, $T->subject('10.0.0.1'));
    $t->get_ok('/x', env => $PROXY, headers => { %$ALICE, 'X-Clearance' => $proxy_clr })
      ->status_is(200, "  so one visitor's clearance clears Alice");
    $t->get_ok('/x', env => $PROXY, headers => { %$BOB, 'X-Clearance' => $proxy_clr })
      ->status_is(200, '  and Bob');
    $t->get_ok('/x', env => $PROXY, headers => { 'X-Forwarded-For' => '203.0.113.9', 'X-Clearance' => $proxy_clr })
      ->status_is(200, '  and everybody else: the shared-subject case the POD warns about');
}

done_testing;
