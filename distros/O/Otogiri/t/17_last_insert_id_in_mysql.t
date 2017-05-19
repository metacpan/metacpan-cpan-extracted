use strict;
use warnings;
use Test::More;
use Otogiri;

use Test::Requires 'Test::mysqld';

my $mysql = Test::mysqld->new(
    my_cnf => {
        'skip-networking' => '',
    }
) or plan skip_all => $Test::mysqld::errstr;


my $db = Otogiri->new( connect_info => [$mysql->dsn(dbname => 'test'), '', '', { RaiseError => 1, PrintError => 0 }] );

my $sql_person = <<'EOF';
CREATE TABLE person (
    id   INTEGER       PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(48) NOT NULL,
    age  INTEGER
);
EOF

$db->dbh->do($sql_person);

subtest 'last_insert_id with sequence name', sub {
    $db->fast_insert('person', {
        name => 'Sherlock Shellingford',
        age  => 15,
    });
    $db->fast_insert('person', {
        name => 'Nero Yuzurizaki',
        age  => 15,
    });

    my ($row) = $db->search_by_sql('SELECT MAX(id) AS max_id FROM person');
    my $lastval = $row->{max_id};

    is( $db->last_insert_id, $lastval);
};

done_testing;
