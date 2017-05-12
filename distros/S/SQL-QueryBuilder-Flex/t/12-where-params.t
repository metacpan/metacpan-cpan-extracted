
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
        ->where
            ->or('a = 1')
            ->or('b > ?', 2)
        ->get_query
    ;
    $q->where->and('c < ?', 3);
    my ($sql, @params) = $q->to_sql();
    is
        $sql,
        'SELECT name, email FROM user u WHERE a = 1 OR b > ? AND c < ?',
        'checking WHERE'
    ;
    is
        join(' ', @params),
        '2 3',
        'checking WHERE params'
    ;
}

done_testing();
