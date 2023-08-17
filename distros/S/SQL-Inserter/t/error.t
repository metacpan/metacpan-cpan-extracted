use Test2::Tools::Exception qw/dies lives/;
use Test2::V0;
use Test2::Mock;

use SQL::Inserter;

my $dbh = mock {} => (
    add => [
        prepare => sub {my $self = shift; return $self},
        execute => sub {},
    ]
);

subtest 'Constructor' => sub {
    like(dies {my $sql = SQL::Inserter->new()}, qr/dbh/, "Missing dbh");
    like(dies {my $sql = SQL::Inserter->new(dbh=>1)}, qr/table/, "Missing table");
};

subtest 'insert' => sub {
    my $sql = SQL::Inserter->new(dbh=>$dbh,table=>'table');
    ok(lives {$sql->insert()}, "No error on empty");
    like(dies {$sql->insert(1)}, qr/cols/, "Requires cols");

    $sql = SQL::Inserter->new(dbh=>$dbh,table=>'table',cols=>[qw/col1 col2/]);
    like(dies {$sql->insert(1)}, qr/multiple/, "Wrong number of cols");
    like(dies {$sql->insert(1..3)}, qr/multiple/, "Wrong number of cols");
    ok(lives {$sql->insert(1, 2)}, "Correct number of cols");
    ok(lives {$sql->insert(1..4)}, "Correct number of cols");
    like(dies {$sql->insert({})}, qr/array/, "Wrong mode");
    $sql->insert();
    ok(lives {$sql->insert({})}, "Mode can change on empty buffer");
    $sql->insert({col1=>1});
    like(dies {$sql->insert(1,2)}, qr/hash/, "Wrong mode again");
};

my $mock = Test2::Mock->new(
    class => 'SQL::Inserter',
    override => [
        croak => sub { return 0 },
    ],
);

subtest 'Cover croak fail' => sub {
    ok(lives {my $sql = SQL::Inserter->new()}, "Missing dbh");
    ok(lives {my $sql = SQL::Inserter->new(dbh=>1)}, "Missing table");
};

done_testing;
