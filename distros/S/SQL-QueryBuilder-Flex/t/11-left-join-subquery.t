
use lib qw( lib );
use strict;
use warnings;

use Test::More tests => 1;

use SQL::QueryBuilder::Flex 'SQL';

{
    my $q = SQL
        ->select(
            'name',
            'email',
        )
        ->from('user', 'u')
        ->left_join(
            SQL
                ->select(
                    'group_id',
                    'group_name',
                )
                ->from('group')
            ,
            'g'
        )->using('group_id')
        ->get_query
    ;
    my ($sql, @params) = $q->to_sql();
    is
        $sql,
        'SELECT name, email FROM user u LEFT JOIN ( SELECT group_id, group_name FROM group ) AS g USING (group_id)',
        'checking FROM + LEFT JOIN + subquery'
    ;
}

done_testing();
