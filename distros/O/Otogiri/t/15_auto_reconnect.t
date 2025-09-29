use strict;
use warnings;
use Test::More;
use Mock::Quick;
use Otogiri;
use File::Temp qw(tempfile);

my ($fh, $dbfile)  = tempfile('db_XXXXX', UNLINK => 1, EXLOCK => 0);

my $db = Otogiri->new( connect_info => ["dbi:SQLite:dbname=$dbfile", '', ''] );

my $sql = "
CREATE TABLE person (
  id   INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT    NOT NULL,
  age  INTEGER NOT NULL DEFAULT 20
);";

$db->do($sql);

$db->fast_insert('person', {
    name => 'Sherlock Shellingford',
    age  => 15,
});
my $person_id = $db->last_insert_id();


subtest 'reconnect', sub {
    $db->disconnect();
    $db->reconnect();
    my $row = $db->single('person', { id => $person_id });
    ok( defined $row );
};

subtest 'auto reconnect', sub {
    $db->disconnect();
    #$db->reconnect();
    my $row = $db->single('person', { id => $person_id });
    ok( defined $row );
};

subtest 'in transaction', sub {
    my $txn = $db->txn_scope();
    my $row = $db->single('person', { id => $person_id });

    my $guard = qclass(
        -takeover => 'DBIx::Sunny::db',
        ping => sub { 0 },
    );

    eval {
        $db->insert('person', {
            name => 'Nero Yuzurizaki',
            age  => 15,
        });
    };
    like( $@, qr/^Detected transaction/ );
    $txn->rollback();
};



done_testing;
