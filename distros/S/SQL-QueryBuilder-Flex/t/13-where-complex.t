
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
            ->and_exp
                ->or('c != ?', 10)
                ->or('c != ?', 12)
        ->get_query
    ;
    my ($sql, @params) = $q->to_sql();
    is
        $sql,
        'SELECT name, email FROM user u WHERE a = 1 OR b > ? AND ( c != ? OR c != ? )',
        'checking WHERE complex conditions'
    ;
    is
        join(' ', @params),
        '2 10 12',
        'checking WHERE complex conditions params'
    ;
}

done_testing();
