use strict;
use warnings;
use Test::More;
use Mock::Quick;
use Otogiri;


my $dbfile  = ':memory:';

my $db = Otogiri->new( connect_info => ["dbi:SQLite:dbname=$dbfile", '', ''] );

my $sql = "
CREATE TABLE person (
  id   INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT    NOT NULL,
  age  INTEGER NOT NULL DEFAULT 20
);";

$db->do($sql);

subtest 'insert with id', sub {
    my $last_insert_id = $db->insert('person', {
        name => 'Sherlock Shellingford',
        age  => 15,
    });
    is $last_insert_id, $db->last_insert_id,
};

subtest 'fast_insert with id', sub {
    my $last_insert_id = $db->insert('person', {
        name => 'Nero Yuzurizaki',
        age  => 15,
    });
    is $last_insert_id, $db->last_insert_id,
};

subtest 'last_insert_id is not called when void context', sub {
    my $last_insert_id_is_called = 0;

    my $guard = qclass(
        -takeover => 'DBIx::Sunny::db',
        last_insert_id => sub { $last_insert_id_is_called = 1 },
    );

    $db->insert('person', {
        name => 'Hercule Barton',
        age  => 16,
    });

    is $last_insert_id_is_called, 0;
};


done_testing;
