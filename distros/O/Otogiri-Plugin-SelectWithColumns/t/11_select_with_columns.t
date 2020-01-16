use strict;
use Test::More;
use Otogiri;
use Otogiri::Plugin;

subtest 'select_with_columns' => sub {
    my $db = _setup();
    _fixture($db, "person", 
        {name => "ytnobody",     age => 39}, 
        {name => "myfinder",     age => 36}, 
        {name => "tsucchi",      age => 40}, 
        {name => "soudai",       age => 35}, 
        {name => "liiu",         age => 26}, 
        {name => "karupanerura", age => 27}, 
    );

    my @rows = $db->select_with_columns(person => ["name"], {age => {">" => 35}}, {order_by => "age DESC"});
    is_deeply [@rows], [{name => "tsucchi"}, {name => "ytnobody"}, {name => "myfinder"}];
    my @rows_search = $db->search_with_columns(person => ["name"], {age => {">" => 35}}, {order_by => "age DESC"});
    is_deeply [@rows], [@rows_search];

};

sub _setup {
    my $dbfile = ':memory:';
    my $db = Otogiri->new(
        connect_info => ["dbi:SQLite:dbname=$dbfile", '', '', {RaiseError => 1, PrintError => 0}],
        strict       => 0,
    );
    $db->load_plugin('SelectWithColumns');

    my @sql = split "\n\n", <<EOSQL;
PRAGMA foreign_keys = ON;

CREATE TABLE person (
    id   INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT    NOT NULL,
    age  INTEGER NOT NULL DEFAULT 30
);
EOSQL

    $db->do($_) for @sql;
    return $db;
}

sub _fixture {
    my ($db, $table, @rows) = @_;
    $db->fast_insert($table, $_) for @rows;
}

done_testing;