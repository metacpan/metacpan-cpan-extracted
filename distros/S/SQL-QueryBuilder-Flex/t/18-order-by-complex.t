
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
        ->order_by_asc('name')
        ->order_by('email', 'DESC')
        ->order_by_desc('SUBSTRING(note, ?, ?)', 0, 10)
    ;
    my ($sql, @params) = $q->to_sql();
    is
        $sql,
        'SELECT name, email FROM user u ORDER BY name ASC, email DESC, SUBSTRING(note, ?, ?) DESC',
        'checking ORDER BY complex'
    ;
    is
        join(' ', @params),
        '0 10',
        'checking ORDER BY complex params'
    ;
}

done_testing();
