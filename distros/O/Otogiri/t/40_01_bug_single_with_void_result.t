use strict;
use warnings;
use Test::More;
use Otogiri;

my $dbfile = ':memory:';
my $db = Otogiri->new(
    connect_info => ["dbi:SQLite:dbname=$dbfile", '', ''],
    inflate => sub {
        my ($row, $table) = @_;
        $row->{table} = $table;
        $row;
    },
    deflate => sub {
        my ($row, $table) = @_;
        delete $row->{table};
        $row;
    },
);

subtest strange_response => sub {
    $db->do(<<'SQL'
CREATE TABLE test (id int, name text)
SQL
    );
    $db->fast_insert(test => {id => 123, name => 'foo'});
    my $row = $db->single(test => {id => 111});
    is $row, undef;
};

done_testing;
