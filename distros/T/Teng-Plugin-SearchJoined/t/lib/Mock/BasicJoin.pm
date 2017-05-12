package Mock::BasicJoin;
use strict;
use warnings;
use parent qw(TengTest);
use Mock::BasicJoin::Schema;

sub create_sqlite {
    my ($class, $dbh) = @_;
    $dbh->do(q{
        CREATE TABLE user (
            id   integer,
            name text,
            primary key ( id )
        )
    });
    $dbh->do(q{
        CREATE TABLE user_item (
            id      integer PRIMARY KEY AUTOINCREMENT,
            user_id integer,
            item_id integer,
            UNIQUE (user_id, item_id)
        )
    });

    $dbh->do(q{
        CREATE TABLE item (
            id   integer,
            name text,
            primary key ( id )
        )
    });
}

1;
