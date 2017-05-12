
use lib qw( lib );
use strict;
use warnings;

use Test::More tests => 4;

use SQL::QueryBuilder::Flex 'SQL';

{
    my $q = SQL
        ->select(
            'name',
            'email',
        )
        ->from('user', 'u')
        ->limit(10)
        ->offset(0)
    ;
    my ($sql, @params) = $q->to_sql();
    is
        $sql,
        'SELECT name, email FROM user u LIMIT ?, ?',
        'checking LIMIT + OFFSET'
    ;
    is
        join(' ', @params),
        '0 10',
        'checking LIMIT + OFFSET params'
    ;
}

{
    my $q = SQL
        ->select(
            'name',
            'email',
        )
        ->from('user', 'u')
        ->offset(0)
        ->limit(1, 10)
    ;
    my ($sql, @params) = $q->to_sql();
    is
        $sql,
        'SELECT name, email FROM user u LIMIT ?, ?',
        'checking OFFSET + LIMIT'
    ;
    is
        join(' ', @params),
        '1 10',
        'checking OFFSET + LIMIT params'
    ;
}

done_testing();
