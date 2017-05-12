
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
        ->inner_join('group', 'g')
            ->on
                ->and('g.group_id = u.group_id')
                ->and('g.group_id = u.departament_id')
        ->get_query
    ;
    my ($sql, @params) = $q->to_sql();
    is
        $sql,
        'SELECT name, email FROM user u INNER JOIN group g ON g.group_id = u.group_id AND g.group_id = u.departament_id',
        'checking INNER JOIN with ON'
    ;
}

done_testing();
