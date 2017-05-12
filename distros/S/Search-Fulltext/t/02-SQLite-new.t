use strict;
use warnings;
use utf8;
use Test::More;
use Test::Exception;

use Search::Fulltext::SQLite;
use Search::Fulltext::TestSupport;

plan tests => 11;

my @docs = (
    'Beer makes people happy',
    'Wine makes people saticefied',
    'I like beer the best',
    'Buy fruits, beer, and eggs',
);

# Tests if all rows are inserted into memory DB
{
    ok my $sqliteh = Search::Fulltext::SQLite->new({
        docs      => \@docs,
        dbfile    => ':memory:',
        tokenizer => 'simple',
    });
    compare_array_with_column(
        \@docs,
        $sqliteh->{dbh},
        Search::Fulltext::SQLite::TABLE, Search::Fulltext::SQLite::CONTENT_COL,
    );
}

# Tests if all rows are inserted into disk DB
{
    my $dbfile = Search::Fulltext::TestSupport::make_tmp_file;
    ok my $sqliteh = Search::Fulltext::SQLite->new({
        docs      => \@docs,
        dbfile    => $dbfile,
        tokenizer => 'simple',
    });
    compare_array_with_column(
        \@docs,
        $sqliteh->{dbh},
        Search::Fulltext::SQLite::TABLE, Search::Fulltext::SQLite::CONTENT_COL,
    );
}

# Invalid tokenizer throws error
{
    throws_ok {
        Search::Fulltext::SQLite->new({
            docs      => \@docs,
            dbfile    => ':memory:',
            tokenizer => 'invalid_tokenizer',
        })
    }
    qr/unknown tokenizer/, 'unknown tokenizer exception caught';
}

sub compare_array_with_column {
    my ($arr, $dbh, $table, $column) = @_;
    my $rows = $dbh->selectall_arrayref("SELECT $column FROM $table", {Columns=>{}});
    foreach my $i (0..$#{$rows}) {
        is $arr->[$i], $rows->[$i]->{$column};
    }
}
