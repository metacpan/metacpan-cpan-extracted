use strict;
use warnings;
use Test::More;
use Test::Time;
use Otogiri;
use Otogiri::Plugin;
Otogiri->load_plugin('InsertAndFetch');

my $dbfile  = ':memory:';

my $db = Otogiri->new(
    connect_info => ["dbi:SQLite:dbname=$dbfile", '', ''],
    deflate => sub {
        my ($row, $table) = @_;
        $row->{created_at} ||= time;
        $row;
    },
);
isa_ok $db, 'DBIx::Otogiri';
can_ok $db, qw/insert fast_insert select single search_by_sql delete update txn_scope dbh maker do/;

my $sql = <<'EOF';
CREATE TABLE member (
    id         INTEGER PRIMARY KEY AUTOINCREMENT,
    name       TEXT    NOT NULL,
    age        INTEGER NOT NULL DEFAULT 20,
    sex        TEXT    NOT NULL,
    created_at INTEGER NOT NULL
);
EOF
$db->do($sql);

subtest insert_and_fetch => sub {
    my $now = time;
    my $param = {
        name       => 'ytnobody', 
        age        => 33,
        sex        => 'male',
    };

    sleep 5;
    my $member = $db->insert_and_fetch(member => $param);
    
    isa_ok $member, 'HASH';
    for my $key (keys %$param) {
        is $member->{$key}, $param->{$key}, "$key is ". $param->{$key};
    }
    is $member->{id}, $db->last_insert_id();
    is $member->{created_at} - $now, 5;
};

done_testing;
