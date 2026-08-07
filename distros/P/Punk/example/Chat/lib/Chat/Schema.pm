package Chat::Schema;

use strict;
use warnings;
use DBI ();

# The one table the example needs, created on demand so the app runs from a
# fresh checkout with nothing to set up first. A real application would keep
# migrations somewhere less casual than this.

my $DDL = <<'SQL';
CREATE TABLE IF NOT EXISTS messages (
    id      INTEGER PRIMARY KEY AUTOINCREMENT,
    room    TEXT NOT NULL,
    nick    TEXT NOT NULL,
    body    TEXT NOT NULL,
    created TEXT NOT NULL
)
SQL

my $INDEX = 'CREATE INDEX IF NOT EXISTS messages_room_id
               ON messages (room, id)';

sub dsn {
    return $ENV{PUNK_CHAT_DSN} if $ENV{PUNK_CHAT_DSN};
    require File::Basename;
    my $home = File::Basename::dirname(__FILE__) . '/../..';
    return "dbi:SQLite:dbname=$home/chat.db";
}

sub ensure {
    my ($dsn) = @_;
    $dsn ||= dsn();
    my $dbh = DBI->connect($dsn, undef, undef,
        { RaiseError => 1, AutoCommit => 1, PrintError => 0 });
    $dbh->do($DDL);
    $dbh->do($INDEX);
    $dbh->disconnect;
    return $dsn;
}

1;
