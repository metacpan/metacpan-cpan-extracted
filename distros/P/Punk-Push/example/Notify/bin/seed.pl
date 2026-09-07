#!/usr/bin/env perl
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/../lib", "$FindBin::Bin/../../../blib/lib";
use DBI;
use VAPID qw(generate_vapid_keys);

# Everything the demo needs before it will run: a database, one user to sign in
# as, and a VAPID keypair.
#
# The keypair is written to var/vapid.env rather than generated at boot,
# because a key minted per process would differ per worker and per restart and
# every subscription made against the old one would be undeliverable.

chdir "$FindBin::Bin/.." or die "cannot chdir: $!\n";
mkdir 'var' unless -d 'var';

my $dbh = DBI->connect('dbi:SQLite:dbname=var/notify.db', '', '',
                       { RaiseError => 1, AutoCommit => 1 });

$dbh->do(q{
    CREATE TABLE IF NOT EXISTS users (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        email         TEXT NOT NULL,
        password_hash TEXT,
        verified      INTEGER NOT NULL DEFAULT 0
    )});
$dbh->do('CREATE UNIQUE INDEX IF NOT EXISTS users_email ON users (lower(email))');

$dbh->do(q{
    CREATE TABLE IF NOT EXISTS push_subscriptions (
        id           INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id      INTEGER NOT NULL,
        endpoint     TEXT    NOT NULL,
        p256dh       TEXT    NOT NULL,
        auth         TEXT    NOT NULL,
        user_agent   TEXT,
        created_at   INTEGER NOT NULL,
        last_seen_at INTEGER,
        last_status  INTEGER
    )});
$dbh->do('CREATE UNIQUE INDEX IF NOT EXISTS push_subscriptions_endpoint
          ON push_subscriptions (endpoint)');
$dbh->do('CREATE INDEX IF NOT EXISTS push_subscriptions_user
          ON push_subscriptions (user_id)');

# One user: demo@example.com / demo. Punk::Auth hashes with PBKDF2 in C.
my ($n) = $dbh->selectrow_array('SELECT COUNT(*) FROM users');
if (!$n) {
    require Punk::Auth::Password;
    my $hash = Punk::Auth::Password::hash('demo');
    $dbh->do('INSERT INTO users (email, password_hash, verified) VALUES (?,?,1)',
             undef, 'demo@example.com', $hash);
    print "user:  demo\@example.com / demo\n";
}
$dbh->disconnect;

if (!-f 'var/vapid.env') {
    my ($pub, $priv) = generate_vapid_keys();
    open my $fh, '>', 'var/vapid.env' or die $!;
    print {$fh} "VAPID_PUBLIC=$pub\nVAPID_PRIVATE=$priv\n";
    close $fh;
    print "keys:  var/vapid.env\n";
}

print "ready. now:\n\n    set -a; . var/vapid.env; set +a\n    plackup app.psgi\n";
