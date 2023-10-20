use strict;
use warnings;
use Test::More;
use Otogiri;
BEGIN {
    plan skip_all => "Test requires Perl 5.38 or higher" if $] < 5.038;
}

use v5.38;
use feature 'class';
no warnings 'experimental::class';

my $dbfile  = ':memory:';

my $db = Otogiri->new( connect_info => ["dbi:SQLite:dbname=$dbfile", '', ''] );
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

class Member {
    field $id :param;
    field $name :param;
    field $age :param;
    field $sex :param;
    field $created_at :param;
    field $updated_at :param;

    method name {
        return $name;
    }
};

subtest single_with_row_class => sub {
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
    {
        my $member = $db->row_class('Member')->single(member => {id => $member_id});
        isa_ok $member, 'Member';
        is $member->name, 'ytnobody';
    }
    {
        my $member = $db->no_row_class->single(member => {id => $member_id});
        isa_ok $member, 'HASH';
        is $member->{name}, 'ytnobody';
    }
};

subtest select_with_row_class => sub {
    my $time = time;
    my $param = {
        name       => 'ytnobody in future', 
        age        => 43,
        sex        => 'male',
        created_at => $time,
    };
    
    $db->insert(member => $param);

    my $member_id = $db->last_insert_id;
    is $member_id, 2;

    {
        my @members = $db->row_class('Member')->select(member => {});
        is scalar @members, 2;
        for my $member (@members) {
            isa_ok $member, 'Member';
        }
    }    
    {
        my @members = $db->no_row_class->select(member => {});
        is scalar @members, 2;
        for my $member (@members) {
            isa_ok $member, 'HASH';
        }
    }    
};

done_testing;
