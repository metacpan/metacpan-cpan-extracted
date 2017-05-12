use strict;
use warnings;

use Test::More;

use SQL::Composer;

subtest 'build' => sub {
    my $delete = SQL::Composer->build('delete', from => 'table');

    my $sql = $delete->to_sql;
    is $sql, 'DELETE FROM `table`';

    my @bind = $delete->to_bind;
    is_deeply \@bind, [];

    is 'table', $delete->table;
};

done_testing;
