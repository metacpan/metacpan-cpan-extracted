use strict;
use warnings;
use Test::More;

use Otogiri;
use Otogiri::Plugin;

use Test::Requires 'Test::mysqld';

my $mysqld = Test::mysqld->new(
    my_cnt => {
        'skip-networking' => '',
    },
) or plan skip_all => $Test::mysqld::errstr;

my $db = Otogiri->new(connect_info => [$mysqld->dsn(dbname => 'test'), '', '']);
$db->load_plugin('BulkInsert');

my $builder = <<'EOSQL';
CREATE TABLE book (
  id     INT(11) PRIMARY KEY AUTO_INCREMENT,
  title  TEXT NOT NULL,
  author TEXT NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
EOSQL
$db->do($builder);

subtest 'bulk insert' => sub {
    my @colnames = qw|title author|;
    my @rowdatas = (
        {title => 'Acmencyclopedia 2009', author => 'Makamaka Hannyaharamitu'},
        {title => 'Acmencyclopedia Reverse', author => 'Makamaka Hannyaharamitu'},
        {title => 'Acmencyclopedia 2010', author => 'Makamaka Hannyaharamitu'},
        {title => 'Acmencyclopedia 2011', author => 'Makamaka Hannyaharamitu'},
        {title => 'Acmencyclopedia 2012', author => 'Makamaka Hannyaharamitu'},
        {title => 'Acmencyclopedia 2013', author => 'Makamaka Hannyaharamitu'},
        {title => 'Miyabi-na-Perl Nyuumon', author => 'Miyabi-na-Rakuda'},
        {title => 'Miyabi-na-Perl Nyuumon 2nd edition', author => 'Miyabi-na-Rakuda'},
    );

    ok($db->bulk_insert(book => [@colnames], [@rowdatas]), 'succeed to bulk insert');

    my @rows = $db->select('book');
    is scalar(@rows), scalar(@rowdatas);
    for my $i (0 .. $#rows) {
        my $row = $rows[$i];
        my $rowdata = $rowdatas[$i];
        for my $colname (@colnames) {
            is $row->{$colname}, $rowdata->{$colname};
        }
    }
};

done_testing;
