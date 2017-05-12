use strict;
use warnings;
use Test::More;
use Otogiri;

use Test::Requires 'Test::PostgreSQL';

my $pg = Test::PostgreSQL->new(
    my_cnf => {
        'skip-networking' => '',
    }
) or plan skip_all => $Test::PostgreSQL::errstr;


my $db = Otogiri->new( connect_info => [$pg->dsn(dbname => 'test'), '', '', { RaiseError => 1, PrintError => 0 }] );

my $sql_person = <<'EOF';
CREATE TABLE person (
    id   serial       PRIMARY KEY,
    name character(48) NOT NULL,
    age  integer
);
EOF

$db->dbh->do($sql_person);

subtest 'last_insert_id with sequence name', sub {
    my ($row) = $db->search_by_sql('SELECT nextval(?) AS nextval', ['person_id_seq']);
    my $lastval = $row->{nextval};
    $db->fast_insert('person', {
        name => 'Sherlock Shellingford',
        age  => 15,
    });
    is( $db->last_insert_id(undef, undef, undef, undef, { sequence => 'person_id_seq' }), $lastval + 1);
};

subtest 'last_insert_id using LASTVAL()', sub {
    my ($row) = $db->search_by_sql('SELECT nextval(?) AS nextval', ['person_id_seq']);
    my $lastval = $row->{nextval};
    $db->fast_insert('person', {
        name => 'Nero Yuzurizaki',
        age  => 15,
    });
    is( $db->last_insert_id(), $lastval + 1);
};

subtest 'last_insert_id using tablename', sub {
    my ($row) = $db->search_by_sql('SELECT nextval(?) AS nextval', ['person_id_seq']);
    my $lastval = $row->{nextval};
    $db->fast_insert('person', {
        name => 'Hercule Barton',
        age  => 16,
    });
    is( $db->last_insert_id(undef, undef, 'person', undef), $lastval + 1);
};


done_testing;
