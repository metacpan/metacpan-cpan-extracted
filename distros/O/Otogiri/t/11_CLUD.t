use strict;
use warnings;
use Test::More;
use Otogiri;

my $dbfile  = ':memory:';

my $db = Otogiri->new( connect_info => ["dbi:SQLite:dbname=$dbfile", '', ''] );
isa_ok $db, 'DBIx::Otogiri';
can_ok $db, qw/insert fast_insert select single search_by_sql delete update txn_scope dbh maker do/;
is $db->maker->strict, 1;

my $sql = <<'EOF';
CREATE TABLE member (
    id         INTEGER PRIMARY KEY AUTOINCREMENT,
    name       TEXT    NOT NULL,
    age        INTEGER NOT NULL DEFAULT 20,
    sex        TEXT    NOT NULL,
    created_at INTEGER NOT NULL,
    updated_at INTEGER
);
EOF
$db->do($sql);

subtest insert => sub {
    my $time = time;
    my $param = {
        name       => 'ytnobody', 
        age        => 30,
        sex        => 'male',
        created_at => $time,
    };
    
    $db->insert(member => $param);

    my $member_id = $db->last_insert_id;
    is $member_id, 1;

    my $member = $db->single(member => {id => $member_id});
    isa_ok $member, 'HASH';

    for my $key (keys %$param) {
        is $member->{$key}, $param->{$key}, "$key is ". $param->{$key};
    }
};

subtest transaction_and_update => sub {
    do {
        my $txn = $db->txn_scope;
        $db->insert(member => {name => 'oreore', sex => 'male', created_at => time});
        $db->update(member => [name => 'tonkichi', updated_at => time], {name => 'oreore'});
        $txn->commit;
    };
    
    my $oreore = $db->single(member => {name => 'tonkichi'});
    isa_ok $oreore, 'HASH';
    is $oreore->{name}, 'tonkichi';
    ok $oreore->{updated_at};
};

subtest rollback => sub {
    do {
        my $txn = $db->txn_scope;
        $db->update(member => [name => 'tonny', updated_at => time], {name => 'tonkichi'});
        $txn->rollback;
    };

    my $oreore = $db->single(member => {name => 'tonny'});
    is $oreore, undef;
    $oreore = $db->single(member => {name => 'tonkichi'});
    isa_ok $oreore, 'HASH';
    is $oreore->{name}, 'tonkichi';
};

subtest fast_insert_and_search_by_sql => sub {
    $db->fast_insert(member => {name => 'airwife', sex => 'female', created_at => time});
    my @rows = $db->search_by_sql('SELECT * FROM member WHERE sex=? ORDER BY id', ['male']);
    is scalar(@rows), 2;
    is $rows[0]->{name}, 'ytnobody';
    is $rows[0]->{sex}, 'male';

    @rows = $db->search_by_sql('SELECT * FROM member WHERE sex=?', ['female']);
    is scalar(@rows), 1;
    is $rows[0]->{name}, 'airwife';
    is $rows[0]->{sex}, 'female';
};

subtest select => sub {
    my @rows = $db->select(member => {sex => 'male'});
    is scalar(@rows), 2;
    is $rows[0]->{name}, 'ytnobody';
    is $rows[0]->{sex}, 'male';
    @rows = $db->select(member => {sex => 'female'});
    is scalar(@rows), 1;
    is $rows[0]->{name}, 'airwife';
    is $rows[0]->{sex}, 'female';
};

subtest iterator => sub {
    my @rows = $db->select(member => {sex => 'male'});
    my $iter = $db->select(member => {sex => 'male'});

    isa_ok $iter, 'DBIx::Otogiri::Iterator';
    can_ok $iter, qw|next fetched_count|;

    while (my $row = $iter->next) {
        isa_ok $row, 'HASH';
        my $index = $iter->fetched_count - 1;
        is_deeply($row, $rows[$index]);
    }
    is $iter->fetched_count, 2;
};

subtest range_search => sub {
    my @rows = $db->search(member => sql_and([
        sql_ge(age => 25), 
        sql_eq(sex => 'male'),
    ]));
    is scalar(@rows), 1;
    is $rows[0]->{name}, 'ytnobody';
};

subtest no_strict_range_search => sub {
    my $db_nost = Otogiri->new( connect_info => ["dbi:SQLite:dbname=$dbfile", '', ''], strict => 0);
    is $db_nost->maker->strict, 0;

    { ### create dummy data for testing ...
        $db_nost->do($sql);
        my $param = {
            name       => 'ytnobody', 
            age        => 30,
            sex        => 'male',
            created_at => time,
        };
        $db_nost->insert(member => $param);
        do {
            my $txn = $db->txn_scope;
            $db_nost->insert(member => {name => 'oreore', sex => 'male', created_at => time});
            $db_nost->update(member => [name => 'tonkichi', updated_at => time], {name => 'oreore'});
            $txn->commit;
        };
    }

    my @rows = $db_nost->search(member => {
        age => { '>=' => 25 }, 
        sex => 'male',
    });
    is scalar(@rows), 1;
    is $rows[0]->{name}, 'ytnobody';
};

subtest delete => sub {
    my $tonkichi = $db->single(member => {name => 'tonkichi'});
    $db->delete(member => {name => 'tonkichi'});
    my $row = $db->single(member => {id => $tonkichi->{id}});
    is $row, undef;
};


done_testing;
