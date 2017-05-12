use strict;
use warnings;

use Test::More;

use SQL::Composer ':funcs';

subtest 'select' => sub {
    my $sql = sql_select from => 'table', columns => [qw/foo bar/];

    isa_ok $sql, 'SQL::Composer::Select';
};

subtest 'insert' => sub {
    my $sql = sql_insert into => 'table', values => [foo => 'bar'];

    isa_ok $sql, 'SQL::Composer::Insert';
};

subtest 'update' => sub {
    my $sql = sql_update table => 'table', values => {foo => 'bar'};

    isa_ok $sql, 'SQL::Composer::Update';
};

subtest 'delete' => sub {
    my $sql = sql_delete from => 'table';

    isa_ok $sql, 'SQL::Composer::Delete';
};

done_testing;
