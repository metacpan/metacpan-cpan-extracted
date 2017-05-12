
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
        ->from('user', 'u' )
        ->left_join('group', 'g')->using('group_id')
        ->right_join('departament')->using('departament_id')
        ->get_query
    ;
    $q->delete_join('g')->delete_join(qr/^depar/);
    my ($sql, @params) = $q->to_sql();
    is
        $sql,
        'SELECT name, email FROM user u',
        'checking delete_join'
    ;
}

1;
