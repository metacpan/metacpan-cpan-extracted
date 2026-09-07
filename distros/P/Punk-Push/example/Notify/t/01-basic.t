#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/../lib", "$FindBin::Bin/../../../blib/lib";
use Test::More;

BEGIN {
    plan skip_all => 'Punk::Push is not installed, and there is no blib '
                   . 'beside this example to run it from'
        unless eval { require Punk::Push; require Punk::Plugin::Push; 1 };
    plan skip_all => 'DBD::SQLite is needed' unless eval { require DBD::SQLite; 1 };
}

use Punk::Test;

chdir "$FindBin::Bin/.." or die "cannot chdir to the application root: $!\n";

plan skip_all => 'run bin/seed.pl first - it makes var/notify.db and the keys'
    unless -f 'var/notify.db' && -f 'var/vapid.env';

# The demo reads its keypair from the environment, as a deployment would.
{
    open my $fh, '<', 'var/vapid.env' or die $!;
    while (<$fh>) { chomp; my ($k, $v) = split /=/, $_, 2; $ENV{$k} = $v }
}

my $t = Punk::Test->new('Notify');

# ---- signed out ------------------------------------------------------------

$t->get_ok('/')->status_is(200)
  ->content_like(qr/You need to be signed in/);

$t->get_ok('/push/key')->status_is(200)->content_is($ENV{VAPID_PUBLIC});
pass('the public key is served without signing in - it is a public key');

$t->get_ok('/push/push.js')->status_is(200)
  ->content_like(qr/urlBase64ToUint8Array/);

# A subscription belongs to a user, so writing one needs an identity.
$t->post_ok('/push/subscribe', json => { endpoint => 'https://p.example/x' })
  ->status_is(401);

# ---- signed in -------------------------------------------------------------

$t->post_ok('/login', form => { email => 'demo@example.com', password => 'demo' })
  ->status_is(302);

$t->get_ok('/')->status_is(200)
  ->content_like(qr/Enable notifications/)
  ->content_like(qr/Send to every device/);

# The form carries the whole surface: what a payload may hold, and what a
# single send may override. Checked here rather than by sending, because a
# test suite must not fire real notifications at a real push service.
{
    my $body = $t->body;
    for my $field (qw(title body url icon badge tag ttl topic)) {
        like($body, qr/name="\Q$field\E"/, "the form offers $field");
    }
    like($body, qr/<select name="urgency"/, 'and urgency as a select');
    for my $u (qw(very-low low normal high)) {
        like($body, qr/<option value="\Q$u\E"/, "  with $u");
    }
    like($body, qr/<option value="normal" selected/,
        '  defaulting to normal, which is the only one not sent as a header');
}

# The form offers /static/icon.png and /static/badge.png as values, so they
# have to exist - a default that 404s is worse than an empty field.
for my $asset (qw(icon.png badge.png)) {
    $t->get_ok("/static/$asset")->status_is(200)
      ->header_like('Content-Type' => qr{^image/png});
}

# The model this application declared is the plugin's, inherited.
is(Punk::Plugin::Push->config_for(Notify->punk_app)->{model},
   'PushSubscription',
   'the application named its own model, so the plugin used it');

{
    my $m = Punk::Model::_punk_model_meta('Notify::Model::PushSubscription');
    ok($m, 'and that model has metadata');
    is($m->{table}, 'push_subscriptions',
        '  inherited from Punk::Model::PushSubscription, not restated');
    is(scalar @{ $m->{fields} }, 9, '  with every inherited column');
}

# ---- a bad subscription is refused ----------------------------------------

$t->post_ok('/push/subscribe', json => {
    endpoint => 'http://p.example/x',        # not https
    keys => { p256dh => 'x', auth => 'y' },
})->status_is(400);

$t->post_ok('/logout')->status_is(302);
$t->get_ok('/')->content_like(qr/You need to be signed in/);

done_testing();
