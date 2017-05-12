use strict;
use warnings;
use Test::More;
use DBI;
use Otogiri;
use Otogiri::Plugin;

use Test::Requires 'Test::mysqld';

my $mysqld = Test::mysqld->new(
    my_cnf => {
        'skip-networking' => '',
    }
) or plan skip_all => $Test::mysqld::errstr;

Otogiri->load_plugin('TableInfo');

my $db = Otogiri->new( connect_info => [$mysqld->dsn(dbname => 'test'), '', '', { RaiseError => 1, PrintError => 0 }] );
my $sql = <<'EOF';
CREATE TABLE member (
    id   INTEGER PRIMARY KEY AUTO_INCREMENT,
    name TEXT    NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
EOF

$db->dbh->do($sql);


subtest 'desc and show_create_table', sub {
    my $expected = <<EOSQL;
CREATE TABLE `member` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` text NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8
EOSQL
    $expected =~ s/\n$//; #trim last newline

    my $result_desc = $db->desc('member');
    my $result_show_create_table = $db->show_create_table('member');

    is( $result_desc,              $expected );
    is( $result_show_create_table, $expected );
};

subtest 'show_create_view', sub {

    $db->do('CREATE VIEW member_view AS SELECT id, name FROM member');

    my $result = $db->show_create_view('member_view');
    my $expected = <<EOSQL;
CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `member_view` AS select `member`.`id` AS `id`,`member`.`name` AS `name` from `member`
EOSQL
    $expected =~ s/\n$//; # trim last newline

    is( $result, $expected );
};

subtest 'desc(table does not exist)', sub {
    my $result = $db->desc('hoge');
    is( $result, undef );
};





done_testing;
