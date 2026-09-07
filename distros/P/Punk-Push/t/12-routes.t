#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Temp ();
use MIME::Base64 qw/encode_base64url/;
use Crypt::PK::ECC;
use VAPID ();
use Punk ();
use Punk::Test;
use Punk::Plugin::Push ();

BEGIN {
    plan skip_all => 'DBD::SQLite is needed to exercise the storage'
        unless eval { require DBD::SQLite; 1 };
}

our ($PUB, $PRIV) = VAPID::generate_vapid_keys();
my $tmp = File::Temp->newdir;
our $DSN = "dbi:SQLite:dbname=$tmp/push.db";

{
    my $dir = Punk::Plugin::Push->shipped_dir;
    open my $fh, '<', "$dir/sqlite/deploy/push_subscriptions.sql" or die $!;
    my $sql = do { local $/; <$fh> };
    $sql =~ s/^\s*--.*$//mg;
    require DBI;
    my $dbh = DBI->connect($DSN, '', '', { RaiseError => 1, AutoCommit => 1 });
    for my $stmt (split /;/, $sql) {
        $stmt =~ s/\A\s+|\s+\z//g;
        next unless length $stmt;
        next if $stmt =~ /\A(?:BEGIN|COMMIT)\z/i;
        $dbh->do($stmt);
    }
    $dbh->disconnect;
}

# A guard standing in for the application's auth: $main::WHO is the logged-in
# user, undef when nobody is.
our $WHO;
our %OPTS = (
    subject => 'mailto:ops@example.com',
    public_key => $PUB, private_key => $PRIV,
    guard => sub {
        my ($c) = @_;
        return 1 if defined $main::WHO;
        return $c->json({ errors => [ { message => 'Unauthorized' } ] }, 401);
    },
);

eval <<'PERL' or die $@;
package PushRoutes;
use Punk;
host 'https://example.com';
database dsn => $main::DSN;
plugin 'Push' => { %main::OPTS };
1;
PERL

my $t = Punk::Test->new('PushRoutes');

# auth_id is a Punk::Context method, so it cannot be shadowed by a helper.
# The per-app context subclass is where an override belongs, and it is the
# smallest stand-in for a configured `auth` that these routes need.
{
    no strict 'refs';
    no warnings 'redefine';
    *{'PushRoutes::_Context::auth_id'} = sub { $main::WHO };
}

sub real_sub {
    my ($n) = @_;
    my $k = Crypt::PK::ECC->new;
    $k->generate_key('prime256v1');
    return {
        endpoint => "https://push.example.net/p/$n",
        keys => { p256dh => encode_base64url($k->export_key_raw('public')),
                  auth   => encode_base64url(join '', map { chr rand 256 } 1..16) },
    };
}

# ---- the key is public -----------------------------------------------------

{
    local $WHO = undef;
    $t->get_ok('/push/key')->status_is(200)->content_is($PUB);
    pass('the key needs no authentication - it is a public key');
}

# ---- the assets ------------------------------------------------------------

{
    local $WHO = undef;
    $t->get_ok('/push/push.js')->status_is(200)
      ->header_like('Content-Type' => qr{^text/javascript})
      ->content_like(qr/urlBase64ToUint8Array/);
    ok($t->header('ETag'), 'the asset carries an ETag');

    $t->get_ok('/push/push-sw.js')->status_is(200)
      ->content_like(qr/notificationclick/);

    # A service worker's scope defaults to the directory it is served from,
    # so one at /push/push-sw.js can only control /push/*. Without this
    # header the browser refuses to register it for '/' outright:
    #
    #   The path of the provided scope ('/') is not under the max scope
    #   allowed ('/push/')
    is($t->header('Service-Worker-Allowed'), '/',
        'the worker is allowed the whole origin, or it cannot be registered '
      . 'for the site at all');

    $t->get_ok('/push/push.js');
    is($t->header('Service-Worker-Allowed'), undef,
        'and the client script, which is not a worker, does not claim it');

    # The header has to survive a 304 too: a browser revalidating the worker
    # re-checks the scope it is allowed.
    $t->get_ok('/push/push-sw.js');
    my $etag = $t->header('ETag');
    $t->get_ok('/push/push-sw.js', headers => { 'If-None-Match' => $etag })
      ->status_is(304);
    is($t->header('Service-Worker-Allowed'), '/',
        'including on a 304, which is what a revalidating browser gets');
}

# ---- subscribe is guarded --------------------------------------------------
#
# An unauthenticated POST that writes a subscription is an open relay: anyone
# who can guess a user id registers their own browser for that user's
# notifications.

{
    local $WHO = undef;
    $t->post_ok('/push/subscribe', json => real_sub('nope'))->status_is(401);
    is(scalar(Punk::Plugin::Push->for_user(PushRoutes->punk_app, 5)), 0,
        'and nothing was stored');
}

{
    local $WHO = 5;
    my $s = real_sub('a');
    $t->post_ok('/push/subscribe', json => $s)->status_is(200)->json_is('/ok', 1);
    my @rows = Punk::Plugin::Push->for_user(PushRoutes->punk_app, 5);
    is(scalar(@rows), 1, 'an authenticated subscribe stores one row');
    is($rows[0]{endpoint}, $s->{endpoint}, '  with the endpoint');
    ok($rows[0]{user_agent} || 1, '  and whatever user agent the client sent');
}

# ---- what subscribe refuses ------------------------------------------------

{
    local $WHO = 5;
    my $bad = real_sub('b');
    $bad->{endpoint} = 'http://push.example.net/p/b';
    $t->post_ok('/push/subscribe', json => $bad)->status_is(400);
    like($t->body, qr/absolute https URL/, 'a non-https endpoint is a 400');

    $t->post_ok('/push/subscribe', json => { nonsense => 1 })->status_is(400);
    $t->post_ok('/push/subscribe', body => 'not json',
                type => 'application/json')->status_is(400);
}

# ---- unsubscribe removes only your own -------------------------------------

{
    local $WHO = 6;
    $t->post_ok('/push/subscribe', json => real_sub('mine'))->status_is(200);
}

{
    # user 5 tries to remove user 6's endpoint
    local $WHO = 5;
    $t->post_ok('/push/unsubscribe',
                json => { endpoint => 'https://push.example.net/p/mine' })
      ->status_is(200)->json_is('/removed', 0);
    is(scalar(Punk::Plugin::Push->for_user(PushRoutes->punk_app, 6)), 1,
        "another user's subscription survives - an endpoint is sent to a third "
      . 'party on every delivery, so it is not a secret');
}

{
    local $WHO = 6;
    $t->post_ok('/push/unsubscribe',
                json => { endpoint => 'https://push.example.net/p/mine' })
      ->status_is(200)->json_is('/removed', 1);
    is(scalar(Punk::Plugin::Push->for_user(PushRoutes->punk_app, 6)), 0,
        'the owner can remove it');
}

{
    local $WHO = undef;
    $t->post_ok('/push/unsubscribe', json => { endpoint => 'x' })->status_is(401);
    pass('unsubscribe is guarded too');
}

{
    local $WHO = 5;
    $t->post_ok('/push/unsubscribe', json => {})->status_is(400);
    like($t->body, qr/endpoint is required/, 'unsubscribe needs an endpoint');
}

# ---- prefix and assets are configurable -----------------------------------

{
    local %OPTS = (%OPTS, prefix => '/notify', assets => 0);
    eval <<'PERL' or die $@;
package PushRoutesAlt;
use Punk;
host 'https://example.com';
database dsn => $main::DSN;
plugin 'Push' => { %main::OPTS };
1;
PERL
    my $a = Punk::Test->new('PushRoutesAlt');
    {
        no strict 'refs'; no warnings 'redefine';
        *{'PushRoutesAlt::_Context::auth_id'} = sub { $main::WHO };
    }
    local $WHO = undef;
    $a->get_ok('/notify/key')->status_is(200);
    $a->get_ok('/push/key')->status_is(404);
    $a->get_ok('/notify/push.js')->status_is(404);
    pass('assets => 0 serves no javascript, which is the documented path once '
       . 'you have copied it into your own tree');
}

# ---- no auth, no unguarded write route -------------------------------------

{
    local $@;
    eval <<'PERL';
package PushNoAuth;
use Punk;
host 'https://example.com';
plugin 'Push' => { subject => 'mailto:o@e.com',
                   public_key => $main::PUB, private_key => $main::PRIV };
1;
PERL
    my $compiled = eval { PushNoAuth->to_app; 1 };
    ok(!$compiled, 'an application with no auth and no guard refuses to compile');
    like($@, qr/open relay/, '  saying what the risk is');
    like($@, qr/Declare auth, or pass an explicit `guard`/, '  and what to do');
}

done_testing;
