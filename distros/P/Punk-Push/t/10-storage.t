#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Temp ();
use MIME::Base64 qw/encode_base64url/;
use VAPID ();
use Punk ();
use Punk::Plugin::Push ();

BEGIN {
    plan skip_all => 'DBD::SQLite is needed to exercise the storage'
        unless eval { require DBD::SQLite; 1 };
}

my ($PUB, $PRIV) = VAPID::generate_vapid_keys();

my $tmp = File::Temp->newdir;
my $db  = "$tmp/push.db";

# The table, from the shipped SQLite change - so the test deploys the DDL this
# distribution actually ships rather than a copy of it that could drift.
{
    my $sql = do {
        my $dir = Punk::Plugin::Push->shipped_dir
            or plan skip_all => 'the shipped sqitch project is not beside the module';
        open my $fh, '<', "$dir/sqlite/deploy/push_subscriptions.sql"
            or plan skip_all => "cannot read the shipped DDL: $!";
        local $/; <$fh>;
    };
    require DBI;
    my $dbh = DBI->connect("dbi:SQLite:dbname=$db", '', '',
                           { RaiseError => 1, AutoCommit => 1 });
    $sql =~ s/^\s*--.*$//mg;               # comments first, or they hide the ;
    for my $stmt (split /;/, $sql) {
        $stmt =~ s/\A\s+|\s+\z//g;
        next unless length $stmt;
        next if $stmt =~ /\A(?:BEGIN|COMMIT)\z/i;   # AutoCommit owns those
        $dbh->do($stmt);
    }
    $dbh->disconnect;
}

our $DSN = "dbi:SQLite:dbname=$db";
our %OPTS = (subject => 'mailto:ops@example.com',
             public_key => $PUB, private_key => $PRIV,
             guard => sub { 1 });

eval <<'PERL' or die $@;
package PushStore;
use Punk;
host 'https://example.com';
database dsn => $main::DSN;
plugin 'Push' => { %main::OPTS };
1;
PERL

my $app = PushStore->punk_app;
PushStore->to_app;

sub sub_for {
    my ($n) = @_;
    return {
        endpoint => "https://push.example.net/p/$n",
        keys     => { p256dh => encode_base64url("\x04" . ('k' x 64)),
                      auth   => encode_base64url('a' x 16) },
    };
}

# ---- storing ---------------------------------------------------------------

{
    ok(Punk::Plugin::Push->store($app, 7, sub_for('a'), 'Firefox/1'),
        'a subscription stores');
    my @rows = Punk::Plugin::Push->for_user($app, 7);
    is(scalar(@rows), 1, 'and comes back for its user');
    is($rows[0]{endpoint}, 'https://push.example.net/p/a', 'with its endpoint');
    is($rows[0]{user_agent}, 'Firefox/1', 'and its user agent');
    ok($rows[0]{created_at}, 'and a created_at');
}

# ---- re-subscribing updates rather than duplicating ------------------------
#
# A browser re-subscribing produces the same endpoint. Without the upsert every
# re-subscribe adds a row and one send fans out across duplicates.

{
    my $again = sub_for('a');
    $again->{keys}{p256dh} = encode_base64url("\x04" . ('m' x 64));
    Punk::Plugin::Push->store($app, 7, $again, 'Firefox/2');

    my @rows = Punk::Plugin::Push->for_user($app, 7);
    is(scalar(@rows), 1, 're-subscribing the same endpoint does not add a row');
    is($rows[0]{p256dh}, $again->{keys}{p256dh}, '  the keys are refreshed');
    is($rows[0]{user_agent}, 'Firefox/2',        '  and the user agent');
}

# ---- several devices -------------------------------------------------------

{
    Punk::Plugin::Push->store($app, 7, sub_for('b'), 'Chrome/1');
    my @rows = Punk::Plugin::Push->for_user($app, 7);
    is(scalar(@rows), 2, 'a second device is a second subscription');
}

{
    Punk::Plugin::Push->store($app, 9, sub_for('c'), 'Safari/1');
    is(scalar(Punk::Plugin::Push->for_user($app, 9)), 1, 'another user has their own');
    is(scalar(Punk::Plugin::Push->for_user($app, 7)), 2, '  without touching the first');
    is(scalar(Punk::Plugin::Push->for_user($app, 99)), 0, 'a user with none gets none');
}

# ---- unsubscribing deletes only your own -----------------------------------
#
# Deleting by endpoint alone would let any authenticated user unsubscribe any
# other, given an endpoint - which is sent to a third party on every delivery.

{
    is(Punk::Plugin::Push->forget($app, 9, 'https://push.example.net/p/a'), 0,
        "user 9 cannot unsubscribe user 7's endpoint");
    is(scalar(Punk::Plugin::Push->for_user($app, 7)), 2, '  and it survives');

    is(Punk::Plugin::Push->forget($app, 7, 'https://push.example.net/p/a'), 1,
        'the owner can');
    is(scalar(Punk::Plugin::Push->for_user($app, 7)), 1, '  and it is gone');

    is(Punk::Plugin::Push->forget($app, 7, 'https://push.example.net/p/nope'), 0,
        'forgetting an endpoint that is not there is not an error');
}

# ---- pruning is what the push service tells you ----------------------------
#
# No user check: the push service is authoritative about its own endpoints.

{
    is(Punk::Plugin::Push->prune($app, 'https://push.example.net/p/c'), 1,
        'a gone subscription prunes');
    is(scalar(Punk::Plugin::Push->for_user($app, 9)), 0, '  and is gone');
    is(Punk::Plugin::Push->prune($app, 'https://push.example.net/p/c'), 0,
        'pruning it twice is not an error');
}

# ---- touch records what the service said -----------------------------------

{
    is(Punk::Plugin::Push->touch($app, 'https://push.example.net/p/b', 201), 1,
        'a delivery records its status');
    my @rows = Punk::Plugin::Push->for_user($app, 7);
    is($rows[0]{last_status}, 201, '  on the row');
    ok($rows[0]{last_seen_at}, '  with a last_seen_at');
}

# ---- what store refuses ----------------------------------------------------

{
    local $@;
    eval { Punk::Plugin::Push->store($app, undef, sub_for('d')) };
    like($@, qr/needs a user/, 'a subscription with no user is refused');
}

{
    local $@;
    my $bad = sub_for('e');
    $bad->{endpoint} = 'http://push.example.net/p/e';
    eval { Punk::Plugin::Push->store($app, 7, $bad) };
    like($@, qr/absolute https URL/, 'and one whose endpoint is not https');
    is(scalar(Punk::Plugin::Push->for_user($app, 7)), 1, '  nothing was stored');
}

# ---- the shipped Sqitch project --------------------------------------------

{
    my $dir = Punk::Plugin::Push->shipped_dir;
    ok($dir, 'the shipped project is found beside the module, through %INC');
    ok(-f "$dir/sqitch.plan", '  with a plan');
    for my $engine (qw(pg sqlite mysql)) {
        ok(-f "$dir/$engine/deploy/push_subscriptions.sql", "  $engine deploy");
        ok(-f "$dir/$engine/revert/push_subscriptions.sql", "  $engine revert");
        ok(-f "$dir/$engine/verify/push_subscriptions.sql", "  $engine verify");
    }
}

# sqitch => 1 needs Punk::Sqitch, and says so rather than failing later.
SKIP: {
    skip 'Punk::Sqitch is installed here, so the refusal cannot be observed', 1
        if eval { require Punk::Plugin::Sqitch; 1 };
    local $@;
    eval { Punk::Plugin::Push::_sqitch({}, { sqitch => 1 }) };
    like($@, qr/needs Punk::Sqitch installed/, 'sqitch => 1 without it croaks');
}

done_testing;
