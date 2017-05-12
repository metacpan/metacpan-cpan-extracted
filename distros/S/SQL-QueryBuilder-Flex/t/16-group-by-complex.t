
use lib qw( lib );
use strict;
use warnings;

use Test::More tests => 2;

use SQL::QueryBuilder::Flex 'SQL';

{
    my $q = SQL
        ->select(
            'name',
            'email',
        )
        ->from('user', 'u')
        ->group_by('name', 'ASC')
    ;
    $q->group_by('email', 'DESC');
    $q->group_by('SUBTRING(note, 0, ?)', 'DESC', 10);
    my ($sql, @params) = $q->to_sql();
    is
        $sql,
        'SELECT name, email FROM user u GROUP BY name ASC, email DESC, SUBTRING(note, 0, ?) DESC',
        'checking GROUP BY complex'
    ;
    is
        join(' ', @params),
        '10',
        'checking GROUP BY complex params'
    ;
}

done_testing();
